//
//  PlacesView.swift
//  RealEstateMileageTracker
//
//  Created by Kuo, Ray on 3/8/26.
//

import SwiftUI
import CoreLocation

struct PlacesView: View {
    @EnvironmentObject var tripStore: TripStore
    @State private var showingAddPlace = false
    @State private var editingPlace: Place?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(tripStore.places) { place in
                    PlaceRow(place: place)
                        .onTapGesture {
                            editingPlace = place
                        }
                }
                .onDelete(perform: deletePlaces)
            }
            .navigationTitle("Places")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddPlace = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddPlace) {
                AddPlaceView()
            }
            .sheet(item: $editingPlace) { place in
                EditPlaceView(place: place)
            }
            .overlay {
                if tripStore.places.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "building.2")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("No Places")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Add places to tag your trips")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button {
                            showingAddPlace = true
                        } label: {
                            Label("Add Place", systemImage: "plus.circle.fill")
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.top, 8)
                    }
                }
            }
        }
    }
    
    private func deletePlaces(at offsets: IndexSet) {
        for index in offsets {
            tripStore.deletePlace(tripStore.places[index])
        }
    }
}

struct PlaceRow: View {
    let place: Place
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let nickname = place.nickname {
                Text(nickname)
                    .font(.headline)
                Text(place.address)
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text(place.address)
                    .font(.headline)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddPlaceView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var tripStore: TripStore
    
    @State private var address = ""
    @State private var nickname = ""
    @State private var isGeocoding = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Place Information") {
                    TextField("Address", text: $address)
                        .textContentType(.fullStreetAddress)
                    
                    TextField("Nickname (Optional)", text: $nickname)
                }
                
                Section {
                    Text("Add places to quickly tag trips and organize your mileage records. The address will be geocoded to enable automatic trip matching.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Add Place")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isGeocoding)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addPlace()
                    }
                    .fontWeight(.semibold)
                    .disabled(address.isEmpty || isGeocoding)
                }
            }
        }
    }
    
    private func addPlace() {
        isGeocoding = true
        
        // Geocode the address
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { placemarks, error in
            let location: LocationData?
            
            if let placemark = placemarks?.first, let coordinate = placemark.location?.coordinate {
                location = LocationData(coordinate: coordinate)
                print("📍 Geocoded place '\(address)' to: \(coordinate.latitude), \(coordinate.longitude)")
            } else {
                location = nil
                print("⚠️ Could not geocode place address: \(address)")
            }
            
            let place = Place(
                address: address,
                nickname: nickname.isEmpty ? nil : nickname,
                location: location
            )
            tripStore.addPlace(place)
            
            isGeocoding = false
            dismiss()
        }
    }
}

struct EditPlaceView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var tripStore: TripStore
    
    @State private var place: Place
    @State private var address: String
    @State private var nickname: String
    @State private var isGeocoding = false
    
    init(place: Place) {
        _place = State(initialValue: place)
        _address = State(initialValue: place.address)
        _nickname = State(initialValue: place.nickname ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Place Information") {
                    TextField("Address", text: $address)
                        .textContentType(.fullStreetAddress)
                    
                    TextField("Nickname (Optional)", text: $nickname)
                }
                
                Section {
                    Text("Updating the address will re-geocode the location for automatic trip matching.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Edit Place")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isGeocoding)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        savePlace()
                    }
                    .fontWeight(.semibold)
                    .disabled(address.isEmpty || isGeocoding)
                }
            }
        }
    }
    
    private func savePlace() {
        isGeocoding = true
        
        // Re-geocode if address changed
        if address != place.address {
            let geocoder = CLGeocoder()
            geocoder.geocodeAddressString(address) { placemarks, error in
                var updatedPlace = place
                updatedPlace.address = address
                updatedPlace.nickname = nickname.isEmpty ? nil : nickname
                
                if let placemark = placemarks?.first, let coordinate = placemark.location?.coordinate {
                    updatedPlace.location = LocationData(coordinate: coordinate)
                    print("📍 Re-geocoded place '\(address)' to: \(coordinate.latitude), \(coordinate.longitude)")
                } else {
                    // Keep old location if geocoding fails
                    print("⚠️ Could not geocode place address: \(address)")
                }
                
                tripStore.updatePlace(updatedPlace)
                isGeocoding = false
                dismiss()
            }
        } else {
            // Just update nickname if address unchanged
            var updatedPlace = place
            updatedPlace.nickname = nickname.isEmpty ? nil : nickname
            tripStore.updatePlace(updatedPlace)
            dismiss()
        }
    }
}

struct PlacePickerView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var tripStore: TripStore
    @Binding var selectedPlace: Place?
    @State private var showingAddPlace = false
    
    var body: some View {
        NavigationView {
            List {
                Button {
                    selectedPlace = nil
                    dismiss()
                } label: {
                    HStack {
                        Text("None")
                        Spacer()
                        if selectedPlace == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                ForEach(tripStore.places) { place in
                    Button {
                        selectedPlace = place
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                if let nickname = place.nickname {
                                    Text(nickname)
                                        .font(.headline)
                                    Text(place.address)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text(place.address)
                                }
                            }
                            
                            Spacer()
                            
                            if selectedPlace?.id == place.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Select Place")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddPlace = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddPlace) {
                AddPlaceView()
            }
        }
    }
}

#Preview {
    PlacesView()
        .environmentObject(TripStore())
}
