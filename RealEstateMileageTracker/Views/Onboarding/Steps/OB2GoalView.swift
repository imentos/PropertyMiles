//
//  OB2GoalView.swift
//  RealEstateMileageTracker
//

import SwiftUI

struct OB2GoalView: View {
    @ObservedObject var vm: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("What brings you to\nLandMile?")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                Text("We'll tailor your experience.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(vm.goals, id: \.text) { goal in
                        GoalOptionRow(
                            icon: goal.icon,
                            text: goal.text,
                            isSelected: vm.selectedGoal == goal.text
                        ) {
                            vm.selectedGoal = goal.text
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
            }

            Button(action: { vm.advance() }) {
                Text("That's me →")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(vm.selectedGoal.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(16)
            }
            .disabled(vm.selectedGoal.isEmpty)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }
}

private struct GoalOptionRow: View {
    let icon: String
    let text: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Text(icon).font(.title3)
                Text(text).font(.subheadline).foregroundColor(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.blue)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? Color.blue : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
                    .background(RoundedRectangle(cornerRadius: 12).fill(isSelected ? Color.blue.opacity(0.08) : Color(.systemBackground)))
            )
        }
        .buttonStyle(.plain)
    }
}
