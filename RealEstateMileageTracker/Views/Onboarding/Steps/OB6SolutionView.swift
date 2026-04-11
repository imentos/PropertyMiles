//
//  OB6SolutionView.swift
//  RealEstateMileageTracker
//

import SwiftUI

struct OB6SolutionView: View {
    @ObservedObject var vm: OnboardingViewModel

    private let rows: [(pain: String, solution: String, icon: String)] = [
        ("Forgetting to log trips", "Auto-detects every drive over 10 mph", "car.fill"),
        ("Unknown deduction value", "Live total updated after every trip", "dollarsign.circle.fill"),
        ("Tax-time scramble", "One-tap CSV ready for your accountant", "doc.text.fill"),
        ("Mixed personal/business", "Tag business trips in seconds", "tag.fill")
    ]

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("LandMile works\nwhile you work.")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                Text("Here's how it solves each problem.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)

            ScrollView {
                VStack(spacing: 16) {
                    ForEach(rows, id: \.pain) { row in
                        SolutionRow(pain: row.pain, solution: row.solution, icon: row.icon)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
            }

            Button(action: { vm.advance() }) {
                Text("Sounds good →")
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
}

private struct SolutionRow: View {
    let pain: String
    let solution: String
    let icon: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue.gradient)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 4) {
                Text(pain)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(solution)
                    .font(.subheadline.bold())
            }
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(14)
    }
}
