//
//  TripManager.swift
//  RealEstateMileageTracker
//
//  Created by Kuo, Ray on 3/8/26.
//

import Foundation
import CoreLocation
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
    private var lastLocation: CLLocation?
    private var stoppedTimer: Timer?
    private let normalStoppedThreshold: TimeInterval = 180 // 3 minutes
    private let debugStoppedThreshold: TimeInterval = 30 // 30 seconds for testing
    private let normalSpeedThreshold: CLLocationSpeed = 4.4704 // 10 mph in m/s
    private let debugSpeedThreshold: CLLocationSpeed = 0.5 // ~1 mph for walking
    private var totalDistance: CLLocationDistance = 0
    
    private var speedThreshold: CLLocationSpeed {
        debugMode ? debugSpeedThreshold : normalSpeedThreshold
    }
    
    private var stoppedThreshold: TimeInterval {
        debugMode ? debugStoppedThreshold : normalStoppedThreshold
    }
    
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
        isTracking = true
    }
    
    func stopTracking() {
        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()
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
        
        // Geocode end location
        geocodeLocation(lastLoc) { [weak self] address in
            self?.currentTrip?.endLocation?.address = address
        }
        
        print("🛑 Trip ended. Distance: \(trip.distance) miles")
        
        // Save trip (will be handled by TripStore)
        NotificationCenter.default.post(
            name: .tripCompleted,
            object: trip
        )
        
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
        print("📍 Speed: \(String(format: "%.1f", speedMph)) mph (threshold: \(String(format: "%.1f", thresholdMph)) mph)\(debugMode ? " [DEBUG]" : "")")
        
        // Trip start detection
        if currentTrip == nil && speed > speedThreshold {
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
            
            // Trip end detection
            if speed < 0.5 { // Stopped
                if stoppedTimer == nil {
                    stoppedTimer = Timer.scheduledTimer(withTimeInterval: stoppedThreshold, repeats: false) { [weak self] _ in
                        self?.endCurrentTrip()
                    }
                }
            } else {
                // Moving again, cancel stop timer
                stoppedTimer?.invalidate()
                stoppedTimer = nil
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
