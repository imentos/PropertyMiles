//
//  PropertiesView.swift
//  RealEstateMileageTracker
//
//  Created by Kuo, Ray on 3/8/26.
//

import SwiftUI

struct PropertiesView: View {
    @EnvironmentObject var tripStore: TripStore
    @State private var showingAddProperty = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(tripStore.properties) { property in
                    PropertyRow(property: property)
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
    
    var body: some View {
        NavigationView {
            Form {
                Section("Property Information") {
                    TextField("Address", text: $address)
                        .textContentType(.fullStreetAddress)
                    
                    TextField("Nickname (Optional)", text: $nickname)
                }
                
                Section {
                    Text("Add properties to quickly tag trips and organize your mileage records.")
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
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        let property = Property(
                            address: address,
                            nickname: nickname.isEmpty ? nil : nickname
                        )
                        tripStore.addProperty(property)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(address.isEmpty)
                }
            }
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
