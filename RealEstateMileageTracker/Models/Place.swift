//
//  Place.swift
//  RealEstateMileageTracker
//
//  Created by Kuo, Ray on 3/8/26.
//

import Foundation
import CoreLocation

// MARK: - Deprecated Place Model
// Kept for backward compatibility with old saved trip data
// Use LocationNickname instead for all new functionality

@available(*, deprecated, message: "Use LocationNickname instead")
struct Place: Identifiable, Codable {
    var id: UUID = UUID()
    var address: String
    var nickname: String?
    var location: LocationData?
    var createdAt: Date = Date()
    
    var displayName: String {
        nickname ?? address
    }
}

// Backward compatibility alias
typealias Property = Place

// Location nickname mapping for auto-assignment
struct LocationNickname: Identifiable, Codable {
    var id: UUID = UUID()
    var coordinate: LocationData
    var nickname: String
    var lastUsed: Date = Date()
    
    var displayName: String {
        nickname
    }
}
