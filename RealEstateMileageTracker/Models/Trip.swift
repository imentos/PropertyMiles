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
    var purpose: TripPurpose?
    var property: Property?
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
    case showing = "Showing"
    case openHouse = "Open House"
    case inspection = "Inspection"
    case clientMeeting = "Client Meeting"
    case personal = "Personal"
    
    var icon: String {
        switch self {
        case .showing: return "house"
        case .openHouse: return "door.left.hand.open"
        case .inspection: return "magnifyingglass"
        case .clientMeeting: return "person.2"
        case .personal: return "car"
        }
    }
}
