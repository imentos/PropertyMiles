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
    @State private var showingVehiclePicker = false
    @State private var startNickname: String = ""
    @State private var endNickname: String = ""
    
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
                        HStack {
                            Label("From", systemImage: "location.circle")
                            Spacer()
                            if let startAddr = trip.startLocation.address {
                                Text(startAddr)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        HStack {
                            Text("Nickname")
                                .foregroundColor(.secondary)
                            Spacer()
                            TextField("Add nickname (optional)", text: $startNickname)
                                .textFieldStyle(.roundedBorder)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    
                    // To location with nickname
                    if trip.endLocation != nil {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Label("To", systemImage: "location.circle.fill")
                                Spacer()
                                if let endAddr = trip.endLocation?.address {
                                    Text(endAddr)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            HStack {
                                Text("Nickname")
                                    .foregroundColor(.secondary)
                                Spacer()
                                TextField("Add nickname (optional)", text: $endNickname)
                                    .textFieldStyle(.roundedBorder)
                                    .multilineTextAlignment(.trailing)
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
            .onAppear {
                // Initialize nickname fields from location map
                let startDisplayName = trip.startLocationDisplayName(tripStore: tripStore)
                if let addr = trip.startLocation.address, startDisplayName != addr,
                   !startDisplayName.contains(",") || !startDisplayName.contains(".") {
                    startNickname = startDisplayName
                }
                
                if let endDisplayName = trip.endLocationDisplayName(tripStore: tripStore),
                   let addr = trip.endLocation?.address, endDisplayName != addr,
                   !endDisplayName.contains(",") || !endDisplayName.contains(".") {
                    endNickname = endDisplayName
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Update location map with nicknames before saving trip
                        if !startNickname.isEmpty {
                            let nicknameId = tripStore.setLocationNickname(
                                coordinate: trip.startLocation.coordinate,
                                address: trip.startLocation.address,
                                nickname: startNickname
                            )
                            trip.startLocation.locationNicknameId = nicknameId
                        } else {
                            trip.startLocation.locationNicknameId = nil
                        }
                        
                        if !endNickname.isEmpty, let endLocation = trip.endLocation {
                            let nicknameId = tripStore.setLocationNickname(
                                coordinate: endLocation.coordinate,
                                address: endLocation.address,
                                nickname: endNickname
                            )
                            trip.endLocation?.locationNicknameId = nicknameId
                        } else {
                            trip.endLocation?.locationNicknameId = nil
                        }
                        
                        tripStore.updateTrip(trip)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
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
        vehicle: nil,
        notes: nil
    ))
    .environmentObject(TripStore())
}
