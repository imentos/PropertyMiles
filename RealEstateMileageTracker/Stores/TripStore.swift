//
//  TripStore.swift
//  RealEstateMileageTracker
//
//  Created by Kuo, Ray on 3/8/26.
//

import Foundation
import Combine
import CoreLocation

class TripStore: ObservableObject {
    @Published var trips: [Trip] = []
    @Published var vehicles: [Vehicle] = []
    @Published var customPurposes: [String] = []
    @Published var locationNicknames: [LocationNickname] = []
    @Published var locationNicknamesLastModified: Date = Date()
    @Published var hasCompletedOnboarding: Bool = false
    @Published var onboardingGoal: String = ""
    @Published var onboardingTripTypes: [String] = []

    private let tripsKey = "saved_trips"
    private let vehiclesKey = "saved_vehicles"
    private let customPurposesKey = "custom_purposes"
    private let locationNicknamesKey = "location_nicknames"
    private let hasCompletedOnboardingKey = "hasCompletedOnboarding"
    private let onboardingGoalKey = "onboardingGoal"
    private let onboardingTripTypesKey = "onboardingTripTypes"
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadTrips()
        loadVehicles()
        loadCustomPurposes()
        loadLocationNicknames()
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: hasCompletedOnboardingKey)
        onboardingGoal = UserDefaults.standard.string(forKey: onboardingGoalKey) ?? ""
        if let data = UserDefaults.standard.data(forKey: onboardingTripTypesKey),
           let types = try? JSONDecoder().decode([String].self, from: data) {
            onboardingTripTypes = types
        }

        // Listen for completed trips
        NotificationCenter.default.publisher(for: .tripCompleted)
            .sink { [weak self] notification in
                if let trip = notification.object as? Trip {
                    self?.addTrip(trip)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Trips
    func loadTrips() {
        guard let data = UserDefaults.standard.data(forKey: tripsKey),
              let decoded = try? JSONDecoder().decode([Trip].self, from: data) else {
            trips = []
            return
        }
        var migrated = decoded
        var didMigratePurposes = false
        for index in migrated.indices {
            let originalPurpose = migrated[index].purposeName
            let migratedPurpose = TripPurpose.migratedStoredValue(originalPurpose)
            if migratedPurpose != originalPurpose {
                migrated[index].purposeName = migratedPurpose
                didMigratePurposes = true
            }
        }
        trips = migrated.sorted { $0.startTime > $1.startTime }
        if didMigratePurposes {
            saveTrips()
        }
    }
    
    func addTrip(_ trip: Trip) {
        trips.insert(trip, at: 0)
        saveTrips()
    }
    
    func updateTrip(_ trip: Trip) {
        if let index = trips.firstIndex(where: { $0.id == trip.id }) {
            trips[index] = trip
            saveTrips()
        }
    }
    
    func deleteTrip(_ trip: Trip) {
        trips.removeAll { $0.id == trip.id }
        saveTrips()
    }
    
    private func saveTrips() {
        if let encoded = try? JSONEncoder().encode(trips) {
            UserDefaults.standard.set(encoded, forKey: tripsKey)
        }
    }
    
    // MARK: - Location Nicknames
    func loadLocationNicknames() {
        guard let data = UserDefaults.standard.data(forKey: locationNicknamesKey),
              let decoded = try? JSONDecoder().decode([LocationNickname].self, from: data) else {
            locationNicknames = []
            return
        }
        locationNicknames = decoded.sorted { $0.lastUsed > $1.lastUsed }
    }
    
    func saveLocationNicknames() {
        if let encoded = try? JSONEncoder().encode(locationNicknames) {
            UserDefaults.standard.set(encoded, forKey: locationNicknamesKey)
        }
    }
    
    // Add or update location nickname, returns the ID for reference
    func setLocationNickname(coordinate: CLLocationCoordinate2D, address: String?, nickname: String) -> UUID {
        let locationData = LocationData(coordinate: coordinate, address: address)
        
        // First check for exact address match (if both have addresses)
        if let targetAddr = address,
           let index = locationNicknames.firstIndex(where: { location in
               guard let locAddr = location.coordinate.address else { return false }
               return addressesMatch(targetAddr, locAddr)
           }) {
            // Update existing entry with exact address match
            locationNicknames[index].nickname = nickname
            locationNicknames[index].lastUsed = Date()
            // Update coordinate to latest (GPS might vary slightly)
            locationNicknames[index].coordinate = locationData
            locationNicknamesLastModified = Date()
            saveLocationNicknames()
            print("📝 Updated nickname '\(nickname)' for exact address match (ID: \(locationNicknames[index].id))")
            return locationNicknames[index].id
        }
        
        // Otherwise check if we already have a nickname for this location by proximity
        if let index = locationNicknames.firstIndex(where: { location in
            let loc1 = CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            let loc2 = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            return loc1.distance(from: loc2) <= 50 // Same location if within 50m
        }) {
            // Update existing
            locationNicknames[index].nickname = nickname
            locationNicknames[index].lastUsed = Date()
            locationNicknamesLastModified = Date()
            saveLocationNicknames()
            print("📝 Updated nickname '\(nickname)' for nearby location (ID: \(locationNicknames[index].id))")
            return locationNicknames[index].id
        } else {
            // Add new
            let newLocation = LocationNickname(coordinate: locationData, nickname: nickname)
            locationNicknames.insert(newLocation, at: 0)
            locationNicknamesLastModified = Date()
            saveLocationNicknames()
            print("📝 Added new nickname '\(nickname)' (ID: \(newLocation.id))")
            return newLocation.id
        }
    }
    
    // Assign a newly saved location nickname to existing trips near the same place.
    func applyLocationNicknameToMatchingTrips(nicknameId: UUID, coordinate: CLLocationCoordinate2D, address: String?, within meters: Double = 500) {
        let targetLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        var didUpdate = false

        for index in trips.indices {
            if shouldMatchLocation(trips[index].startLocation, targetLocation: targetLocation, address: address, within: meters),
               trips[index].startLocation.locationNicknameId != nicknameId {
                trips[index].startLocation.locationNicknameId = nicknameId
                didUpdate = true
            }

            if let endLocation = trips[index].endLocation,
               shouldMatchLocation(endLocation, targetLocation: targetLocation, address: address, within: meters),
               trips[index].endLocation?.locationNicknameId != nicknameId {
                trips[index].endLocation?.locationNicknameId = nicknameId
                didUpdate = true
            }
        }

        if didUpdate {
            locationNicknamesLastModified = Date()
            saveTrips()
        }
    }

    private func addressesMatch(_ lhs: String, _ rhs: String) -> Bool {
        normalizedAddress(lhs) == normalizedAddress(rhs)
    }

    private func normalizedAddress(_ address: String) -> String {
        address
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private func shouldMatchLocation(_ locationData: LocationData, targetLocation: CLLocation, address: String?, within meters: Double) -> Bool {
        if let address,
           let locationAddress = locationData.address,
           addressesMatch(address, locationAddress) {
            return true
        }

        let location = CLLocation(latitude: locationData.latitude, longitude: locationData.longitude)
        return location.distance(from: targetLocation) <= meters
    }

    // Find and return LocationNickname entry (with ID) for a location
    func findLocationNicknameEntry(coordinate: CLLocationCoordinate2D, address: String?, within meters: Double = 200) -> LocationNickname? {
        let targetLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        var closestEntry: LocationNickname?
        var closestDistance: Double = meters
        
        for locationNickname in locationNicknames {
            let locationCoordinate = locationNickname.coordinate.coordinate
            let location = CLLocation(latitude: locationCoordinate.latitude, longitude: locationCoordinate.longitude)
            let distance = targetLocation.distance(from: location)
            
            // Check if addresses match exactly (if both have addresses)
            if let targetAddr = address, let locAddr = locationNickname.coordinate.address,
               addressesMatch(targetAddr, locAddr) {
                print("🎯 Found exact address match: '\(locationNickname.nickname)' (ID: \(locationNickname.id))")
                return locationNickname
            }
            
            // Otherwise find closest
            if distance <= closestDistance {
                closestDistance = distance
                closestEntry = locationNickname
            }
        }
        
        if let entry = closestEntry {
            print("🎯 Found nearby location nickname: '\(entry.nickname)' at \(String(format: "%.0f", closestDistance))m away (ID: \(entry.id))")
        }
        
        return closestEntry
    }
    
    // Find nickname for a location (exact address match or nearby location)
    func findLocationNickname(coordinate: CLLocationCoordinate2D, address: String?, within meters: Double = 200) -> String? {
        let targetLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        var closestNickname: String?
        var closestDistance: Double = meters
        
        for locationNickname in locationNicknames {
            let locationCoordinate = locationNickname.coordinate.coordinate
            let location = CLLocation(latitude: locationCoordinate.latitude, longitude: locationCoordinate.longitude)
            let distance = targetLocation.distance(from: location)
            
            // Check if addresses match exactly (if both have addresses)
            if let targetAddr = address, let locAddr = locationNickname.coordinate.address,
               addressesMatch(targetAddr, locAddr) {
                return locationNickname.nickname
            }
            
            // Otherwise find closest
            if distance <= closestDistance {
                closestDistance = distance
                closestNickname = locationNickname.nickname
            }
        }
        
        return closestNickname
    }
    
    // MARK: - Vehicles
    func loadVehicles() {
        guard let data = UserDefaults.standard.data(forKey: vehiclesKey),
              let decoded = try? JSONDecoder().decode([Vehicle].self, from: data) else {
            vehicles = []
            return
        }
        vehicles = decoded.sorted { $0.createdAt > $1.createdAt }
    }
    
    func addVehicle(_ vehicle: Vehicle) {
        vehicles.insert(vehicle, at: 0)
        saveVehicles()
    }
    
    func updateVehicle(_ vehicle: Vehicle) {
        if let index = vehicles.firstIndex(where: { $0.id == vehicle.id }) {
            vehicles[index] = vehicle
            saveVehicles()
        }
    }
    
    func deleteVehicle(_ vehicle: Vehicle) {
        vehicles.removeAll { $0.id == vehicle.id }
        saveVehicles()
    }
    
    private func saveVehicles() {
        if let encoded = try? JSONEncoder().encode(vehicles) {
            UserDefaults.standard.set(encoded, forKey: vehiclesKey)
        }
    }
    
    // MARK: - Custom Purposes
    func loadCustomPurposes() {
        guard let data = UserDefaults.standard.data(forKey: customPurposesKey),
              let decoded = try? JSONDecoder().decode([String].self, from: data) else {
            customPurposes = []
            return
        }
        customPurposes = decoded.sorted()
    }
    
    func addCustomPurpose(_ purpose: String) {
        let trimmed = purpose.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty && !customPurposes.contains(trimmed) else { return }
        customPurposes.append(trimmed)
        customPurposes.sort()
        saveCustomPurposes()
    }
    
    func deleteCustomPurpose(_ purpose: String) {
        customPurposes.removeAll { $0 == purpose }
        saveCustomPurposes()
    }
    
    private func saveCustomPurposes() {
        if let encoded = try? JSONEncoder().encode(customPurposes) {
            UserDefaults.standard.set(encoded, forKey: customPurposesKey)
        }
    }
    
    // MARK: - Reports
    func tripsForDateRange(start: Date, end: Date) -> [Trip] {
        trips.filter { trip in
            trip.startTime >= start && trip.startTime <= end
        }
    }
    
    func totalMileageForDateRange(start: Date, end: Date) -> Double {
        tripsForDateRange(start: start, end: end)
            .reduce(0) { $0 + $1.distance }
    }
    
    func totalAmountForDateRange(start: Date, end: Date) -> Double {
        tripsForDateRange(start: start, end: end)
            .reduce(0) { $0 + $1.mileageAmount }
    }
    
    func generateCSV(for trips: [Trip]) -> String {
        var csv = "Date,Start Time,End Time,Start Address,End Address,Miles,Purpose,From Nickname,To Nickname,Vehicle,Amount\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        
        for trip in trips {
            let date = dateFormatter.string(from: trip.startTime)
            let startTime = timeFormatter.string(from: trip.startTime)
            let endTime = trip.endTime.map { timeFormatter.string(from: $0) } ?? ""
            let startAddr = trip.startLocation.address ?? "\(trip.startLocation.latitude),\(trip.startLocation.longitude)"
            let endAddr = trip.endLocation?.address ?? (trip.endLocation.map { "\($0.latitude),\($0.longitude)" } ?? "")
            let miles = String(format: "%.2f", trip.distance)
            let purpose = trip.purposeDisplayName
            let fromNickname = trip.startLocationDisplayName(tripStore: self)
            let toNickname = trip.endLocationDisplayName(tripStore: self) ?? ""
            let vehicle = trip.vehicle?.displayName ?? ""
            let amount = String(format: "%.2f", trip.mileageAmount)
            
            csv += "\"\(date)\",\"\(startTime)\",\"\(endTime)\",\"\(startAddr)\",\"\(endAddr)\",\(miles),\"\(purpose)\",\"\(fromNickname)\",\"\(toNickname)\",\"\(vehicle)\",\(amount)\n"
        }
        
        return csv
    }
    
    // MARK: - Debug
    func generateSampleTrips() {
        let sampleAddresses = [
            ("123 Market St, San Francisco, CA", 37.7749, -122.4194),
            ("456 Broadway, Oakland, CA", 37.8044, -122.2712),
            ("789 Main St, Berkeley, CA", 37.8715, -122.2730),
            ("321 Oak Ave, Palo Alto, CA", 37.4419, -122.1430),
            ("654 Pine St, San Jose, CA", 37.3382, -121.8863)
        ]
        
        let purposes: [TripPurpose] = [.repair, .openHouse, .propertyCheck, .supplyRun]
        let distances = [5.2, 12.8, 3.4, 18.5, 7.9, 15.3, 4.6]
        
        // Generate 5 sample trips from the last week
        for i in 0..<5 {
            let daysAgo = Double(i + 1)
            let startTime = Date().addingTimeInterval(-daysAgo * 24 * 3600)
            let duration: TimeInterval = Double.random(in: 600...3600) // 10-60 minutes
            
            let startIdx = i % sampleAddresses.count
            let endIdx = (i + 1) % sampleAddresses.count
            
            let startAddr = sampleAddresses[startIdx]
            let endAddr = sampleAddresses[endIdx]
            
            let trip = Trip(
                startTime: startTime,
                endTime: startTime.addingTimeInterval(duration),
                startLocation: LocationData(
                    coordinate: CLLocationCoordinate2D(latitude: startAddr.1, longitude: startAddr.2),
                    address: startAddr.0
                ),
                endLocation: LocationData(
                    coordinate: CLLocationCoordinate2D(latitude: endAddr.1, longitude: endAddr.2),
                    address: endAddr.0
                ),
                distance: distances[i % distances.count],
                purposeName: purposes[i % purposes.count].rawValue,
                vehicle: vehicles.first,
                notes: i == 0 ? "Sample trip for testing" : nil
            )
            
            addTrip(trip)
        }
        
        print("🎯 Generated 5 sample trips for testing")
    }
    
    func clearAllTrips() {
        trips.removeAll()
        saveTrips()
        print("🗑️ Cleared all trips")
    }

    /// Seeds ~$1,100 in deductions across 2026 — realistic data for App Store screenshots.
    func generateScreenshotTrips() {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date())

        struct TripSeed {
            let month: Int, day: Int
            let fromAddr: String, fromLat: Double, fromLng: Double
            let toAddr: String, toLat: Double, toLng: Double
            let miles: Double
            let purpose: TripPurpose
        }

        let seeds: [TripSeed] = [
            TripSeed(month: 1, day: 6,  fromAddr: "654 Pine St, San Jose, CA",       fromLat: 37.3382, fromLng: -121.8863, toAddr: "123 Market St, San Francisco, CA", toLat: 37.7749, toLng: -122.4194, miles: 48.2, purpose: .openHouse),
            TripSeed(month: 1, day: 14, fromAddr: "789 Main St, Berkeley, CA",         fromLat: 37.8715, fromLng: -122.2730, toAddr: "456 Broadway, Oakland, CA",         toLat: 37.8044, toLng: -122.2712, miles: 22.5, purpose: .repair),
            TripSeed(month: 1, day: 21, fromAddr: "321 Oak Ave, Palo Alto, CA",        fromLat: 37.4419, fromLng: -122.1430, toAddr: "654 Pine St, San Jose, CA",          toLat: 37.3382, toLng: -121.8863, miles: 19.8, purpose: .propertyCheck),
            TripSeed(month: 2, day: 3,  fromAddr: "123 Market St, San Francisco, CA", fromLat: 37.7749, fromLng: -122.4194, toAddr: "789 Main St, Berkeley, CA",          toLat: 37.8715, toLng: -122.2730, miles: 31.4, purpose: .rentCollection),
            TripSeed(month: 2, day: 11, fromAddr: "456 Broadway, Oakland, CA",         fromLat: 37.8044, fromLng: -122.2712, toAddr: "321 Oak Ave, Palo Alto, CA",        toLat: 37.4419, toLng: -122.1430, miles: 27.6, purpose: .supplyRun),
            TripSeed(month: 2, day: 18, fromAddr: "654 Pine St, San Jose, CA",         fromLat: 37.3382, fromLng: -121.8863, toAddr: "123 Market St, San Francisco, CA", toLat: 37.7749, toLng: -122.4194, miles: 51.3, purpose: .openHouse),
            TripSeed(month: 3, day: 5,  fromAddr: "789 Main St, Berkeley, CA",         fromLat: 37.8715, fromLng: -122.2730, toAddr: "654 Pine St, San Jose, CA",          toLat: 37.3382, toLng: -121.8863, miles: 44.9, purpose: .emergencyCall),
            TripSeed(month: 3, day: 12, fromAddr: "321 Oak Ave, Palo Alto, CA",        fromLat: 37.4419, fromLng: -122.1430, toAddr: "456 Broadway, Oakland, CA",         toLat: 37.8044, toLng: -122.2712, miles: 36.2, purpose: .repair),
            TripSeed(month: 3, day: 22, fromAddr: "123 Market St, San Francisco, CA", fromLat: 37.7749, fromLng: -122.4194, toAddr: "321 Oak Ave, Palo Alto, CA",        toLat: 37.4419, toLng: -122.1430, miles: 29.7, purpose: .propertyCheck),
            TripSeed(month: 4, day: 2,  fromAddr: "456 Broadway, Oakland, CA",         fromLat: 37.8044, fromLng: -122.2712, toAddr: "789 Main St, Berkeley, CA",          toLat: 37.8715, toLng: -122.2730, miles: 18.3, purpose: .legalCourt),
            TripSeed(month: 4, day: 9,  fromAddr: "654 Pine St, San Jose, CA",         fromLat: 37.3382, fromLng: -121.8863, toAddr: "321 Oak Ave, Palo Alto, CA",        toLat: 37.4419, toLng: -122.1430, miles: 22.1, purpose: .supplyRun),
            TripSeed(month: 4, day: 17, fromAddr: "789 Main St, Berkeley, CA",         fromLat: 37.8715, fromLng: -122.2730, toAddr: "123 Market St, San Francisco, CA", toLat: 37.7749, toLng: -122.4194, miles: 38.6, purpose: .openHouse),
            TripSeed(month: 5, day: 7,  fromAddr: "321 Oak Ave, Palo Alto, CA",        fromLat: 37.4419, fromLng: -122.1430, toAddr: "654 Pine St, San Jose, CA",          toLat: 37.3382, toLng: -121.8863, miles: 24.4, purpose: .rentCollection),
            TripSeed(month: 5, day: 14, fromAddr: "123 Market St, San Francisco, CA", fromLat: 37.7749, fromLng: -122.4194, toAddr: "456 Broadway, Oakland, CA",         toLat: 37.8044, toLng: -122.2712, miles: 17.9, purpose: .repair),
            TripSeed(month: 5, day: 23, fromAddr: "456 Broadway, Oakland, CA",         fromLat: 37.8044, fromLng: -122.2712, toAddr: "789 Main St, Berkeley, CA",          toLat: 37.8715, toLng: -122.2730, miles: 41.2, purpose: .propertyCheck),
            TripSeed(month: 6, day: 4,  fromAddr: "654 Pine St, San Jose, CA",         fromLat: 37.3382, fromLng: -121.8863, toAddr: "123 Market St, San Francisco, CA", toLat: 37.7749, toLng: -122.4194, miles: 53.8, purpose: .openHouse),
            TripSeed(month: 6, day: 11, fromAddr: "789 Main St, Berkeley, CA",         fromLat: 37.8715, fromLng: -122.2730, toAddr: "321 Oak Ave, Palo Alto, CA",        toLat: 37.4419, toLng: -122.1430, miles: 33.5, purpose: .supplyRun),
            TripSeed(month: 6, day: 19, fromAddr: "321 Oak Ave, Palo Alto, CA",        fromLat: 37.4419, fromLng: -122.1430, toAddr: "456 Broadway, Oakland, CA",         toLat: 37.8044, toLng: -122.2712, miles: 28.9, purpose: .emergencyCall),
        ]

        let vehicle = vehicles.first
        var newTrips: [Trip] = []

        for seed in seeds {
            var components = DateComponents()
            components.year = year
            components.month = seed.month
            components.day = seed.day
            components.hour = Int.random(in: 8...17)
            components.minute = Int.random(in: 0...59)
            guard let startTime = calendar.date(from: components) else { continue }
            let duration = seed.miles / 30.0 * 3600 // ~30 mph average
            let trip = Trip(
                startTime: startTime,
                endTime: startTime.addingTimeInterval(duration),
                startLocation: LocationData(
                    coordinate: CLLocationCoordinate2D(latitude: seed.fromLat, longitude: seed.fromLng),
                    address: seed.fromAddr
                ),
                endLocation: LocationData(
                    coordinate: CLLocationCoordinate2D(latitude: seed.toLat, longitude: seed.toLng),
                    address: seed.toAddr
                ),
                distance: seed.miles,
                purposeName: seed.purpose.rawValue,
                vehicle: vehicle
            )
            newTrips.append(trip)
        }

        trips.append(contentsOf: newTrips)
        trips.sort { $0.startTime > $1.startTime }
        saveTrips()

        let total = newTrips.reduce(0) { $0 + $1.mileageAmount }
        print("📸 Generated \(newTrips.count) screenshot trips — $\(String(format: "%.2f", total)) total deduction")
    }

    // MARK: - Onboarding

    func completeOnboarding(goal: String, tripTypes: [String]) {
        onboardingGoal = goal
        onboardingTripTypes = tripTypes
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: hasCompletedOnboardingKey)
        UserDefaults.standard.set(goal, forKey: onboardingGoalKey)
        if let data = try? JSONEncoder().encode(tripTypes) {
            UserDefaults.standard.set(data, forKey: onboardingTripTypesKey)
        }
    }

    func resetOnboarding() {
        hasCompletedOnboarding = false
        onboardingGoal = ""
        onboardingTripTypes = []
        UserDefaults.standard.removeObject(forKey: hasCompletedOnboardingKey)
        UserDefaults.standard.removeObject(forKey: onboardingGoalKey)
        UserDefaults.standard.removeObject(forKey: onboardingTripTypesKey)
    }
}
