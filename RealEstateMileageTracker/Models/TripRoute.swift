import Foundation
import CoreLocation
import MapKit

struct TripRoutePoint: Codable, Equatable {
    var latitude: Double
    var longitude: Double
    var timestamp: Date
    var startsNewSegment: Bool

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct TripRouteRecorder {
    static let maximumPoints = 4096
    private(set) var points: [TripRoutePoint] = []
    private var lastSampleTimestamp: Date?
    private var pendingSegmentBreak = false

    mutating func breakSegment() {
        pendingSegmentBreak = true
    }

    @discardableResult
    mutating func append(_ location: CLLocation, now: Date = Date()) -> Bool {
        let age = now.timeIntervalSince(location.timestamp)
        guard CLLocationCoordinate2DIsValid(location.coordinate),
              location.horizontalAccuracy >= 0, location.horizontalAccuracy <= 100,
              age >= -5, age <= 30 else { return false }
        if let lastSampleTimestamp, location.timestamp <= lastSampleTimestamp { return false }

        let sampleGap = lastSampleTimestamp.map { location.timestamp.timeIntervalSince($0) } ?? 0
        lastSampleTimestamp = location.timestamp

        var beginsSegment = points.isEmpty || pendingSegmentBreak || sampleGap > 60
        if let last = points.last {
            let previous = CLLocation(latitude: last.latitude, longitude: last.longitude)
            let distance = location.distance(from: previous)
            beginsSegment = beginsSegment || distance >= 200
            guard distance >= 10 || beginsSegment else { return false }
        }

        points.append(TripRoutePoint(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            timestamp: location.timestamp,
            startsNewSegment: beginsSegment
        ))
        pendingSegmentBreak = false

        // Bound long-drive storage while retaining endpoints and discontinuities.
        if points.count > Self.maximumPoints {
            var reduced = [points[0]]
            var crossedBreak = false
            for index in 1..<points.count {
                crossedBreak = crossedBreak || points[index].startsNewSegment
                if index.isMultiple(of: 2) || index == points.count - 1 {
                    var point = points[index]
                    point.startsNewSegment = crossedBreak
                    reduced.append(point)
                    crossedBreak = false
                }
            }
            points = reduced
        }
        return true
    }
}

enum TripRouteGeometry {
    static func segments(from points: [TripRoutePoint]) -> [[CLLocationCoordinate2D]] {
        var segments: [[CLLocationCoordinate2D]] = []
        var current: [CLLocationCoordinate2D] = []
        for point in points {
            guard CLLocationCoordinate2DIsValid(point.coordinate) else {
                if current.count >= 2 { segments.append(current) }
                current = []
                continue
            }
            if point.startsNewSegment {
                if current.count >= 2 { segments.append(current) }
                current = []
            }
            current.append(point.coordinate)
        }
        if current.count >= 2 { segments.append(current) }
        return segments
    }

    static func fittedRect(start: CLLocationCoordinate2D, end: CLLocationCoordinate2D,
                           segments: [[CLLocationCoordinate2D]]) -> MKMapRect {
        let coordinates = ([start, end] + segments.flatMap { $0 })
            .filter { CLLocationCoordinate2DIsValid($0) }
        var bounds = MKMapRect.null
        for coordinate in coordinates {
            let point = MKMapPoint(coordinate)
            bounds = bounds.union(MKMapRect(x: point.x, y: point.y, width: 1, height: 1))
        }
        guard !bounds.isNull else { return .world }
        let latitude = coordinates.first?.latitude ?? 0
        let minimumSpan = 400 * MKMapPointsPerMeterAtLatitude(latitude)
        let width = max(bounds.width * 1.4, minimumSpan)
        let height = max(bounds.height * 1.6, minimumSpan)
        return MKMapRect(x: bounds.midX - width / 2, y: bounds.midY - height / 2,
                         width: width, height: height)
    }

    static func isRoundTrip(start: CLLocationCoordinate2D, end: CLLocationCoordinate2D) -> Bool {
        CLLocation(latitude: start.latitude, longitude: start.longitude)
            .distance(from: CLLocation(latitude: end.latitude, longitude: end.longitude)) < 50
    }
}
