import Foundation
import SwiftUI

enum MileageRegion: String, CaseIterable {
    case unitedStates = "US"
    case canada = "CA"

    static var deviceDefault: String {
        Locale.current.region?.identifier == "CA" ? "CA" : "US"
    }
}

struct MileageReporting {
    let region: MileageRegion
    let canadianRate: Double

    static var current: MileageReporting {
        let defaults = UserDefaults.standard
        return MileageReporting(
            region: MileageRegion(rawValue: defaults.string(forKey: "reportingRegion") ?? MileageRegion.deviceDefault) ?? .unitedStates,
            canadianRate: defaults.double(forKey: "canadianReimbursementRate")
        )
    }

    var isCanada: Bool { region == .canada }
    var showsAmounts: Bool { !isCanada || (canadianRate.isFinite && canadianRate > 0) }
    var unit: String { NSLocalizedString(isCanada ? "km" : "mi", comment: "Distance unit") }
    var amountTitle: String {
        NSLocalizedString(isCanada ? "Reimbursement Estimate" : "US Deduction Estimate", comment: "Report amount title")
    }
    var csvAmountTitle: String { isCanada ? "Reimbursement Estimate (CAD)" : "IRS Estimate (USD)" }

    // Keep persisted distances in miles so switching countries never changes trip data.
    func distance(_ miles: Double) -> Double {
        isCanada ? miles * 1.609344 : miles
    }

    func distanceText(_ miles: Double, decimals: Int = 1) -> String {
        String(format: "%.*f %@", decimals, distance(miles), unit)
    }

    func amount(for trip: Trip) -> Double {
        isCanada ? (showsAmounts ? distance(trip.distance) * canadianRate : 0) : trip.mileageAmount
    }

    func money(_ amount: Double) -> String {
        String(format: "%@%.2f", isCanada ? "CA$" : "US$", amount)
    }
}

struct MileagePreferences: DynamicProperty {
    @AppStorage("reportingRegion") var regionCode = MileageRegion.deviceDefault
    @AppStorage("canadianReimbursementRate") var canadianRate = 0.0

    var reporting: MileageReporting {
        MileageReporting(region: MileageRegion(rawValue: regionCode) ?? .unitedStates, canadianRate: canadianRate)
    }
}
