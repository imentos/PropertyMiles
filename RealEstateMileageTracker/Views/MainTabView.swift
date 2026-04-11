//
//  MainTabView.swift
//  RealEstateMileageTracker
//
//  Created by Kuo, Ray on 3/8/26.
//

import SwiftUI
import CoreLocation

struct MainTabView: View {
    @EnvironmentObject private var tripStore: TripStore
    @EnvironmentObject private var tripManager: TripManager

    var body: some View {
        TabView {
            TripsView()
                .tabItem {
                    Label("Trips", systemImage: "car")
                }

            LocationNicknamesView()
                .tabItem {
                    Label("Locations", systemImage: "map")
                }

            ReportsView()
                .tabItem {
                    Label("Reports", systemImage: "chart.bar")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .onAppear {
            // Link tripStore to tripManager for place matching
            tripManager.tripStore = tripStore
            
            // Request location permission on first launch
            if tripManager.locationPermissionStatus == .notDetermined {
                tripManager.requestLocationPermission()
            }
            // Auto-start tracking if already authorized
            else if tripManager.locationPermissionStatus == .authorizedAlways && !tripManager.isTracking {
                print("🚀 Starting tracking from MainTabView (already authorized)")
                tripManager.startTracking()
            }
        }
    }
}

#Preview {
    MainTabView()
}
