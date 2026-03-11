//
//  Place.swift
//  RealEstateMileageTracker
//
//  Created by Kuo, Ray on 3/8/26.
//

import Foundation
import CoreLocation

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
