//
//  Place.swift
//  RealEstateMileageTracker
//
//  Created by Kuo, Ray on 3/8/26.
//

import Foundation
import CoreLocation

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
