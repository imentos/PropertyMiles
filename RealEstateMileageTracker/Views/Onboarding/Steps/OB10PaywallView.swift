//
//  OB10PaywallView.swift
//  RealEstateMileageTracker
//

import SwiftUI
import StoreKit

struct OB10PaywallView: View {
    @ObservedObject var vm: OnboardingViewModel
    var onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            SubscriptionStoreView(productIDs: SubscriptionManager.ProductID.allCases.map { $0.rawValue }) {
                marketingHeader
            }
            .subscriptionStoreButtonLabel(.multiline)
            .subscriptionStoreControlStyle(.prominentPicker)
            .onInAppPurchaseCompletion { _, result in
                if case .success(let purchaseResult) = result,
                   case .success = purchaseResult {
                    onComplete()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Footer
            VStack(spacing: 10) {
                Button("Maybe later") { onComplete() }
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Button("Restore Purchases") {
                    Task { await SubscriptionManager.shared.restorePurchases() }
                }
                .font(.caption)
                .foregroundColor(.secondary)

                HStack(spacing: 16) {
                    Link("Terms of Use", destination: URL(string: "https://imentos.github.io/PropertyMiles/terms-of-use")!)
                    Link("Privacy Policy", destination: URL(string: "https://imentos.github.io/PropertyMiles/privacy-policy")!)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding(.vertical, 12)
        }
    }

    private var marketingHeader: some View {
        VStack(spacing: 16) {
            Image(systemName: "car.fill")
                .font(.system(size: 48))
                .foregroundStyle(.blue.gradient)
                .padding(.top, 8)

            Text("Stop leaving money\non the road.")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text("Every mile tracked = more money back at tax time.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // Features
            VStack(spacing: 10) {
                PaywallFeatureRow(icon: "car.fill",       text: "Unlimited automatic trip tracking")
                PaywallFeatureRow(icon: "doc.text.fill",  text: "IRS-compliant CSV export")
                PaywallFeatureRow(icon: "tag.fill",       text: "Vehicle & purpose management")
                PaywallFeatureRow(icon: "chart.bar.fill", text: "Full trip history & reports")
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(14)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
}

private struct PaywallFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(.blue).font(.subheadline).frame(width: 24)
            Text(text).font(.subheadline)
            Spacer()
        }
    }
}
