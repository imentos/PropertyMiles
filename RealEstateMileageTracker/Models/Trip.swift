//
//  Trip.swift
//  RealEstateMileageTracker
//
//  Created by Kuo, Ray on 3/8/26.
//

import Foundation
import CoreLocation

struct Trip: Identifiable, Codable {
    var id: UUID = UUID()
    var startTime: Date
    var endTime: Date?
    var startLocation: LocationData
    var endLocation: LocationData?
    var distance: Double // in miles
    var purposeName: String? // Changed to support custom purposes
    var property: Property?
    var vehicle: Vehicle?
    var notes: String?
    
    // Legacy support - decode old purpose enum if present
    enum CodingKeys: String, CodingKey {
        case id, startTime, endTime, startLocation, endLocation, distance
        case purposeName, property, vehicle, notes
        case purpose // old key
    }
    
    init(id: UUID = UUID(), startTime: Date, endTime: Date? = nil, 
         startLocation: LocationData, endLocation: LocationData? = nil,
         distance: Double, purposeName: String? = nil, property: Property? = nil,
         vehicle: Vehicle? = nil, notes: String? = nil) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.startLocation = startLocation
        self.endLocation = endLocation
        self.distance = distance
        self.purposeName = purposeName
        self.property = property
        self.vehicle = vehicle
        self.notes = notes
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        startTime = try container.decode(Date.self, forKey: .startTime)
        endTime = try container.decodeIfPresent(Date.self, forKey: .endTime)
        startLocation = try container.decode(LocationData.self, forKey: .startLocation)
        endLocation = try container.decodeIfPresent(LocationData.self, forKey: .endLocation)
        distance = try container.decode(Double.self, forKey: .distance)
        property = try container.decodeIfPresent(Property.self, forKey: .property)
        vehicle = try container.decodeIfPresent(Vehicle.self, forKey: .vehicle)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        
        // Try new format first
        if let purposeName = try container.decodeIfPresent(String.self, forKey: .purposeName) {
            self.purposeName = purposeName
        } 
        // Fall back to old enum format
        else if let oldPurpose = try? container.decodeIfPresent(TripPurpose.self, forKey: .purpose) {
            self.purposeName = oldPurpose.rawValue
        } else {
            self.purposeName = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(startTime, forKey: .startTime)
        try container.encodeIfPresent(endTime, forKey: .endTime)
        try container.encode(startLocation, forKey: .startLocation)
        try container.encodeIfPresent(endLocation, forKey: .endLocation)
        try container.encode(distance, forKey: .distance)
        try container.encodeIfPresent(purposeName, forKey: .purposeName)
        try container.encodeIfPresent(property, forKey: .property)
        try container.encodeIfPresent(vehicle, forKey: .vehicle)
        try container.encodeIfPresent(notes, forKey: .notes)
    }
    
    var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }
    
    var isComplete: Bool {
        endTime != nil && endLocation != nil
    }
    
    var mileageAmount: Double {
        distance * 0.67 // 2025 IRS standard mileage rate
    }
    
    var purposeIcon: String {
        guard let purposeName = purposeName else { return "car" }
        // Check if it matches a default purpose
        if let defaultPurpose = TripPurpose.allCases.first(where: { $0.rawValue == purposeName }) {
            return defaultPurpose.icon
        }
        // Custom purpose default icon
        return "tag"
    }
}

struct LocationData: Codable {
    var latitude: Double
    var longitude: Double
    var address: String?
    
    init(coordinate: CLLocationCoordinate2D, address: String? = nil) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.address = address
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

enum TripPurpose: String, Codable, CaseIterable {
    case repair = "Repair/Maintenance"
    case supplyRun = "Supply Shopping"
    case propertyCheck = "Property Check"
    case legalCourt = "Legal/Court"
    case openHouse = "Open House"
    case rentCollection = "Rent Collection"
    case emergencyCall = "Emergency Call"
    case personal = "Personal"
    
    var icon: String {
        switch self {
        case .repair: return "wrench.and.screwdriver"
        case .supplyRun: return "cart.fill"
        case .propertyCheck: return "house.circle"
        case .legalCourt: return "building.columns.fill"
        case .openHouse: return "door.left.hand.open"
        case .rentCollection: return "dollarsign.circle"
        case .emergencyCall: return "exclamationmark.triangle.fill"
        case .personal: return "car"
        }
    }
}
