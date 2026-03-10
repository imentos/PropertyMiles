//
//  Vehicle.swift
//  RealEstateMileageTracker
//
//  Created by Kuo, Ray on 3/9/26.
//

import Foundation

struct Vehicle: Identifiable, Codable {
    var id: UUID = UUID()
    var make: String
    var model: String
    var year: String
    var createdAt: Date = Date()
    
    var displayName: String {
        "\(year) \(make) \(model)"
    }
}
