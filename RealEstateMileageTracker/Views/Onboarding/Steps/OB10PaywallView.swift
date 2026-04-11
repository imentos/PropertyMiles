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
            // SubscriptionStoreView manages its own scrolling
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

            // Footer pinned below
            VStack(spacing: 12) {
                Button("Maybe later") { onComplete() }
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(spacing: 16) {
                    Link("Terms of Use", destination: URL(string: "https://imentos.github.io/LandMile/terms-of-use")!)
                    Link("Privacy Policy", destination: URL(string: "https://imentos.github.io/LandMile/privacy-policy")!)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding(.vertical, 16)
        }
    }

    private var marketingHeader: some View {
        VStack(spacing: 20) {
            Image(systemName: "car.fill")
                .font(.system(size: 56))
                .foregroundStyle(.blue.gradient)
                .padding(.top, 8)

            Text("Stop leaving money\non the road.")
                .font(.title.bold())
                .multilineTextAlignment(.center)

            Text("Every mile tracked = more money back\nat tax time.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // Testimonial
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { _ in
                        Image(systemName: "star.fill").foregroundColor(.yellow).font(.caption)
                    }
                }
                Text("\"Paid for itself in the first week. I had no idea how many miles I was logging.\"")
                    .font(.subheadline)
                    .italic()
                Text("-- Sandra K., Property Manager")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGray6))
            .cornerRadius(16)

            // Features
            VStack(spacing: 14) {
                PaywallFeatureRow(icon: "car.fill",          text: "Unlimited automatic trip tracking")
                PaywallFeatureRow(icon: "doc.text.fill",     text: "IRS-compliant CSV export")
                PaywallFeatureRow(icon: "tag.fill",          text: "Vehicle & purpose management")
                PaywallFeatureRow(icon: "chart.bar.fill",    text: "Full trip history & reports")
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
    }
}

private struct PaywallFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon).foregroundColor(.blue).font(.title3).frame(width: 28)
            Text(text).font(.subheadline)
            Spacer()
        }
    }
}
