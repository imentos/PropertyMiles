//
//  CustomPurposesView.swift
//  RealEstateMileageTracker
//
//  Created by Kuo, Ray on 3/9/26.
//

import SwiftUI

struct CustomPurposesView: View {
    @EnvironmentObject var tripStore: TripStore
    @State private var showingAddPurpose = false
    @State private var newPurposeName = ""
    
    var allPurposes: [String] {
        TripPurpose.allCases.map { $0.rawValue } + tripStore.customPurposes
    }
    
    var body: some View {
        List {
            Section("Default Purposes") {
                ForEach(TripPurpose.allCases, id: \.self) { purpose in
                    HStack {
                        Image(systemName: purpose.icon)
                        Text(purpose.rawValue)
                    }
                }
            }
            
            Section("Custom Purposes") {
                ForEach(tripStore.customPurposes, id: \.self) { purpose in
                    HStack {
                        Image(systemName: "tag")
                        Text(purpose)
                    }
                }
                .onDelete(perform: deleteCustomPurpose)
            }
        }
        .navigationTitle("Trip Purposes")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddPurpose = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .alert("Add Custom Purpose", isPresented: $showingAddPurpose) {
            TextField("Purpose name", text: $newPurposeName)
            Button("Cancel", role: .cancel) {
                newPurposeName = ""
            }
            Button("Add") {
                tripStore.addCustomPurpose(newPurposeName)
                newPurposeName = ""
            }
        }
    }
    
    private func deleteCustomPurpose(at offsets: IndexSet) {
        for index in offsets {
            tripStore.deleteCustomPurpose(tripStore.customPurposes[index])
        }
    }
}

#Preview {
    NavigationView {
        CustomPurposesView()
            .environmentObject(TripStore())
    }
}
