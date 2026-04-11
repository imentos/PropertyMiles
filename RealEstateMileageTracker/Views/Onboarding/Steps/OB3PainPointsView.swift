//
//  OB3PainPointsView.swift
//  RealEstateMileageTracker
//

import SwiftUI

struct OB3PainPointsView: View {
    @ObservedObject var vm: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("What makes tracking\nmileage hard?")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                Text("Select all that apply.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(vm.painPoints, id: \.self) { point in
                        PainPointRow(
                            text: point,
                            isSelected: vm.selectedPainPoints.contains(point)
                        ) {
                            if vm.selectedPainPoints.contains(point) {
                                vm.selectedPainPoints.remove(point)
                            } else {
                                vm.selectedPainPoints.insert(point)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
            }

            Button(action: { vm.advance() }) {
                Text("Continue →")
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

private struct PainPointRow: View {
    let text: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(isSelected ? .blue : Color(.systemGray3))
                    .font(.title3)
                Text(text).font(.subheadline).foregroundColor(.primary)
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.08) : Color(.systemGray6))
            )
        }
        .buttonStyle(.plain)
    }
}
