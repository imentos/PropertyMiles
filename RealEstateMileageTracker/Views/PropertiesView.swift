//
//  PropertiesView.swift
//  RealEstateMileageTracker
//
//  Created by Kuo, Ray on 3/8/26.
//

import SwiftUI
import CoreLocation

struct PropertiesView: View {
    @EnvironmentObject var tripStore: TripStore
    @State private var showingAddProperty = false
    @State private var editingProperty: Property?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(tripStore.properties) { property in
                    PropertyRow(property: property)
                        .onTapGesture {
                            editingProperty = property
                        }
                }
                .onDelete(perform: deleteProperties)
            }
            .navigationTitle("Properties")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddProperty = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddProperty) {
                AddPropertyView()
            }
            .sheet(item: $editingProperty) { property in
                EditPropertyView(property: property)
            }
            .overlay {
                if tripStore.properties.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "building.2")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("No Properties")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Add properties to tag your trips")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button {
                            showingAddProperty = true
                        } label: {
                            Label("Add Property", systemImage: "plus.circle.fill")
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
    
    private func deleteProperties(at offsets: IndexSet) {
        for index in offsets {
            tripStore.deleteProperty(tripStore.properties[index])
        }
    }
}

struct PropertyRow: View {
    let property: Property
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let nickname = property.nickname {
                Text(nickname)
                    .font(.headline)
                Text(property.address)
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text(property.address)
                    .font(.headline)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddPropertyView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var tripStore: TripStore
    
    @State private var address = ""
    @State private var nickname = ""
    @State private var isGeocoding = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Property Information") {
                    TextField("Address", text: $address)
                        .textContentType(.fullStreetAddress)
                    
                    TextField("Nickname (Optional)", text: $nickname)
                }
                
                Section {
                    Text("Add properties to quickly tag trips and organize your mileage records. The address will be geocoded to enable automatic trip matching.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Add Property")
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
                        addProperty()
                    }
                    .fontWeight(.semibold)
                    .disabled(address.isEmpty || isGeocoding)
                }
            }
        }
    }
    
    private func addProperty() {
        isGeocoding = true
        
        // Geocode the address
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { placemarks, error in
            let location: LocationData?
            
            if let placemark = placemarks?.first, let coordinate = placemark.location?.coordinate {
                location = LocationData(coordinate: coordinate)
                print("📍 Geocoded property '\(address)' to: \(coordinate.latitude), \(coordinate.longitude)")
            } else {
                location = nil
                print("⚠️ Could not geocode property address: \(address)")
            }
            
            let property = Property(
                address: address,
                nickname: nickname.isEmpty ? nil : nickname,
                location: location
            )
            tripStore.addProperty(property)
            
            isGeocoding = false
            dismiss()
        }
    }
}

struct EditPropertyView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var tripStore: TripStore
    
    @State private var property: Property
    @State private var address: String
    @State private var nickname: String
    @State private var isGeocoding = false
    
    init(property: Property) {
        _property = State(initialValue: property)
        _address = State(initialValue: property.address)
        _nickname = State(initialValue: property.nickname ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Property Information") {
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
            .navigationTitle("Edit Property")
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
                        saveProperty()
                    }
                    .fontWeight(.semibold)
                    .disabled(address.isEmpty || isGeocoding)
                }
            }
        }
    }
    
    private func saveProperty() {
        isGeocoding = true
        
        // Re-geocode if address changed
        if address != property.address {
            let geocoder = CLGeocoder()
            geocoder.geocodeAddressString(address) { placemarks, error in
                var updatedProperty = property
                updatedProperty.address = address
                updatedProperty.nickname = nickname.isEmpty ? nil : nickname
                
                if let placemark = placemarks?.first, let coordinate = placemark.location?.coordinate {
                    updatedProperty.location = LocationData(coordinate: coordinate)
                    print("📍 Re-geocoded property '\(address)' to: \(coordinate.latitude), \(coordinate.longitude)")
                } else {
                    // Keep old location if geocoding fails
                    print("⚠️ Could not geocode property address: \(address)")
                }
                
                tripStore.updateProperty(updatedProperty)
                isGeocoding = false
                dismiss()
            }
        } else {
            // Just update nickname if address unchanged
            var updatedProperty = property
            updatedProperty.nickname = nickname.isEmpty ? nil : nickname
            tripStore.updateProperty(updatedProperty)
            dismiss()
        }
    }
}

struct PropertyPickerView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var tripStore: TripStore
    @Binding var selectedProperty: Property?
    @State private var showingAddProperty = false
    
    var body: some View {
        NavigationView {
            List {
                Button {
                    selectedProperty = nil
                    dismiss()
                } label: {
                    HStack {
                        Text("None")
                        Spacer()
                        if selectedProperty == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                ForEach(tripStore.properties) { property in
                    Button {
                        selectedProperty = property
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                if let nickname = property.nickname {
                                    Text(nickname)
                                        .font(.headline)
                                    Text(property.address)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text(property.address)
                                }
                            }
                            
                            Spacer()
                            
                            if selectedProperty?.id == property.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Select Property")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddProperty = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddProperty) {
                AddPropertyView()
            }
        }
    }
}

#Preview {
    PropertiesView()
        .environmentObject(TripStore())
}
