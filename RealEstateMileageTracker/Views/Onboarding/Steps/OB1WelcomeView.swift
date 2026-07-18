//
//  OB1WelcomeView.swift
//  RealEstateMileageTracker
//

import SwiftUI

struct OB1WelcomeView: View {
    @ObservedObject var vm: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            tripSummaryMock
                .padding(.bottom, 40)

            Text("Every business mile\ncan be worth up to $0.76.")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Text("Property managers miss an average of\n$3,200 in tax deductions every year.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 12)

            Spacer()

            Button(action: { vm.advance() }) {
                Text("Start Saving →")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }

    private var tripSummaryMock: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("This Month")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("247.3 miles")
                        .font(.title2.bold())
                    Text("$165.69 deduction")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                Spacer()
                Image(systemName: "car.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.blue.gradient)
            }
            .padding()

            Divider()

            VStack(spacing: 8) {
                MockTripRow(icon: "wrench.fill", purpose: "Maintenance", address: "123 Oak St", miles: "12.4 mi")
                MockTripRow(icon: "key.fill", purpose: "Showing", address: "456 Elm Ave", miles: "8.7 mi")
                MockTripRow(icon: "dollarsign.circle.fill", purpose: "Rent Collection", address: "789 Pine Rd", miles: "5.2 mi")
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.12), radius: 16, y: 6)
        .padding(.horizontal, 24)
    }
}

private struct MockTripRow: View {
    let icon: String
    let purpose: String
    let address: String
    let miles: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(purpose).font(.caption.bold())
                Text(address).font(.caption2).foregroundColor(.secondary)
            }
            Spacer()
            Text(miles).font(.caption.bold()).foregroundColor(.blue)
        }
    }
}
