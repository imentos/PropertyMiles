//
//  OnboardingView.swift
//  RealEstateMileageTracker
//

import SwiftUI

struct OnboardingView: View {
    var onComplete: () -> Void
    @StateObject private var vm = OnboardingViewModel()
    @EnvironmentObject var tripStore: TripStore

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color(.systemGray5)).frame(height: 4)
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geo.size.width * CGFloat(vm.currentStep) / CGFloat(vm.totalSteps), height: 4)
                        .animation(.easeInOut(duration: 0.3), value: vm.currentStep)
                }
            }
            .frame(height: 4)

            // Back button
            HStack {
                if vm.currentStep > 1 {
                    Button(action: vm.goBack) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(.primary)
                            .padding(12)
                    }
                }
                Spacer()
            }
            .frame(height: 44)

            // Step content
            stepView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private var stepView: some View {
        switch vm.currentStep {
        case 1:  OB1WelcomeView(vm: vm)
        case 2:  OB2GoalView(vm: vm)
        case 3:  OB3PainPointsView(vm: vm)
        case 4:  OB4SocialProofView(vm: vm)
        case 5:  OB5TinderCardsView(vm: vm)
        case 6:  OB6SolutionView(vm: vm)
        case 7:  OB7PreferenceView(vm: vm)
        case 8:  OB8LocationPrimingView(vm: vm)
        case 9:  OB9ProcessingView(vm: vm)
        case 10: OB10PaywallView(vm: vm, onComplete: {
            vm.complete(tripStore: tripStore)
            onComplete()
        })
        default: OB1WelcomeView(vm: vm)
        }
    }
}
