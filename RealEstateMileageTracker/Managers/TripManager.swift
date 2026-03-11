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
            print("🐛 Debug mode: \(debugMode ? "ON" : "OFF")")
        }
    }
    
    private let locationManager = CLLocationManager()
    private let motionActivityManager = CMMotionActivityManager()
    private var lastLocation: CLLocation?
    private var stoppedTimer: Timer?
    private let normalStoppedThreshold: TimeInterval = 180 // 3 minutes
    private let speedThreshold: CLLocationSpeed = 4.4704 // 10 mph in m/s
    private var totalDistance: CLLocationDistance = 0
    private var currentActivity: CMMotionActivity?
    private var isVehicleActivity: Bool = false // Tracks automotive OR cycling
    
    // Reference to TripStore for place matching
    weak var tripStore: TripStore?
    
    private let geocoder = CLGeocoder()
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.activityType = .automotiveNavigation
        locationManager.pausesLocationUpdatesAutomatically = false
        
        locationPermissionStatus = locationManager.authorizationStatus
        
        // Auto-start tracking if we already have "Always" permission
        // This ensures tracking continues after app relaunch or background wake
        if locationPermissionStatus == .authorizedAlways {
            print("🚀 Auto-starting tracking with Always permission")
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
        
        // Start significant location change monitoring for automatic app relaunch
        locationManager.startMonitoringSignificantLocationChanges()
        
        locationManager.startUpdatingLocation()
        
        // Start motion activity monitoring to detect driving/cycling
        if CMMotionActivityManager.isActivityAvailable() {
            motionActivityManager.startActivityUpdates(to: .main) { [weak self] activity in
                guard let activity = activity else { return }
                self?.currentActivity = activity
                self?.isVehicleActivity = activity.automotive || activity.cycling
                
                let activityType = activity.automotive ? "🚗 Driving" : 
                                   activity.cycling ? "🚴 Cycling" :
                                   activity.stationary ? "🛑 Stationary" : "❓ Other"
                print("Activity: \(activityType), Confidence: \(activity.confidence.rawValue)")
            }
        } else {
            print("⚠️ Motion activity not available on this device")
        }
        
        isTracking = true
    }
    
    func stopTracking() {
        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()
        motionActivityManager.stopActivityUpdates()
        isTracking = false
        endCurrentTrip()
    }
    
    // Called when app launches in background due to location event
    func handleBackgroundLaunch() {
        print("🌙 App launched in background for location event")
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
        
        print("🚗 Trip started at \(location.coordinate)")
    }
    
    private func endCurrentTrip() {
        guard var trip = currentTrip, let lastLoc = lastLocation else { return }
        
        trip.endTime = Date()
        trip.endLocation = LocationData(coordinate: lastLoc.coordinate)
        trip.distance = totalDistance * 0.000621371 // Convert meters to miles
        
        print("🛑 Trip ended. Distance: \(trip.distance) miles")
        
        // Check for nearby place at start location and auto-assign nickname
        if let nearbyStartPlace = tripStore?.findNearbyPlace(coordinate: trip.startLocation.coordinate) {
            trip.startLocation.nickname = nearbyStartPlace.nickname
            print("🏠 Auto-assigned from nickname (place): \(nearbyStartPlace.displayName)")
        } else if let nearbyNickname = tripStore?.findLocationNickname(coordinate: trip.startLocation.coordinate, address: nil) {
            // If no nearby place, check location nicknames map
            trip.startLocation.nickname = nearbyNickname
            print("🏠 Auto-assigned from nickname (location map): \(nearbyNickname)")
        }
        
        // Check for nearby place at end location and auto-assign nickname (and legacy place)
        if let nearbyPlace = tripStore?.findNearbyPlace(coordinate: lastLoc.coordinate) {
            trip.place = nearbyPlace
            trip.endLocation?.nickname = nearbyPlace.nickname
            print("🏠 Auto-assigned to nickname (place): \(nearbyPlace.displayName)")
        } else if let nearbyNickname = tripStore?.findLocationNickname(coordinate: lastLoc.coordinate, address: nil) {
            // If no nearby place, check location nicknames map
            trip.endLocation?.nickname = nearbyNickname
            print("🏠 Auto-assigned to nickname (location map): \(nearbyNickname)")
        }
        
        // Geocode end location and then save trip
        geocodeLocation(lastLoc) { [weak self] address in
            guard let self = self else { return }
            
            // Update trip with end address
            trip.endLocation?.address = address
            
            // Re-check nickname with actual address (might find exact address match)
            if trip.endLocation?.nickname == nil, let address = address {
                if let addressNickname = self.tripStore?.findLocationNickname(coordinate: lastLoc.coordinate, address: address) {
                    trip.endLocation?.nickname = addressNickname
                    print("🏠 Auto-assigned to nickname with address: \(addressNickname)")
                }
            } else if let nickname = trip.endLocation?.nickname, let address = address {
                // Save auto-assigned nickname to location map for future reuse
                self.tripStore?.setLocationNickname(coordinate: lastLoc.coordinate, address: address, nickname: nickname)
            }
            
            // Also ensure we have the start address from currentTrip
            if let currentTripStartAddr = self.currentTrip?.startLocation.address {
                trip.startLocation.address = currentTripStartAddr
                
                // Re-check start nickname with actual address too
                if trip.startLocation.nickname == nil {
                    if let startNickname = self.tripStore?.findLocationNickname(coordinate: trip.startLocation.coordinate, address: currentTripStartAddr) {
                        trip.startLocation.nickname = startNickname
                        print("🏠 Auto-assigned from nickname with address: \(startNickname)")
                    }
                } else if let nickname = trip.startLocation.nickname {
                    // Save auto-assigned nickname to location map for future reuse
                    self.tripStore?.setLocationNickname(coordinate: trip.startLocation.coordinate, address: currentTripStartAddr, nickname: nickname)
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
        
        let speed = location.speed // m/s
        
        let speedMph = speed * 2.23694
        let thresholdMph = speedThreshold * 2.23694
        let activityStatus = isVehicleActivity ? (currentActivity?.cycling == true ? "🚴" : "🚗") : "❓"
        print("📍 Speed: \(String(format: "%.1f", speedMph)) mph (threshold: \(String(format: "%.1f", thresholdMph)) mph) \(activityStatus)\(debugMode ? " [DEBUG]" : "")")
        
        // Trip start detection - require BOTH speed threshold AND vehicle activity (driving or cycling)
        if currentTrip == nil && speed > speedThreshold {
            // Check if we're in vehicle mode (or motion activity is unavailable)
            if !CMMotionActivityManager.isActivityAvailable() || isVehicleActivity {
                startTrip(at: location)
                return
            } else {
                print("⚠️ Speed threshold met but not in vehicle mode - ignoring")
            }
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
            
            // Trip end detection - end if stopped
            let shouldEndTrip = speed < 0.5
            
            if shouldEndTrip {
                if stoppedTimer == nil {
                    print("⏸️ Trip ending soon (stopped) - waiting \(Int(normalStoppedThreshold))s...")
                    stoppedTimer = Timer.scheduledTimer(withTimeInterval: normalStoppedThreshold, repeats: false) { [weak self] _ in
                        self?.endCurrentTrip()
                    }
                }
            } else {
                // Cancel stop timer if moving again
                if stoppedTimer != nil {
                    stoppedTimer?.invalidate()
                    stoppedTimer = nil
                }
            }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        locationPermissionStatus = manager.authorizationStatus
        
        if locationPermissionStatus == .authorizedAlways {
            startTracking()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location error: \(error.localizedDescription)")
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let tripCompleted = Notification.Name("tripCompleted")
}
