import SwiftUI
import MapKit

struct RecordedTripMap: View {
    let startCoordinate: CLLocationCoordinate2D
    let endCoordinate: CLLocationCoordinate2D
    let routePoints: [TripRoutePoint]
    var isInteractive = false

    private var segments: [[CLLocationCoordinate2D]] {
        TripRouteGeometry.segments(from: routePoints)
    }

    var body: some View {
        let route = segments
        let bounds = TripRouteGeometry.fittedRect(start: startCoordinate, end: endCoordinate, segments: route)
        Map(initialPosition: .rect(bounds), interactionModes: isInteractive ? .all : []) {
            ForEach(route.indices, id: \.self) { index in
                MapPolyline(coordinates: route[index])
                    .stroke(.blue, lineWidth: 4)
            }
            if TripRouteGeometry.isRoundTrip(start: startCoordinate, end: endCoordinate) {
                Marker("Start / End", systemImage: "flag.checkered", coordinate: startCoordinate)
                    .tint(.green)
            } else {
                Marker("Start", systemImage: "play.fill", coordinate: startCoordinate)
                    .tint(.green)
                Marker("End", systemImage: "flag.checkered", coordinate: endCoordinate)
                    .tint(.red)
            }
        }
        .allowsHitTesting(isInteractive)
        .overlay(alignment: .topLeading) {
            if route.isEmpty {
                Text("No recorded route for this trip")
                    .font(.caption2)
                    .padding(6)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 4))
                    .padding(6)
            }
        }
        .accessibilityLabel(route.isEmpty ? Text("Trip endpoints") : Text("Recorded driving route"))
    }
}
