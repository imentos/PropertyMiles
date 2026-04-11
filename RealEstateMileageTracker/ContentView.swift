//
//  ContentView.swift
//  RealEstateMileageTracker
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var tripStore: TripStore

    var body: some View {
        if tripStore.hasCompletedOnboarding {
            MainTabView()
        } else {
            OnboardingView {
                // onComplete is handled inside OnboardingView via vm.complete(tripStore:)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(TripStore())
        .environmentObject(TripManager())
}
