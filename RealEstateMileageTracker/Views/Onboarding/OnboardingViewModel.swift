//
//  OnboardingViewModel.swift
//  RealEstateMileageTracker
//

import SwiftUI
import Combine

@MainActor
final class OnboardingViewModel: ObservableObject {

    // MARK: - Navigation
    @Published var currentStep: Int = 1
    let totalSteps: Int = 10

    // MARK: - Screen 2: Goal
    let goals: [(icon: String, text: String)] = [
        ("🏢", "I manage multiple rental properties"),
        ("🔑", "I'm a real estate agent doing showings"),
        ("🔧", "I handle maintenance and repairs myself"),
        ("📋", "I want to track miles for tax deductions"),
        ("💼", "My accountant asked me to track mileage")
    ]
    @Published var selectedGoal: String = ""

    // MARK: - Screen 3: Pain Points
    let painPoints: [String] = [
        "I forget to log trips while I'm busy",
        "I don't know what counts as a business mile",
        "I lose track at the end of the year",
        "My car is personal and business mixed",
        "Paper logs are too time-consuming",
        "I've missed deductions before and it cost me"
    ]
    @Published var selectedPainPoints: Set<String> = []

    // MARK: - Screen 5: Tinder Cards
    let tinderStatements: [String] = [
        "\"I've driven to the same property 12 times this year and logged maybe 3 of those trips.\"",
        "\"Tax season used to stress me out. I knew I was missing deductions but couldn't prove it.\"",
        "\"I tried spreadsheets. I tried notes apps. I always fell behind within two weeks.\"",
        "\"My accountant said I left over $2,000 on the table last year. That stings.\""
    ]
    @Published var tinderIndex: Int = 0
    @Published var tinderOffset: CGFloat = 0
    @Published var tinderRotation: Double = 0

    // MARK: - Screen 7: Trip Types
    let tripTypes: [(icon: String, text: String)] = [
        ("🔑", "Showings & move-ins"),
        ("🔧", "Maintenance & repairs"),
        ("💰", "Rent collection"),
        ("🏪", "Supply runs"),
        ("📋", "Property inspections"),
        ("⚖️", "Legal / court")
    ]
    @Published var selectedTripTypes: Set<String> = []

    // MARK: - Screen 9: Processing
    @Published var processingStep: Int = 0
    private var processingWorkItems: [DispatchWorkItem] = []

    // MARK: - Navigation

    func advance() {
        guard currentStep < totalSteps else { return }
        withAnimation(.easeInOut(duration: 0.3)) { currentStep += 1 }
    }

    func goBack() {
        guard currentStep > 1 else { return }
        withAnimation(.easeInOut(duration: 0.3)) { currentStep -= 1 }
    }

    // MARK: - Tinder Cards

    var isTinderComplete: Bool { tinderIndex >= tinderStatements.count }

    func swipeTinderCard(direction: SwipeDirection) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            tinderOffset = direction == .right ? 400 : -400
            tinderRotation = direction == .right ? 15 : -15
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            guard let self else { return }
            self.tinderOffset = 0
            self.tinderRotation = 0
            self.tinderIndex += 1
        }
    }

    // MARK: - Processing Animation

    func runProcessingAnimation(completion: @escaping () -> Void) {
        processingWorkItems.forEach { $0.cancel() }
        processingWorkItems.removeAll()
        processingStep = 0

        let delays: [Double] = [0.6, 1.2, 1.8]
        for (i, delay) in delays.enumerated() {
            let item = DispatchWorkItem { [weak self] in
                self?.processingStep = i + 1
            }
            processingWorkItems.append(item)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
        }

        let done = DispatchWorkItem { completion() }
        processingWorkItems.append(done)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5, execute: done)
    }

    // MARK: - Completion

    func complete(tripStore: TripStore) {
        tripStore.completeOnboarding(goal: selectedGoal, tripTypes: Array(selectedTripTypes))
    }
}

enum SwipeDirection { case left, right }
