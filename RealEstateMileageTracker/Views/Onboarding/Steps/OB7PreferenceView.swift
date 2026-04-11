//
//  OB7PreferenceView.swift
//  RealEstateMileageTracker
//

import SwiftUI

struct OB7PreferenceView: View {
    @ObservedObject var vm: OnboardingViewModel
    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("What types of trips\ndo you make most?")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                Text("We'll pre-set your trip purposes.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(vm.tripTypes, id: \.text) { tripType in
                        TripTypeCell(
                            icon: tripType.icon,
                            text: tripType.text,
                            isSelected: vm.selectedTripTypes.contains(tripType.text)
                        ) {
                            if vm.selectedTripTypes.contains(tripType.text) {
                                vm.selectedTripTypes.remove(tripType.text)
                            } else {
                                vm.selectedTripTypes.insert(tripType.text)
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

private struct TripTypeCell: View {
    let icon: String
    let text: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                Text(icon).font(.largeTitle)
                Text(text)
                    .font(.caption.bold())
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(isSelected ? Color.blue : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
                    .background(RoundedRectangle(cornerRadius: 14).fill(isSelected ? Color.blue.opacity(0.08) : Color(.systemBackground)))
            )
        }
        .buttonStyle(.plain)
    }
}
