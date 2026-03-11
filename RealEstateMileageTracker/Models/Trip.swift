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
    var place: Place?  // Legacy field - kept for backward compatibility
    var vehicle: Vehicle?
    var notes: String?
    
    // Legacy support - decode old purpose enum if present
    enum CodingKeys: String, CodingKey {
        case id, startTime, endTime, startLocation, endLocation, distance
        case purposeName, vehicle, notes
        case purpose // old key for backward compatibility
        case property // old key for backward compatibility (now place)
        case place
        case fromPlace, toPlace // old keys for backward compatibility
    }
    
    init(id: UUID = UUID(), startTime: Date, endTime: Date? = nil, 
         startLocation: LocationData, endLocation: LocationData? = nil,
         distance: Double, purposeName: String? = nil, place: Place? = nil,
         vehicle: Vehicle? = nil, notes: String? = nil) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.startLocation = startLocation
        self.endLocation = endLocation
        self.distance = distance
        self.purposeName = purposeName
        self.place = place
        self.vehicle = vehicle
        self.notes = notes
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        startTime = try container.decode(Date.self, forKey: .startTime)
        endTime = try container.decodeIfPresent(Date.self, forKey: .endTime)
        var decodedStartLocation = try container.decode(LocationData.self, forKey: .startLocation)
        var decodedEndLocation = try container.decodeIfPresent(LocationData.self, forKey: .endLocation)
        distance = try container.decode(Double.self, forKey: .distance)
        vehicle = try container.decodeIfPresent(Vehicle.self, forKey: .vehicle)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        
        // Migrate old fromPlace/toPlace to LocationData.nickname
        if decodedStartLocation.nickname == nil, let fromPlace = try? container.decodeIfPresent(Place.self, forKey: .fromPlace) {
            decodedStartLocation.nickname = fromPlace.nickname
        }
        if decodedEndLocation?.nickname == nil, let toPlace = try? container.decodeIfPresent(Place.self, forKey: .toPlace) {
            decodedEndLocation?.nickname = toPlace.nickname
        }
        
        startLocation = decodedStartLocation
        endLocation = decodedEndLocation
        
        // Try new format first, then fall back to old 'property' key
        if let place = try container.decodeIfPresent(Place.self, forKey: .place) {
            self.place = place
        } else if let oldProperty = try container.decodeIfPresent(Place.self, forKey: .property) {
            self.place = oldProperty
        } else {
            self.place = nil
        }
        
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
        try container.encodeIfPresent(place, forKey: .place)
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
    
    // Get display name for start location (location map is source of truth)
    func startLocationDisplayName(tripStore: TripStore?) -> String {
        // First check if we have a reference to location map
        if let locationNicknameId = startLocation.locationNicknameId,
           let tripStore = tripStore,
           let locationNickname = tripStore.locationNicknames.first(where: { $0.id == locationNicknameId }) {
            return locationNickname.nickname
        }
        
        // Fall back to searching by address/coordinate
        if let tripStore = tripStore,
           let nickname = tripStore.findLocationNickname(coordinate: startLocation.coordinate, address: startLocation.address) {
            return nickname
        }
        
        // Legacy: trip's stored nickname
        if let nickname = startLocation.nickname, !nickname.isEmpty {
            return nickname
        }
        
        // Finally fall back to address or coordinates
        return startLocation.address ?? "\(startLocation.latitude), \(startLocation.longitude)"
    }
    
    // Get display name for end location (location map is source of truth)
    func endLocationDisplayName(tripStore: TripStore?) -> String? {
        guard let endLocation = endLocation else { return nil }
        
        // First check if we have a reference to location map
        if let locationNicknameId = endLocation.locationNicknameId,
           let tripStore = tripStore,
           let locationNickname = tripStore.locationNicknames.first(where: { $0.id == locationNicknameId }) {
            return locationNickname.nickname
        }
        
        // Fall back to searching by address/coordinate
        if let tripStore = tripStore,
           let nickname = tripStore.findLocationNickname(coordinate: endLocation.coordinate, address: endLocation.address) {
            return nickname
        }
        
        // Legacy: trip's stored nickname
        if let nickname = endLocation.nickname, !nickname.isEmpty {
            return nickname
        }
        
        // Finally fall back to address or coordinates
        return endLocation.address ?? "\(endLocation.latitude), \(endLocation.longitude)"
    }
}

struct LocationData: Codable {
    var latitude: Double
    var longitude: Double
    var address: String?
    var nickname: String?  // Deprecated: kept for backward compatibility, use locationNicknameId instead
    var locationNicknameId: UUID?  // Reference to LocationNickname entry
    
    init(coordinate: CLLocationCoordinate2D, address: String? = nil, nickname: String? = nil, locationNicknameId: UUID? = nil) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.address = address
        self.nickname = nickname
        self.locationNicknameId = locationNicknameId
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    // Display name - should look up from location map using locationNicknameId
    var displayName: String {
        nickname ?? address ?? "\(latitude), \(longitude)"
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
