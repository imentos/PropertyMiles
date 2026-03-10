//
//  VehiclesManagementView.swift
//  RealEstateMileageTracker
//
//  Created by Kuo, Ray on 3/9/26.
//

import SwiftUI

struct VehiclesManagementView: View {
    @EnvironmentObject var tripStore: TripStore
    @State private var showingAddVehicle = false
    @State private var editingVehicle: Vehicle?
    
    var body: some View {
        List {
            ForEach(tripStore.vehicles) { vehicle in
                VehicleRow(vehicle: vehicle)
                    .onTapGesture {
                        editingVehicle = vehicle
                    }
            }
            .onDelete(perform: deleteVehicles)
        }
        .navigationTitle("Vehicles")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddVehicle = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddVehicle) {
            AddVehicleView()
        }
        .sheet(item: $editingVehicle) { vehicle in
            EditVehicleView(vehicle: vehicle)
        }
        .overlay {
            if tripStore.vehicles.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "car.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    
                    Text("No Vehicles")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Add vehicles for IRS reporting")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button {
                        showingAddVehicle = true
                    } label: {
                        Label("Add Vehicle", systemImage: "plus.circle.fill")
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
    
    private func deleteVehicles(at offsets: IndexSet) {
        for index in offsets {
            tripStore.deleteVehicle(tripStore.vehicles[index])
        }
    }
}

struct VehicleRow: View {
    let vehicle: Vehicle
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(vehicle.displayName)
                .font(.headline)
        }
        .padding(.vertical, 4)
    }
}

struct AddVehicleView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var tripStore: TripStore
    
    @State private var make = ""
    @State private var model = ""
    @State private var year = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Vehicle Information") {
                    TextField("Make (e.g., Toyota)", text: $make)
                        .textContentType(.none)
                    
                    TextField("Model (e.g., Camry)", text: $model)
                        .textContentType(.none)
                    
                    TextField("Year (e.g., 2023)", text: $year)
                        .keyboardType(.numberPad)
                }
                
                Section {
                    Text("Vehicle information is required for IRS mileage reporting. Enter the make, model, and year of the vehicle used for business trips.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Add Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addVehicle()
                    }
                    .fontWeight(.semibold)
                    .disabled(make.isEmpty || model.isEmpty || year.isEmpty)
                }
            }
        }
    }
    
    private func addVehicle() {
        let vehicle = Vehicle(
            make: make.trimmingCharacters(in: .whitespacesAndNewlines),
            model: model.trimmingCharacters(in: .whitespacesAndNewlines),
            year: year.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        tripStore.addVehicle(vehicle)
        dismiss()
    }
}

struct EditVehicleView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var tripStore: TripStore
    
    let vehicle: Vehicle
    
    @State private var make: String
    @State private var model: String
    @State private var year: String
    
    init(vehicle: Vehicle) {
        self.vehicle = vehicle
        _make = State(initialValue: vehicle.make)
        _model = State(initialValue: vehicle.model)
        _year = State(initialValue: vehicle.year)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Vehicle Information") {
                    TextField("Make", text: $make)
                        .textContentType(.none)
                    
                    TextField("Model", text: $model)
                        .textContentType(.none)
                    
                    TextField("Year", text: $year)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Edit Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        updateVehicle()
                    }
                    .fontWeight(.semibold)
                    .disabled(make.isEmpty || model.isEmpty || year.isEmpty)
                }
            }
        }
    }
    
    private func updateVehicle() {
        var updatedVehicle = vehicle
        updatedVehicle.make = make.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedVehicle.model = model.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedVehicle.year = year.trimmingCharacters(in: .whitespacesAndNewlines)
        
        tripStore.updateVehicle(updatedVehicle)
        dismiss()
    }
}

#Preview {
    NavigationView {
        VehiclesManagementView()
            .environmentObject(TripStore())
    }
}

struct VehiclePickerView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var tripStore: TripStore
    @Binding var selectedVehicle: Vehicle?
    @State private var showingAddVehicle = false
    
    var body: some View {
        NavigationView {
            List {
                Button {
                    selectedVehicle = nil
                    dismiss()
                } label: {
                    HStack {
                        Text("None")
                        Spacer()
                        if selectedVehicle == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                ForEach(tripStore.vehicles) { vehicle in
                    Button {
                        selectedVehicle = vehicle
                        dismiss()
                    } label: {
                        HStack {
                            Text(vehicle.displayName)
                            
                            Spacer()
                            
                            if selectedVehicle?.id == vehicle.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Select Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddVehicle = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddVehicle) {
                AddVehicleView()
            }
        }
    }
}
