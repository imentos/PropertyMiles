//
//  RealEstateMileageTrackerApp.swift
//  RealEstateMileageTracker
//
//  Created by Kuo, Ray on 3/8/26.
//

import SwiftUI

@main
struct RealEstateMileageTrackerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var tripStore = TripStore()
    @StateObject private var tripManager = TripManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(tripStore)
                .environmentObject(tripManager)
        }
    }
}
