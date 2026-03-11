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
    @Published var places: [Place] = []
    @Published var vehicles: [Vehicle] = []
    @Published var customPurposes: [String] = []
    
    private let tripsKey = "saved_trips"
    private let placesKey = "saved_properties" // kept as 'properties' for backward compatibility
    private let vehiclesKey = "saved_vehicles"
    private let customPurposesKey = "custom_purposes"
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadTrips()
        loadPlaces()
        loadVehicles()
        loadCustomPurposes()
        
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
        trips = decoded.sorted { $0.startTime > $1.startTime }
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
    
    // MARK: - Places
    func loadPlaces() {
        guard let data = UserDefaults.standard.data(forKey: placesKey),
              let decoded = try? JSONDecoder().decode([Place].self, from: data) else {
            places = []
            return
        }
        places = decoded.sorted { $0.createdAt > $1.createdAt }
    }
    
    func addPlace(_ place: Place) {
        places.insert(place, at: 0)
        savePlaces()
    }
    
    func updatePlace(_ place: Place) {
        if let index = places.firstIndex(where: { $0.id == place.id }) {
            places[index] = place
            savePlaces()
        }
    }
    
    func deletePlace(_ place: Place) {
        places.removeAll { $0.id == place.id }
        savePlaces()
    }
    
    private func savePlaces() {
        if let encoded = try? JSONEncoder().encode(places) {
            UserDefaults.standard.set(encoded, forKey: placesKey)
        }
    }
    
    // Find place near a location (within 200 meters)
    func findNearbyPlace(coordinate: CLLocationCoordinate2D, within meters: Double = 200) -> Place? {
        let targetLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        for place in places {
            guard let placeLocation = place.location else { continue }
            
            let placeCoordinate = placeLocation.coordinate
            let placeLocationObj = CLLocation(latitude: placeCoordinate.latitude, longitude: placeCoordinate.longitude)
            
            let distance = targetLocation.distance(from: placeLocationObj)
            
            if distance <= meters {
                print("🎯 Found nearby place: '\(place.displayName)' at \(String(format: "%.0f", distance))m away")
                return place
            }
        }
        
        return nil
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
        var csv = "Date,Start Time,End Time,Start Address,End Address,Miles,Purpose,Place,From Place,To Place,Vehicle,Amount\n"
        
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
            let purpose = trip.purposeName ?? ""
            let place = trip.place?.displayName ?? ""
            let fromPlace = trip.fromPlace?.displayName ?? ""
            let toPlace = trip.toPlace?.displayName ?? ""
            let vehicle = trip.vehicle?.displayName ?? ""
            let amount = String(format: "%.2f", trip.mileageAmount)
            
            csv += "\"\(date)\",\"\(startTime)\",\"\(endTime)\",\"\(startAddr)\",\"\(endAddr)\",\(miles),\"\(purpose)\",\"\(place)\",\"\(fromPlace)\",\"\(toPlace)\",\"\(vehicle)\",\(amount)\n"
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
                place: places.first,
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
}
