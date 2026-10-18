//
//  TripDetailView.swift
//  RealEstateMileageTracker
//
//  Created by Kuo, Ray on 3/8/26.
//

import SwiftUI
import MapKit

struct TripDetailView: View {
    private var preferences = MileagePreferences()
    private var mileage: MileageReporting { preferences.reporting }
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
                            Text(purpose.displayName).tag(purpose.rawValue)
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
                        Text(mileage.distanceText(trip.distance, decimals: 2))
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
                    
                    if mileage.showsAmounts {
                        HStack {
                            Label(mileage.amountTitle, systemImage: "dollarsign.circle")
                            Spacer()
                            Text(mileage.money(mileage.amount(for: trip)))
                                .foregroundColor(.secondary)
                        }
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
                            Text(trip.startLocation.displayAddress)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        HStack {
                            Text("Nickname")
                                .foregroundColor(.secondary)
                                .padding(.leading, 40)
                            Spacer()
                            TextField("", text: $startNickname)
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
                                if let endLocation = trip.endLocation {
                                    Text(endLocation.displayAddress)
                                        .multilineTextAlignment(.trailing)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            HStack {
                                Text("Nickname")
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 40)
                                Spacer()
                                TextField("", text: $endNickname)
                                    .textFieldStyle(.roundedBorder)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                    }
                }
                
                // Map preview
                if let endLocation = trip.endLocation {
                    Section("Route") {
                        RecordedTripMap(
                            startCoordinate: trip.startLocation.coordinate,
                            endCoordinate: endLocation.coordinate,
                            routePoints: trip.routePoints ?? [],
                            isInteractive: true
                        )
                        .frame(height: 200)
                        .cornerRadius(8)
                    }
                }

                Section("Notes") {
                    TextEditor(text: Binding(
                        get: { trip.notes ?? "" },
                        set: { trip.notes = $0.isEmpty ? nil : $0 }
                    ))
                    .frame(minHeight: 100)
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
                            tripStore.applyLocationNicknameToMatchingTrips(
                                nicknameId: nicknameId,
                                coordinate: trip.startLocation.coordinate,
                                address: trip.startLocation.address
                            )
                        } else {
                            tripStore.removeLocationNickname(
                                coordinate: trip.startLocation.coordinate,
                                address: trip.startLocation.address
                            )
                            trip.startLocation.locationNicknameId = nil
                        }
                        
                        if !endNickname.isEmpty, let endLocation = trip.endLocation {
                            let nicknameId = tripStore.setLocationNickname(
                                coordinate: endLocation.coordinate,
                                address: endLocation.address,
                                nickname: endNickname
                            )
                            trip.endLocation?.locationNicknameId = nicknameId
                            tripStore.applyLocationNicknameToMatchingTrips(
                                nicknameId: nicknameId,
                                coordinate: endLocation.coordinate,
                                address: endLocation.address
                            )
                        } else if let endLocation = trip.endLocation {
                            tripStore.removeLocationNickname(
                                coordinate: endLocation.coordinate,
                                address: endLocation.address
                            )
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
            return String(format: NSLocalizedString("%dh %dm", comment: "Trip duration"), hours, minutes)
        } else {
            return String(format: NSLocalizedString("%dm", comment: "Trip duration"), minutes)
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
        purposeName: TripPurpose.openHouse.rawValue,
        vehicle: nil,
        notes: nil
    ))
    .environmentObject(TripStore())
}
