//
//  OB8LocationPrimingView.swift
//  RealEstateMileageTracker
//

import SwiftUI
import CoreLocation

struct OB8LocationPrimingView: View {
    @ObservedObject var vm: OnboardingViewModel
    @EnvironmentObject var tripManager: TripManager

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue.gradient)

                VStack(spacing: 8) {
                    Text("Track every mile\nautomatically.")
                        .font(.title.bold())
                        .multilineTextAlignment(.center)
                    Text("LandMile needs location access to detect\ntrips while you drive.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: 14) {
                    BenefitRow(icon: "play.circle.fill", text: "Trips start the moment you drive away")
                    BenefitRow(icon: "hand.raised.slash.fill", text: "No tapping, no manual logging")
                    BenefitRow(icon: "lock.shield.fill", text: "Your location is never shared with anyone")
                }
                .padding(.horizontal, 16)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .padding(.horizontal, 24)
            }

            Spacer()

            VStack(spacing: 12) {
                Button(action: requestLocation) {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }

    private func requestLocation() {
        tripManager.requestLocationPermission()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            vm.advance()
        }
    }
}

private struct BenefitRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            Text(text).font(.subheadline)
            Spacer()
        }
    }
}
