import Foundation

// A minimal trip fixture keeps these reporting checks independent of GPS and UI.
struct Trip {
    var distance: Double
    var mileageAmount: Double
}

@main
struct MileageReportingChecks {
    static func main() {
        let trip = Trip(distance: 10, mileageAmount: 7.60)
        let us = MileageReporting(region: .unitedStates, canadianRate: 0.73)
        let canada = MileageReporting(region: .canada, canadianRate: 0)
        let reimbursement = MileageReporting(region: .canada, canadianRate: 0.50)

        precondition(us.distance(10) == 10)
        precondition(abs(canada.distance(10) - 16.09344) < 0.000001)
        precondition(canada.distanceText(10) == "16.1 km")
        precondition(us.distanceText(10) == "10.0 mi")
        precondition(us.amount(for: trip) == 7.60)
        precondition(us.money(7.60) == "US$7.60")
        precondition(!canada.showsAmounts && canada.amount(for: trip) == 0)
        precondition(reimbursement.showsAmounts)
        precondition(abs(reimbursement.amount(for: trip) - 8.04672) < 0.000001)
        precondition(reimbursement.money(reimbursement.amount(for: trip)) == "CA$8.05")
        precondition(reimbursement.csvAmountTitle == "Reimbursement Estimate (CAD)")
        for invalidRate in [-1.0, Double.nan, Double.infinity] {
            let invalid = MileageReporting(region: .canada, canadianRate: invalidRate)
            precondition(!invalid.showsAmounts && invalid.amount(for: trip) == 0)
        }
        precondition(trip.distance == 10, "Country selection must never mutate stored miles")

        let defaults = UserDefaults.standard
        let originalRegion = defaults.object(forKey: "reportingRegion")
        let originalRate = defaults.object(forKey: "canadianReimbursementRate")
        defer {
            defaults.set(originalRegion, forKey: "reportingRegion")
            defaults.set(originalRate, forKey: "canadianReimbursementRate")
        }
        defaults.set("CA", forKey: "reportingRegion")
        defaults.set(0.50, forKey: "canadianReimbursementRate")
        precondition(MileageReporting.current.isCanada)
        precondition(MileageReporting.current.canadianRate == 0.50)
        defaults.set("US", forKey: "reportingRegion")
        precondition(MileageReporting.current.amount(for: trip) == 7.60)
        defaults.set("invalid", forKey: "reportingRegion")
        precondition(!MileageReporting.current.isCanada)
        print("PASS: conversion, CAD/USD estimates, distance-only mode, invalid rates, persistence and country switching")
    }
}
