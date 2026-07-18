//
//  OB9ProcessingView.swift
//  RealEstateMileageTracker
//

import SwiftUI

struct OB9ProcessingView: View {
    @ObservedObject var vm: OnboardingViewModel
    @State private var spinAngle: Double = 0

    private let steps = [
        "Configuring trip detection",
        "Setting current IRS rate",
        "Ready to track"
    ]

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "car.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue.gradient)
                .rotationEffect(.degrees(spinAngle))
                .onAppear {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        spinAngle = 360
                    }
                }

            Text("Setting up your\nmileage tracker...")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 16) {
                ForEach(0..<steps.count, id: \.self) { i in
                    HStack(spacing: 12) {
                        Image(systemName: vm.processingStep > i ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(vm.processingStep > i ? .green : Color(.systemGray3))
                        Text(steps[i])
                            .font(.subheadline)
                            .foregroundColor(vm.processingStep > i ? .primary : .secondary)
                    }
                    .animation(.easeInOut(duration: 0.3), value: vm.processingStep)
                }
            }
            .padding(.horizontal, 48)

            Spacer()
        }
        .onAppear {
            vm.runProcessingAnimation { vm.advance() }
        }
    }
}
