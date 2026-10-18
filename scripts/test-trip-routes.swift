import Foundation
import CoreLocation
import MapKit

// Trip's display-name helpers depend on a store; route checks need no app state.
struct LocationNickname {
    var id: UUID
    var nickname: String
}

final class TripStore {
    var locationNicknames: [LocationNickname] = []
    func findLocationNickname(coordinate: CLLocationCoordinate2D, address: String?) -> String? { nil }
}

@main
struct TripRouteChecks {
    static let base = Date(timeIntervalSince1970: 1_700_000_000)

    static func sample(_ latitude: Double, _ longitude: Double, time: Double,
                       accuracy: Double = 5) -> CLLocation {
        CLLocation(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                   altitude: 0, horizontalAccuracy: accuracy, verticalAccuracy: 5,
                   timestamp: base.addingTimeInterval(time))
    }

    static func add(_ location: CLLocation, to recorder: inout TripRouteRecorder) {
        recorder.append(location, now: location.timestamp)
    }

    static func main() throws {
        var recorder = TripRouteRecorder()
        let coordinates: [(Double, Double)] = [
            (37.7749, -122.4194), (37.7759, -122.4194),
            (37.7759, -122.4184), (37.7749, -122.4184), (37.7749, -122.4194)
        ]
        for (index, coordinate) in coordinates.enumerated() {
            add(sample(coordinate.0, coordinate.1, time: Double(index * 5)), to: &recorder)
        }
        precondition(recorder.points.count == 5)
        let segments = TripRouteGeometry.segments(from: recorder.points)
        precondition(segments.count == 1 && segments[0].count == 5)
        let start = segments[0][0]
        let end = segments[0][4]
        precondition(TripRouteGeometry.isRoundTrip(start: start, end: end))
        let bounds = TripRouteGeometry.fittedRect(start: start, end: end, segments: segments)
        precondition(bounds.contains(MKMapPoint(segments[0][2])), "A Home-to-Home map must frame the excursion")
        precondition(bounds.width > 0 && bounds.height > 0)

        var trip = Trip(startTime: base, endTime: base.addingTimeInterval(30),
                        startLocation: LocationData(coordinate: start),
                        endLocation: LocationData(coordinate: end), distance: 4.2)
        let legacyData = try JSONEncoder().encode(trip)
        let legacyTrip = try JSONDecoder().decode(Trip.self, from: legacyData)
        precondition(legacyTrip.routePoints == nil)
        trip.routePoints = recorder.points
        let restored = try JSONDecoder().decode(Trip.self, from: JSONEncoder().encode(trip))
        precondition(restored.routePoints == trip.routePoints)
        precondition(restored.distance == 4.2, "Route display must not recalculate stored mileage")

        let oldCount = recorder.points.count
        precondition(!recorder.append(sample(37.775, -122.4194, time: 25, accuracy: 101), now: base.addingTimeInterval(25)))
        precondition(!recorder.append(sample(37.775, -122.4194, time: 25), now: base.addingTimeInterval(100)))
        precondition(!recorder.append(sample(37.775, -122.4194, time: 19), now: base.addingTimeInterval(19)))
        precondition(!recorder.append(sample(37.7749, -122.4194, time: 20), now: base.addingTimeInterval(20)))
        precondition(!recorder.append(sample(91, -122, time: 25), now: base.addingTimeInterval(25)))
        precondition(recorder.points.count == oldCount)

        recorder.breakSegment()
        add(sample(37.7749, -122.4194, time: 25), to: &recorder)
        add(sample(37.775, -122.4194, time: 30), to: &recorder)
        precondition(TripRouteGeometry.segments(from: recorder.points).count == 2)
        add(sample(37.7751, -122.4194, time: 100), to: &recorder)
        precondition(recorder.points.last!.startsNewSegment, "Do not bridge a GPS time gap")
        add(sample(37.785, -122.4194, time: 105), to: &recorder)
        precondition(recorder.points.last!.startsNewSegment, "Do not connect a large GPS jump")

        var longDrive = TripRouteRecorder()
        for index in 0..<9000 {
            if index == 2000 { longDrive.breakSegment() }
            add(sample(37.7749, -122.4194 + Double(index) * 0.0002, time: Double(index)), to: &longDrive)
        }
        precondition(longDrive.points.count <= TripRouteRecorder.maximumPoints)
        precondition(longDrive.points.first!.longitude == -122.4194)
        precondition(abs(longDrive.points.last!.longitude - (-122.4194 + 8999 * 0.0002)) < 0.000001)
        precondition(TripRouteGeometry.segments(from: longDrive.points).count == 2)
        if CommandLine.arguments.count == 3, CommandLine.arguments[1] == "--fixture" {
            var fixture = trip
            fixture.startTime = Date().addingTimeInterval(-60)
            fixture.endTime = Date().addingTimeInterval(-30)
            fixture.startLocation.address = "Home"
            fixture.endLocation?.address = "Home"
            fixture.distance = 0.25
            fixture.notes = "Synthetic route fixture for UI verification, not an actual recorded drive."
            let defaults: [String: Any] = [
                "saved_trips": try JSONEncoder().encode([fixture]),
                "hasCompletedOnboarding": true,
                "reportingRegion": "US"
            ]
            let data = try PropertyListSerialization.data(fromPropertyList: defaults, format: .xml, options: 0)
            try data.write(to: URL(fileURLWithPath: CommandLine.arguments[2]), options: .atomic)
        }
        print("PASS: legacy decoding, route persistence, round-trip bounds, GPS filtering, pause/gap segments, bounded storage and unchanged mileage")
    }
}
