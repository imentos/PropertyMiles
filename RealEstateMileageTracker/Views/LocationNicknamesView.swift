//
//  LocationNicknamesView.swift
//  RealEstateMileageTracker
//
//  Created by Kuo, Ray on 3/10/26.
//

import SwiftUI
import CoreLocation

struct LocationNicknamesView: View {
    @EnvironmentObject var tripStore: TripStore
    @State private var editingLocation: LocationNickname?
    @State private var showingAddLocation = false
    
    var sortedLocations: [LocationNickname] {
        tripStore.locationNicknames.sorted { $0.lastUsed > $1.lastUsed }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(sortedLocations) { location in
                    LocationNicknameRow(location: location)
                        .onTapGesture {
                            editingLocation = location
                        }
                }
                .onDelete(perform: deleteLocations)
            }
            .navigationTitle("Locations")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddLocation = true
                    } label: {
                        Label("Add Location", systemImage: "plus")
                    }
                }
            }
            .sheet(item: $editingLocation) { location in
                EditLocationNicknameView(location: location)
            }
            .sheet(isPresented: $showingAddLocation) {
                AddLocationNicknameView()
            }
            .overlay {
                if tripStore.locationNicknames.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "map")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("No Saved Locations")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Location nicknames will appear here as you add them to trips")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button {
                            showingAddLocation = true
                        } label: {
                            Label("Add Location", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
    }
    
    private func deleteLocations(at offsets: IndexSet) {
        for index in offsets {
            let location = sortedLocations[index]
            tripStore.locationNicknames.removeAll { $0.id == location.id }
        }
        tripStore.locationNicknamesLastModified = Date()
        tripStore.saveLocationNicknames()
    }
}


struct AddLocationNicknameView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var tripStore: TripStore

    @State private var nickname = ""
    @State private var address = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let geocoder = CLGeocoder()

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Name", text: $nickname)
                        .textContentType(.organizationName)

                    TextField("Address", text: $address, axis: .vertical)
                        .textContentType(.fullStreetAddress)
                        .lineLimit(2...4)
                } header: {
                    Text("Location")
                } footer: {
                    Text("Use a full address so LandMile can match future trips near this location.")
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Add Location")
            .navigationBarTitleDisplayMode(.inline)
            .disabled(isSaving)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSaving)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving..." : "Save") {
                        saveLocation()
                    }
                    .disabled(!canSave || isSaving)
                }
            }
        }
    }

    private var canSave: Bool {
        !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func saveLocation() {
        let trimmedNickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedNickname.isEmpty, !trimmedAddress.isEmpty else { return }

        isSaving = true
        errorMessage = nil

        geocoder.geocodeAddressString(trimmedAddress) { placemarks, error in
            DispatchQueue.main.async {
                isSaving = false

                if let error {
                    errorMessage = "Could not find that address. \(error.localizedDescription)"
                    return
                }

                guard let coordinate = placemarks?.first?.location?.coordinate else {
                    errorMessage = "Could not find that address. Try a more specific address."
                    return
                }

                let nicknameId = tripStore.setLocationNickname(
                    coordinate: coordinate,
                    address: trimmedAddress,
                    nickname: trimmedNickname
                )
                tripStore.applyLocationNicknameToMatchingTrips(
                    nicknameId: nicknameId,
                    coordinate: coordinate,
                    address: trimmedAddress
                )

                dismiss()
            }
        }
    }
}

struct LocationNicknameRow: View {
    let location: LocationNickname
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(location.nickname)
                .font(.headline)
            
            if let address = location.coordinate.address {
                Text(address)
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("\(location.coordinate.latitude), \(location.coordinate.longitude)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("Last used: \(formatDate(location.lastUsed))")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct EditLocationNicknameView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var tripStore: TripStore
    
    @State private var location: LocationNickname
    @State private var nickname: String
    
    init(location: LocationNickname) {
        _location = State(initialValue: location)
        _nickname = State(initialValue: location.nickname)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Location") {
                    if let address = location.coordinate.address {
                        Text(address)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text("\(location.coordinate.latitude), \(location.coordinate.longitude)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Section("Nickname") {
                    TextField("Nickname", text: $nickname)
                }
            }
            .navigationTitle("Edit Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveLocation()
                    }
                    .disabled(nickname.isEmpty)
                }
            }
        }
    }
    
    private func saveLocation() {
        if let index = tripStore.locationNicknames.firstIndex(where: { $0.id == location.id }) {
            tripStore.locationNicknames[index].nickname = nickname
            tripStore.locationNicknames[index].lastUsed = Date()
            tripStore.locationNicknamesLastModified = Date()
            tripStore.saveLocationNicknames()
            tripStore.applyLocationNicknameToMatchingTrips(
                nicknameId: location.id,
                coordinate: location.coordinate.coordinate,
                address: location.coordinate.address
            )
        }
        dismiss()
    }
}

#Preview {
    LocationNicknamesView()
        .environmentObject(TripStore())
}
