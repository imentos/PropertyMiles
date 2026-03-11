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
    var purposeName: String?
    var vehicle: Vehicle?
    var notes: String?
    
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
        
        // Fall back to searching by address/coordinate (location map is source of truth)
        if let tripStore = tripStore,
           let nickname = tripStore.findLocationNickname(coordinate: startLocation.coordinate, address: startLocation.address) {
            return nickname
        }
        
        // Fall back to address or coordinates
        // Note: Stored nickname is ignored - location map is the only source of truth
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
        
        // Fall back to searching by address/coordinate (location map is source of truth)
        if let tripStore = tripStore,
           let nickname = tripStore.findLocationNickname(coordinate: endLocation.coordinate, address: endLocation.address) {
            return nickname
        }
        
        // Fall back to address or coordinates
        // Note: Stored nickname is ignored - location map is the only source of truth
        return endLocation.address ?? "\(endLocation.latitude), \(endLocation.longitude)"
    }
}

struct LocationData: Codable {
    var latitude: Double
    var longitude: Double
    var address: String?
    var locationNicknameId: UUID?  // Reference to LocationNickname entry
    
    init(coordinate: CLLocationCoordinate2D, address: String? = nil, locationNicknameId: UUID? = nil) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.address = address
        self.locationNicknameId = locationNicknameId
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
