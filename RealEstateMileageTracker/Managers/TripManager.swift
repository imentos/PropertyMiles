//
//  TripManager.swift
//  RealEstateMileageTracker
//
//  Created by Kuo, Ray on 3/8/26.
//

import Foundation
import CoreLocation
import CoreMotion
import Combine

class TripManager: NSObject, ObservableObject {
    @Published var currentTrip: Trip?
    @Published var isTracking: Bool = false
    @Published var locationPermissionStatus: CLAuthorizationStatus = .notDetermined
    @Published var debugMode: Bool = false {
        didSet {
            logTrackingEvent("Debug mode: \(debugMode ? "ON" : "OFF")")
        }
    }
    private static let trackingLogKey = "tracking_debug_log"
    private static let maxTrackingLogEntries = 500

    @Published var recentTrackingEvents: [String] = UserDefaults.standard.stringArray(forKey: TripManager.trackingLogKey) ?? []
    
    private let locationManager = CLLocationManager()
    private let motionActivityManager = CMMotionActivityManager()
    private var lastLocation: CLLocation?
    private var stoppedTimer: Timer?
    private var stoppedAt: Date?
    private let normalStoppedThreshold: TimeInterval = 300 // 5 minutes (prevents ending at traffic lights)
    private let speedThreshold: CLLocationSpeed = 2.2352 // 5 mph in m/s
    private var totalDistance: CLLocationDistance = 0
    private var currentActivity: CMMotionActivity?
    private var isVehicleActivity: Bool = false // Tracks automotive only
    private var isPreciseLocationActive = false
    private let speedLogInterval: TimeInterval = 30
    private var lastSpeedLogTime: Date?
    private var lastActivityLogSignature: String?
    
    // Reference to TripStore for place matching
    weak var tripStore: TripStore?
    
    private let geocoder = CLGeocoder()
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.activityType = .automotiveNavigation
        configureIdleLocationMode()
        
        locationPermissionStatus = locationManager.authorizationStatus
        
        // Auto-start tracking if we already have "Always" permission
        // This ensures tracking continues after app relaunch or background wake
        if locationPermissionStatus == .authorizedAlways {
            logTrackingEvent("Auto-starting tracking with Always permission")
            startTracking()
        }
    }
    
    func requestLocationPermission() {
        locationManager.requestAlwaysAuthorization()
    }
    
    func startTracking() {
        guard locationPermissionStatus == .authorizedAlways else {
            requestLocationPermission()
            return
        }
        
        // Enable background location tracking
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.showsBackgroundLocationIndicator = true
        
        isTracking = true

        // Start significant location change monitoring for automatic app relaunch
        locationManager.startMonitoringSignificantLocationChanges()
        
        // Start motion activity monitoring to detect driving
        if CMMotionActivityManager.isActivityAvailable() {
            motionActivityManager.startActivityUpdates(to: .main) { [weak self] activity in
                guard let activity = activity else { return }
                self?.currentActivity = activity
                self?.isVehicleActivity = activity.automotive && activity.confidence != .low

                if activity.automotive && activity.confidence != .low {
                    self?.resumeTripIfNeeded(reason: "vehicle activity")
                    self?.activatePreciseLocationUpdates(reason: "vehicle activity")
                } else if activity.stationary && activity.confidence != .low {
                    if self?.currentTrip != nil {
                        self?.handleStoppedSignal(since: activity.startDate, reason: "stationary activity")
                    } else {
                        self?.deactivatePreciseLocationUpdates()
                    }
                }
                
                let activityType = activity.automotive ? "🚗 Driving" : 
                                   activity.stationary ? "🛑 Stationary" : "❓ Other"
                let activitySignature = "\(activityType)|\(activity.confidence.rawValue)"
                if self?.lastActivityLogSignature != activitySignature {
                    self?.lastActivityLogSignature = activitySignature
                    self?.logTrackingEvent("Activity: \(activityType), confidence \(activity.confidence.rawValue)")
                }
            }
        } else {
            logTrackingEvent("Motion activity not available on this device")
        }
    }
    
    func stopTracking() {
        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()
        motionActivityManager.stopActivityUpdates()
        isPreciseLocationActive = false
        configureIdleLocationMode()
        isTracking = false
        endCurrentTrip()
    }
    
    // Called when app launches in background due to location event
    func handleBackgroundLaunch() {
        logTrackingEvent("App launched in background for location event")
        // Significant location changes will trigger didUpdateLocations
        // which will start trip if speed threshold is met
    }
    
    private func startTrip(at location: CLLocation) {
        guard currentTrip == nil else { return }
        
        let locationData = LocationData(coordinate: location.coordinate)
        currentTrip = Trip(
            startTime: Date(),
            endTime: nil,
            startLocation: locationData,
            endLocation: nil,
            distance: 0
        )
        
        lastLocation = location
        totalDistance = 0
        
        // Geocode start location
        geocodeLocation(location) { [weak self] address in
            self?.currentTrip?.startLocation.address = address
        }
        
        logTrackingEvent("Trip started at \(location.coordinate)")
    }
    
    private func endCurrentTrip() {
        guard var trip = currentTrip, let lastLoc = lastLocation else { return }
        
        trip.endTime = Date()
        trip.endLocation = LocationData(coordinate: lastLoc.coordinate)
        trip.distance = totalDistance * 0.000621371 // Convert meters to miles
        
        logTrackingEvent("Trip ended. Distance: \(String(format: "%.2f", trip.distance)) miles")
        
        // Check for nearby location at start and auto-assign nickname
        if let nearbyEntry = tripStore?.findLocationNicknameEntry(coordinate: trip.startLocation.coordinate, address: nil) {
            trip.startLocation.locationNicknameId = nearbyEntry.id
            print("🏠 Auto-assigned from nickname (location map): \(nearbyEntry.nickname)")
        }
        
        // Check for nearby location at end and auto-assign nickname
        if let nearbyEntry = tripStore?.findLocationNicknameEntry(coordinate: lastLoc.coordinate, address: nil) {
            trip.endLocation?.locationNicknameId = nearbyEntry.id
            print("🏠 Auto-assigned to nickname (location map): \(nearbyEntry.nickname)")
        }
        
        // Geocode end location and then save trip
        geocodeLocation(lastLoc) { [weak self] address in
            guard let self = self else { return }
            
            // Update trip with end address
            trip.endLocation?.address = address
            
            // Re-check nickname with actual address (might find exact address match)
            if trip.endLocation?.locationNicknameId == nil, let address = address {
                if let entry = self.tripStore?.findLocationNicknameEntry(coordinate: lastLoc.coordinate, address: address) {
                    trip.endLocation?.locationNicknameId = entry.id
                    print("🏠 Auto-assigned to nickname with address: \(entry.nickname)")
                }
            }
            
            // Also ensure we have the start address from currentTrip
            if let currentTripStartAddr = self.currentTrip?.startLocation.address {
                trip.startLocation.address = currentTripStartAddr
                
                // Re-check start nickname with actual address too
                if trip.startLocation.locationNicknameId == nil {
                    if let entry = self.tripStore?.findLocationNicknameEntry(coordinate: trip.startLocation.coordinate, address: currentTripStartAddr) {
                        trip.startLocation.locationNicknameId = entry.id
                        print("🏠 Auto-assigned from nickname with address: \(entry.nickname)")
                    }
                }
            }
            
            print("📍 Trip addresses - From: \(trip.startLocation.address ?? "Unknown") → To: \(trip.endLocation?.address ?? "Unknown")")
            
            // Save trip (will be handled by TripStore)
            NotificationCenter.default.post(
                name: .tripCompleted,
                object: trip
            )
        }
        
        currentTrip = nil
        lastLocation = nil
        totalDistance = 0
        stoppedTimer?.invalidate()
        stoppedTimer = nil
        stoppedAt = nil

        if isTracking {
            deactivatePreciseLocationUpdates()
        }
    }
    
    private func configureIdleLocationMode() {
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = 100
        locationManager.pausesLocationUpdatesAutomatically = true
    }

    private func configurePreciseLocationMode() {
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = 20
        locationManager.pausesLocationUpdatesAutomatically = false
    }

    private func activatePreciseLocationUpdates(reason: String) {
        guard isTracking, !isPreciseLocationActive else { return }

        configurePreciseLocationMode()
        locationManager.startUpdatingLocation()
        isPreciseLocationActive = true

        logTrackingEvent("Precise GPS ON (\(reason))")
    }

    private func deactivatePreciseLocationUpdates() {
        guard isPreciseLocationActive else { return }

        locationManager.stopUpdatingLocation()
        configureIdleLocationMode()
        isPreciseLocationActive = false

        logTrackingEvent("Precise GPS OFF (idle)")
    }

    private func handleStoppedSignal(since detectedAt: Date = Date(), reason: String) {
        guard currentTrip != nil else { return }

        if stoppedAt == nil {
            if let tripStart = currentTrip?.startTime {
                stoppedAt = max(detectedAt, tripStart)
            } else {
                stoppedAt = detectedAt
            }
            logTrackingEvent("Trip stop detected (\(reason))")
        }

        finishTripIfStoppedLongEnough(reason: reason)
    }

    private func finishTripIfStoppedLongEnough(reason: String) {
        guard currentTrip != nil, let stoppedAt else { return }

        let stoppedDuration = Date().timeIntervalSince(stoppedAt)
        if stoppedDuration >= normalStoppedThreshold {
            logTrackingEvent("Trip ending after \(Int(stoppedDuration))s stopped (\(reason))")
            endCurrentTrip()
            return
        }

        scheduleStoppedTimer(remaining: normalStoppedThreshold - stoppedDuration, reason: reason)
    }

    private func scheduleStoppedTimer(remaining: TimeInterval, reason: String) {
        guard stoppedTimer == nil else { return }

        let delay = max(1, remaining)
        logTrackingEvent("Trip ending soon - waiting \(Int(delay))s (\(reason))")
        stoppedTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.finishTripIfStoppedLongEnough(reason: "stop timer")
        }
    }

    private func resumeTripIfNeeded(reason: String) {
        guard stoppedAt != nil || stoppedTimer != nil else { return }

        stoppedAt = nil
        stoppedTimer?.invalidate()
        stoppedTimer = nil
        logTrackingEvent("Trip resumed (\(reason))")
    }

    private func logTrackingEvent(_ message: String) {
        print(message)

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm:ss a"
        let entry = "\(formatter.string(from: Date()))  \(message)"

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.recentTrackingEvents.insert(entry, at: 0)
            if self.recentTrackingEvents.count > Self.maxTrackingLogEntries {
                self.recentTrackingEvents.removeLast(self.recentTrackingEvents.count - Self.maxTrackingLogEntries)
            }
            UserDefaults.standard.set(self.recentTrackingEvents, forKey: Self.trackingLogKey)
        }
    }

    func clearTrackingLog() {
        recentTrackingEvents.removeAll()
        lastSpeedLogTime = nil
        UserDefaults.standard.removeObject(forKey: Self.trackingLogKey)
    }

    private func logSpeedSampleIfNeeded(speedMph: Double, thresholdMph: Double, activityStatus: String) {
        let now = Date()
        if let lastSpeedLogTime, now.timeIntervalSince(lastSpeedLogTime) < speedLogInterval {
            return
        }

        lastSpeedLogTime = now
        logTrackingEvent("Speed sample: \(String(format: "%.1f", speedMph)) mph, threshold \(String(format: "%.1f", thresholdMph)) mph \(activityStatus)")
    }

    private func geocodeLocation(_ location: CLLocation, completion: @escaping (String?) -> Void) {
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            guard let placemark = placemarks?.first, error == nil else {
                completion(nil)
                return
            }
            
            let address = [
                placemark.subThoroughfare,
                placemark.thoroughfare,
                placemark.locality,
                placemark.administrativeArea,
                placemark.postalCode
            ].compactMap { $0 }.joined(separator: ", ")
            
            completion(address.isEmpty ? nil : address)
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension TripManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        guard location.horizontalAccuracy >= 0, location.horizontalAccuracy <= 100 else {
            logTrackingEvent("Ignoring inaccurate location: \(String(format: "%.0f", location.horizontalAccuracy))m")
            return
        }
        
        let speed = location.speed // m/s
        
        let speedMph = speed * 2.23694
        let thresholdMph = speedThreshold * 2.23694
        let activityStatus = isVehicleActivity ? "🚗" : "❓"
        logSpeedSampleIfNeeded(speedMph: speedMph, thresholdMph: thresholdMph, activityStatus: activityStatus)
        
        let speedIsReliable = speed >= 0
        let isMovingFastEnough = speedIsReliable && speed > speedThreshold
        let isLikelyVehicleTrip = isVehicleActivity && speedIsReliable && speed > 0.5

        // Trip start detection - allow short, slow drives when motion says vehicle.
        if currentTrip == nil && (isMovingFastEnough || isLikelyVehicleTrip) {
            let reason = isMovingFastEnough ? "speed threshold" : "vehicle motion"
            activatePreciseLocationUpdates(reason: reason)
            startTrip(at: location)
            return
        }
        
        // Update trip distance
        if currentTrip != nil {
            if let lastLoc = lastLocation {
                let distance = location.distance(from: lastLoc)
                if distance > 0 && distance < 200 { // Ignore GPS jumps > 200m
                    totalDistance += distance
                    currentTrip?.distance = totalDistance * 0.000621371 // meters to miles
                }
            }
            
            lastLocation = location
            
            // Trip end detection - end after the device has truly been stopped long enough.
            let shouldEndTrip = speedIsReliable && speed < 0.5
            
            if shouldEndTrip {
                handleStoppedSignal(reason: "low speed")
            } else if speedIsReliable {
                resumeTripIfNeeded(reason: "location speed")
            }
            
            finishTripIfStoppedLongEnough(reason: "location update")
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        locationPermissionStatus = manager.authorizationStatus
        
        if locationPermissionStatus == .authorizedAlways {
            startTracking()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        logTrackingEvent("Location error: \(error.localizedDescription)")
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let tripCompleted = Notification.Name("tripCompleted")
}
