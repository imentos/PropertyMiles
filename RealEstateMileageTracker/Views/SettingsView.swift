//
//  SettingsView.swift
//  RealEstateMileageTracker
//
//  Created by Kuo, Ray on 3/8/26.
//

import SwiftUI
import CoreLocation

struct SettingsView: View {
    @EnvironmentObject var tripManager: TripManager
    @EnvironmentObject var tripStore: TripStore
    @State private var showingPermissionAlert = false
    @State private var tapCount = 0
    @State private var showDebugModeAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Location Tracking") {
                    HStack {
                        Label("Permission Status", systemImage: "location.circle")
                        Spacer()
                        Text(permissionStatusText)
                            .foregroundColor(permissionStatusColor)
                    }
                    
                    if tripManager.locationPermissionStatus != .authorizedAlways {
                        Button {
                            showingPermissionAlert = true
                        } label: {
                            Label("Request Permission", systemImage: "location.fill")
                        }
                    }
                    
                    Toggle(isOn: $tripManager.isTracking) {
                        Label("Auto-Track Trips", systemImage: tripManager.isTracking ? "play.circle.fill" : "pause.circle.fill")
                    }
                    .onChange(of: tripManager.isTracking) { newValue in
                        if newValue {
                            tripManager.startTracking()
                        } else {
                            tripManager.stopTracking()
                        }
                    }
                }
                
                Section("Mileage Rate") {
                    HStack {
                        Label("IRS Standard Rate", systemImage: "dollarsign.circle")
                        Spacer()
                        Text("$0.67/mile")
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Rate for 2025 tax year")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if tripManager.debugMode {
                    Section {
                        HStack {
                            Image(systemName: "ant.circle.fill")
                                .foregroundColor(.orange)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Debug Mode Active")
                                    .font(.headline)
                                    .foregroundColor(.orange)
                                Text("Walking speed (~1 mph) triggers trips • Stops after 30s")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                        
                        Button {
                            tripStore.generateSampleTrips()
                        } label: {
                            Label("Generate Sample Trips", systemImage: "text.badge.plus")
                        }
                        
                        Button(role: .destructive) {
                            tripStore.clearAllTrips()
                        } label: {
                            Label("Clear All Trips", systemImage: "trash")
                        }
                    } header: {
                        Text("Debug Tools")
                    }
                }
                
                Section("About") {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0\(tripManager.debugMode ? " [DEBUG]" : "")")
                            .foregroundColor(tripManager.debugMode ? .orange : .secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        tapCount += 1
                        if tapCount >= 7 {
                            tripManager.debugMode.toggle()
                            showDebugModeAlert = true
                            tapCount = 0
                        }
                        // Reset tap count after 2 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            tapCount = 0
                        }
                    }
                    
                    Link(destination: URL(string: "https://www.irs.gov/tax-professionals/standard-mileage-rates")!) {
                        Label("IRS Mileage Information", systemImage: "link")
                    }
                }
                
                Section {
                    Text("Automatically tracks your driving trips for real estate business mileage. Make sure to enable 'Always Allow' location permission for best results.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Settings")
            .alert("Location Permission Required", isPresented: $showingPermissionAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Please go to Settings and allow 'Always' location access for automatic trip tracking.")
            }
            .alert(tripManager.debugMode ? "Debug Mode Enabled" : "Debug Mode Disabled", isPresented: $showDebugModeAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                if tripManager.debugMode {
                    Text("Walking speed (~1 mph) will trigger trips. Trips end after 30 seconds stopped. Great for testing!")
                } else {
                    Text("Trips now require driving speed (10+ mph) and stop after 3 minutes.")
                }
            }
        }
    }
    
    private var permissionStatusText: String {
        switch tripManager.locationPermissionStatus {
        case .notDetermined:
            return "Not Set"
        case .restricted:
            return "Restricted"
        case .denied:
            return "Denied"
        case .authorizedAlways:
            return "Allowed"
        case .authorizedWhenInUse:
            return "When In Use"
        @unknown default:
            return "Unknown"
        }
    }
    
    private var permissionStatusColor: Color {
        switch tripManager.locationPermissionStatus {
        case .authorizedAlways:
            return .green
        case .authorizedWhenInUse:
            return .orange
        default:
            return .red
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(TripManager())
        .environmentObject(TripStore())
}
