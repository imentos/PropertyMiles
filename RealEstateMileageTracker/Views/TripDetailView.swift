//
//  TripDetailView.swift
//  RealEstateMileageTracker
//
//  Created by Kuo, Ray on 3/8/26.
//

import SwiftUI
import MapKit

struct TripDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var tripStore: TripStore
    
    @State private var trip: Trip
    @State private var showingPlacePicker = false
    @State private var showingVehiclePicker = false
    
    init(trip: Trip) {
        _trip = State(initialValue: trip)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Purpose") {
                    Picker("Trip Purpose", selection: Binding(
                        get: { trip.purposeName ?? "" },
                        set: { trip.purposeName = $0.isEmpty ? nil : $0 }
                    )) {
                        Text("None").tag("")
                        
                        ForEach(TripPurpose.allCases, id: \.self) { purpose in
                            Text(purpose.rawValue).tag(purpose.rawValue)
                        }
                        
                        if !tripStore.customPurposes.isEmpty {
                            Divider()
                            ForEach(tripStore.customPurposes, id: \.self) { purpose in
                                Text(purpose).tag(purpose)
                            }
                        }
                    }
                }
                
                Section("Place") {
                    Button {
                        showingPlacePicker = true
                    } label: {
                        HStack {
                            Label("Place", systemImage: "building.2")
                            Spacer()
                            if let place = trip.place {
                                Text(place.displayName)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("None")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section("Vehicle") {
                    Button {
                        showingVehiclePicker = true
                    } label: {
                        HStack {
                            Label("Vehicle", systemImage: "car")
                            Spacer()
                            if let vehicle = trip.vehicle {
                                Text(vehicle.displayName)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("None")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section("Trip Summary") {
                    HStack {
                        Label("Distance", systemImage: "road.lanes")
                        Spacer()
                        Text(String(format: "%.2f miles", trip.distance))
                            .foregroundColor(.secondary)
                    }
                    
                    if let duration = trip.duration {
                        HStack {
                            Label("Duration", systemImage: "clock")
                            Spacer()
                            Text(formatDuration(duration))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Label("Amount", systemImage: "dollarsign.circle")
                        Spacer()
                        Text(String(format: "$%.2f", trip.mileageAmount))
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Details") {
                    HStack {
                        Label("Date", systemImage: "calendar")
                        Spacer()
                        Text(formatDateTime(trip.startTime))
                            .foregroundColor(.secondary)
                    }
                    
                    // From location with nickname
                    VStack(alignment: .leading, spacing: 4) {
                        Label("From", systemImage: "location.circle")
                        
                        if let startAddr = trip.startLocation.address {
                            Text(startAddr)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.leading, 28)
                        }
                        
                        HStack {
                            Text("Nickname:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.leading, 28)
                            TextField("Optional", text: Binding(
                                get: {
                                    // Show nickname from location map (any source: reference, search, or stored)
                                    let displayName = trip.startLocationDisplayName(tripStore: tripStore)
                                    // If it's an address or coordinates, return empty
                                    if let addr = trip.startLocation.address, displayName == addr {
                                        return ""
                                    }
                                    if displayName.contains(",") && displayName.contains(".") {
                                        return "" // Coordinates
                                    }
                                    return displayName
                                },
                                set: { newValue in
                                    trip.startLocation.nickname = newValue.isEmpty ? nil : newValue
                                }
                            ))
                            .font(.caption)
                            .textFieldStyle(.roundedBorder)
                        }
                    }
                    
                    // To location with nickname
                    if trip.endLocation != nil {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("To", systemImage: "location.circle.fill")
                            
                            if let endAddr = trip.endLocation?.address {
                                Text(endAddr)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 28)
                            }
                            
                            HStack {
                                Text("Nickname:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 28)
                                TextField("Optional", text: Binding(
                                    get: {
                                        // Show nickname from location map (any source: reference, search, or stored)
                                        if let displayName = trip.endLocationDisplayName(tripStore: tripStore) {
                                            // If it's an address or coordinates, return empty
                                            if let addr = trip.endLocation?.address, displayName == addr {
                                                return ""
                                            }
                                            if displayName.contains(",") && displayName.contains(".") {
                                                return "" // Coordinates
                                            }
                                            return displayName
                                        }
                                        return ""
                                    },
                                    set: { newValue in
                                        trip.endLocation?.nickname = newValue.isEmpty ? nil : newValue
                                    }
                                ))
                                .font(.caption)
                                .textFieldStyle(.roundedBorder)
                            }
                        }
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: Binding(
                        get: { trip.notes ?? "" },
                        set: { trip.notes = $0.isEmpty ? nil : $0 }
                    ))
                    .frame(minHeight: 100)
                }
                
                // Map preview
                if let endLocation = trip.endLocation {
                    Section("Route") {
                        MapPreview(
                            startCoordinate: trip.startLocation.coordinate,
                            endCoordinate: endLocation.coordinate
                        )
                        .frame(height: 200)
                        .cornerRadius(8)
                    }
                }
            }
            .navigationTitle("Trip Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        tripStore.updateTrip(trip)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingPlacePicker) {
                PlacePickerView(selectedPlace: $trip.place)
            }
            .sheet(isPresented: $showingVehiclePicker) {
                VehiclePickerView(selectedVehicle: $trip.vehicle)
            }
        }
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct MapPreview: View {
    let startCoordinate: CLLocationCoordinate2D
    let endCoordinate: CLLocationCoordinate2D
    
    @State private var region: MKCoordinateRegion
    
    init(startCoordinate: CLLocationCoordinate2D, endCoordinate: CLLocationCoordinate2D) {
        self.startCoordinate = startCoordinate
        self.endCoordinate = endCoordinate
        
        // Calculate region to show both points
        let centerLat = (startCoordinate.latitude + endCoordinate.latitude) / 2
        let centerLon = (startCoordinate.longitude + endCoordinate.longitude) / 2
        
        let latDelta = abs(startCoordinate.latitude - endCoordinate.latitude) * 1.5
        let lonDelta = abs(startCoordinate.longitude - endCoordinate.longitude) * 1.5
        
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(
                latitudeDelta: max(latDelta, 0.01),
                longitudeDelta: max(lonDelta, 0.01)
            )
        ))
    }
    
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: [
            MapPoint(coordinate: startCoordinate, title: "Start"),
            MapPoint(coordinate: endCoordinate, title: "End")
        ]) { point in
            MapMarker(coordinate: point.coordinate, tint: point.title == "Start" ? .green : .red)
        }
    }
}

#Preview {
    TripDetailView(trip: Trip(
        startTime: Date(),
        endTime: Date().addingTimeInterval(1800),
        startLocation: LocationData(
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            address: "123 Market St, San Francisco, CA"
        ),
        endLocation: LocationData(
            coordinate: CLLocationCoordinate2D(latitude: 37.8044, longitude: -122.2712),
            address: "456 Broadway, Oakland, CA"
        ),
        distance: 12.5,
        purposeName: "Showing",
        place: nil,
        vehicle: nil,
        notes: nil
    ))
    .environmentObject(TripStore())
}
