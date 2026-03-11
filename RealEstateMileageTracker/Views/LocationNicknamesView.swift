//
//  LocationNicknamesView.swift
//  RealEstateMileageTracker
//
//  Created by Kuo, Ray on 3/10/26.
//

import SwiftUI

struct LocationNicknamesView: View {
    @EnvironmentObject var tripStore: TripStore
    @State private var editingLocation: LocationNickname?
    
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
            .sheet(item: $editingLocation) { location in
                EditLocationNicknameView(location: location)
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
        tripStore.saveLocationNicknames()
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
            tripStore.saveLocationNicknames()
        }
        dismiss()
    }
}

#Preview {
    LocationNicknamesView()
        .environmentObject(TripStore())
}
