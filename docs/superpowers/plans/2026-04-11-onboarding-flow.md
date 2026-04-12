# LandMile Onboarding Flow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a 10-screen conversion-optimised onboarding flow for LandMile that gates the app behind a paywall for property managers.

**Architecture:** `OnboardingView` is a root container that routes to 10 step views via `OnboardingViewModel`. `ContentView` gates on `hasCompletedOnboarding` from `TripStore`. The final screen is a paywall backed by StoreKit 2 via a new `SubscriptionManager`. All onboarding state is persisted to UserDefaults via `TripStore`.

**Tech Stack:** SwiftUI, StoreKit 2, UserDefaults (TripStore), CLLocationManager (existing TripManager)

---

## File Structure

**Create:**
- `RealEstateMileageTracker/Views/Onboarding/OnboardingViewModel.swift` — all onboarding state
- `RealEstateMileageTracker/Views/Onboarding/OnboardingView.swift` — root container with progress bar + routing
- `RealEstateMileageTracker/Views/Onboarding/Steps/OB1WelcomeView.swift`
- `RealEstateMileageTracker/Views/Onboarding/Steps/OB2GoalView.swift`
- `RealEstateMileageTracker/Views/Onboarding/Steps/OB3PainPointsView.swift`
- `RealEstateMileageTracker/Views/Onboarding/Steps/OB4SocialProofView.swift`
- `RealEstateMileageTracker/Views/Onboarding/Steps/OB5TinderCardsView.swift`
- `RealEstateMileageTracker/Views/Onboarding/Steps/OB6SolutionView.swift`
- `RealEstateMileageTracker/Views/Onboarding/Steps/OB7PreferenceView.swift`
- `RealEstateMileageTracker/Views/Onboarding/Steps/OB8LocationPrimingView.swift`
- `RealEstateMileageTracker/Views/Onboarding/Steps/OB9ProcessingView.swift`
- `RealEstateMileageTracker/Views/Onboarding/Steps/OB10PaywallView.swift`
- `RealEstateMileageTracker/Services/SubscriptionManager.swift` — StoreKit 2 wrapper

**Modify:**
- `RealEstateMileageTracker/Stores/TripStore.swift` — add `hasCompletedOnboarding`, `onboardingGoal`, `onboardingTripTypes`, `completeOnboarding()`, `resetOnboarding()`
- `RealEstateMileageTracker/ContentView.swift` — gate on `hasCompletedOnboarding`
- `RealEstateMileageTracker/Views/SettingsView.swift` — add `#if DEBUG` reset onboarding button

---

## Task 1: Extend TripStore with onboarding state

**Files:**
- Modify: `RealEstateMileageTracker/Stores/TripStore.swift`

- [ ] **Step 1: Add onboarding keys and published properties**

Add to the keys section and `@Published` properties in `TripStore`:

```swift
private let hasCompletedOnboardingKey = "hasCompletedOnboarding"
private let onboardingGoalKey = "onboardingGoal"
private let onboardingTripTypesKey = "onboardingTripTypes"

@Published var hasCompletedOnboarding: Bool = false
@Published var onboardingGoal: String = ""
@Published var onboardingTripTypes: [String] = []
```

- [ ] **Step 2: Load onboarding state in `init()` after `loadLocationNicknames()`**

```swift
hasCompletedOnboarding = UserDefaults.standard.bool(forKey: hasCompletedOnboardingKey)
onboardingGoal = UserDefaults.standard.string(forKey: onboardingGoalKey) ?? ""
if let data = UserDefaults.standard.data(forKey: onboardingTripTypesKey),
   let types = try? JSONDecoder().decode([String].self, from: data) {
    onboardingTripTypes = types
}
```

- [ ] **Step 3: Add `completeOnboarding()` and `resetOnboarding()` methods**

Add after the `// MARK: - Debug` section:

```swift
// MARK: - Onboarding

func completeOnboarding(goal: String, tripTypes: [String]) {
    onboardingGoal = goal
    onboardingTripTypes = tripTypes
    hasCompletedOnboarding = true
    UserDefaults.standard.set(true, forKey: hasCompletedOnboardingKey)
    UserDefaults.standard.set(goal, forKey: onboardingGoalKey)
    if let data = try? JSONEncoder().encode(tripTypes) {
        UserDefaults.standard.set(data, forKey: onboardingTripTypesKey)
    }
}

func resetOnboarding() {
    hasCompletedOnboarding = false
    onboardingGoal = ""
    onboardingTripTypes = []
    UserDefaults.standard.removeObject(forKey: hasCompletedOnboardingKey)
    UserDefaults.standard.removeObject(forKey: onboardingGoalKey)
    UserDefaults.standard.removeObject(forKey: onboardingTripTypesKey)
}
```

- [ ] **Step 4: Build and verify**

```bash
cd /Users/I818292/Documents/Funs/RealEstateMileageTracker
xcodebuild -project RealEstateMileageTracker.xcodeproj -scheme RealEstateMileageTracker -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' build 2>&1 | tail -5
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add RealEstateMileageTracker/Stores/TripStore.swift
git commit -m "feat: add onboarding state to TripStore"
```

---

## Task 2: Create SubscriptionManager (StoreKit 2)

**Files:**
- Create: `RealEstateMileageTracker/Services/SubscriptionManager.swift`

Product IDs to use:
- `com.landmile.monthly` — $4.99/month
- `com.landmile.annual` — $39.99/year (with 7-day free trial)

- [ ] **Step 1: Create SubscriptionManager.swift**

```swift
//
//  SubscriptionManager.swift
//  RealEstateMileageTracker
//

import Foundation
import StoreKit

@MainActor
final class SubscriptionManager: ObservableObject {

    static let shared = SubscriptionManager()

    enum ProductID: String, CaseIterable {
        case monthly = "com.landmile.monthly"
        case annual  = "com.landmile.annual"

        var displayName: String {
            switch self {
            case .monthly: return "Monthly"
            case .annual:  return "Annual"
            }
        }
    }

    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var isLoading = false

    var isPro: Bool { !purchasedProductIDs.isEmpty }

    private var updateListenerTask: Task<Void, Never>?

    private init() {
        updateListenerTask = listenForTransactions()
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }

    deinit { updateListenerTask?.cancel() }

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let ids = ProductID.allCases.map { $0.rawValue }
            let loaded = try await Product.products(for: ids)
            self.products = loaded.sorted { p1, p2 in
                let order = [ProductID.monthly.rawValue, ProductID.annual.rawValue]
                return (order.firstIndex(of: p1.id) ?? 0) < (order.firstIndex(of: p2.id) ?? 1)
            }
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updateSubscriptionStatus()
            await transaction.finish()
            return true
        case .userCancelled: return false
        case .pending:       return false
        @unknown default:    return false
        }
    }

    func restorePurchases() async {
        try? await AppStore.sync()
        await updateSubscriptionStatus()
    }

    func updateSubscriptionStatus() async {
        var active: Set<String> = []
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result),
               transaction.revocationDate == nil {
                active.insert(transaction.productID)
            }
        }
        purchasedProductIDs = active
    }

    func product(for id: ProductID) -> Product? {
        products.first { $0.id == id.rawValue }
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { @MainActor in
            for await result in Transaction.updates {
                if let transaction = try? await self.checkVerified(result) {
                    await self.updateSubscriptionStatus()
                    await transaction.finish()
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified: throw SubscriptionError.failedVerification
        case .verified(let safe): return safe
        }
    }
}

enum SubscriptionError: LocalizedError {
    case failedVerification
    var errorDescription: String? { "Purchase verification failed" }
}
```

- [ ] **Step 2: Build and verify**

```bash
xcodebuild -project RealEstateMileageTracker.xcodeproj -scheme RealEstateMileageTracker -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' build 2>&1 | tail -5
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add RealEstateMileageTracker/Services/SubscriptionManager.swift
git commit -m "feat: add SubscriptionManager with StoreKit 2"
```

---

## Task 3: Create OnboardingViewModel

**Files:**
- Create: `RealEstateMileageTracker/Views/Onboarding/OnboardingViewModel.swift`

- [ ] **Step 1: Create OnboardingViewModel.swift**

```swift
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
```

- [ ] **Step 2: Build and verify**

```bash
xcodebuild -project RealEstateMileageTracker.xcodeproj -scheme RealEstateMileageTracker -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' build 2>&1 | tail -5
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add RealEstateMileageTracker/Views/Onboarding/OnboardingViewModel.swift
git commit -m "feat: add OnboardingViewModel for 10-step flow"
```

---

## Task 4: Create OnboardingView root container + all stub step views

**Files:**
- Create: `RealEstateMileageTracker/Views/Onboarding/OnboardingView.swift`
- Create: All 10 stub files in `RealEstateMileageTracker/Views/Onboarding/Steps/`

- [ ] **Step 1: Create OnboardingView.swift**

```swift
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
```

- [ ] **Step 2: Create all 10 stub step files**

Create each file with a minimal stub that compiles. Replace contents of each:

**OB1WelcomeView.swift:**
```swift
import SwiftUI
struct OB1WelcomeView: View {
    @ObservedObject var vm: OnboardingViewModel
    var body: some View {
        VStack { Text("OB1 Welcome").font(.title); Button("Continue") { vm.advance() }.buttonStyle(.borderedProminent) }
    }
}
```

**OB2GoalView.swift:**
```swift
import SwiftUI
struct OB2GoalView: View {
    @ObservedObject var vm: OnboardingViewModel
    var body: some View {
        VStack { Text("OB2 Goal").font(.title); Button("Continue") { vm.advance() }.buttonStyle(.borderedProminent) }
    }
}
```

**OB3PainPointsView.swift:**
```swift
import SwiftUI
struct OB3PainPointsView: View {
    @ObservedObject var vm: OnboardingViewModel
    var body: some View {
        VStack { Text("OB3 Pain Points").font(.title); Button("Continue") { vm.advance() }.buttonStyle(.borderedProminent) }
    }
}
```

**OB4SocialProofView.swift:**
```swift
import SwiftUI
struct OB4SocialProofView: View {
    @ObservedObject var vm: OnboardingViewModel
    var body: some View {
        VStack { Text("OB4 Social Proof").font(.title); Button("Continue") { vm.advance() }.buttonStyle(.borderedProminent) }
    }
}
```

**OB5TinderCardsView.swift:**
```swift
import SwiftUI
struct OB5TinderCardsView: View {
    @ObservedObject var vm: OnboardingViewModel
    var body: some View {
        VStack { Text("OB5 Tinder Cards").font(.title); Button("Continue") { vm.advance() }.buttonStyle(.borderedProminent) }
    }
}
```

**OB6SolutionView.swift:**
```swift
import SwiftUI
struct OB6SolutionView: View {
    @ObservedObject var vm: OnboardingViewModel
    var body: some View {
        VStack { Text("OB6 Solution").font(.title); Button("Continue") { vm.advance() }.buttonStyle(.borderedProminent) }
    }
}
```

**OB7PreferenceView.swift:**
```swift
import SwiftUI
struct OB7PreferenceView: View {
    @ObservedObject var vm: OnboardingViewModel
    var body: some View {
        VStack { Text("OB7 Preference").font(.title); Button("Continue") { vm.advance() }.buttonStyle(.borderedProminent) }
    }
}
```

**OB8LocationPrimingView.swift:**
```swift
import SwiftUI
struct OB8LocationPrimingView: View {
    @ObservedObject var vm: OnboardingViewModel
    var body: some View {
        VStack { Text("OB8 Location").font(.title); Button("Continue") { vm.advance() }.buttonStyle(.borderedProminent) }
    }
}
```

**OB9ProcessingView.swift:**
```swift
import SwiftUI
struct OB9ProcessingView: View {
    @ObservedObject var vm: OnboardingViewModel
    var body: some View {
        VStack { Text("OB9 Processing").font(.title) }
            .onAppear { vm.runProcessingAnimation { vm.advance() } }
    }
}
```

**OB10PaywallView.swift:**
```swift
import SwiftUI
struct OB10PaywallView: View {
    @ObservedObject var vm: OnboardingViewModel
    var onComplete: () -> Void
    var body: some View {
        VStack { Text("OB10 Paywall").font(.title); Button("Maybe later") { onComplete() }.buttonStyle(.borderedProminent) }
    }
}
```

- [ ] **Step 3: Gate ContentView on onboarding**

Replace `ContentView.swift` with:

```swift
//
//  ContentView.swift
//  RealEstateMileageTracker
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var tripStore: TripStore

    var body: some View {
        if tripStore.hasCompletedOnboarding {
            MainTabView()
        } else {
            OnboardingView {
                // onComplete handled inside OnboardingView
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(TripStore())
        .environmentObject(TripManager())
}
```

- [ ] **Step 4: Inject tripStore into OnboardingView in RealEstateMileageTrackerApp.swift**

`OnboardingView` uses `.environmentObject` to get `TripStore`. Verify `MainTabView` already injects `TripStore` and `TripManager` as `@StateObject` — if it does, `ContentView` inherits them. Check `MainTabView.swift` and ensure both are injected from the app root if not already.

Read `MainTabView.swift` to confirm — if `@StateObject var tripStore = TripStore()` is in `MainTabView`, move it to `RealEstateMileageTrackerApp` so it's available to `ContentView` (and thus `OnboardingView`) before `MainTabView` is shown:

```swift
// RealEstateMileageTrackerApp.swift
@main
struct RealEstateMileageTrackerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var tripStore = TripStore()
    @StateObject private var tripManager = TripManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(tripStore)
                .environmentObject(tripManager)
        }
    }
}
```

And update `MainTabView` to use `@EnvironmentObject` instead of `@StateObject` for both.

- [ ] **Step 5: Build and verify**

```bash
xcodebuild -project RealEstateMileageTracker.xcodeproj -scheme RealEstateMileageTracker -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' build 2>&1 | tail -5
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 6: Commit**

```bash
git add RealEstateMileageTracker/Views/Onboarding/
git add RealEstateMileageTracker/ContentView.swift
git add RealEstateMileageTracker/RealEstateMileageTrackerApp.swift
git commit -m "feat: add OnboardingView scaffold, stub steps, gate ContentView"
```

---

## Task 5: Implement OB1 Welcome + OB2 Goal + OB3 Pain Points

**Files:**
- Modify: `RealEstateMileageTracker/Views/Onboarding/Steps/OB1WelcomeView.swift`
- Modify: `RealEstateMileageTracker/Views/Onboarding/Steps/OB2GoalView.swift`
- Modify: `RealEstateMileageTracker/Views/Onboarding/Steps/OB3PainPointsView.swift`

- [ ] **Step 1: Implement OB1WelcomeView**

```swift
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

            // Hero mock — trip summary card
            tripSummaryMock
                .padding(.bottom, 40)

            Text("Every mile you drive\nis worth $0.67.")
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
                Text("Start Saving \u{2192}")
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
```

- [ ] **Step 2: Implement OB2GoalView**

```swift
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
                Text("That's me \u{2192}")
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
```

- [ ] **Step 3: Implement OB3PainPointsView**

```swift
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
                Text("Continue \u{2192}")
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
```

- [ ] **Step 4: Build and verify**

```bash
xcodebuild -project RealEstateMileageTracker.xcodeproj -scheme RealEstateMileageTracker -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' build 2>&1 | tail -5
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add RealEstateMileageTracker/Views/Onboarding/Steps/OB1WelcomeView.swift
git add RealEstateMileageTracker/Views/Onboarding/Steps/OB2GoalView.swift
git add RealEstateMileageTracker/Views/Onboarding/Steps/OB3PainPointsView.swift
git commit -m "feat: implement onboarding screens 1-3 (welcome, goal, pain points)"
```

---

## Task 6: Implement OB4 Social Proof + OB5 Tinder Cards

**Files:**
- Modify: `RealEstateMileageTracker/Views/Onboarding/Steps/OB4SocialProofView.swift`
- Modify: `RealEstateMileageTracker/Views/Onboarding/Steps/OB5TinderCardsView.swift`

- [ ] **Step 1: Implement OB4SocialProofView**

```swift
//
//  OB4SocialProofView.swift
//  RealEstateMileageTracker
//

import SwiftUI

struct OB4SocialProofView: View {
    @ObservedObject var vm: OnboardingViewModel

    private let testimonials: [(name: String, tag: String, review: String)] = [
        ("Marcus T.", "Portfolio Manager", "\"I used to guess at tax time. Now I just hand my accountant the CSV. Saved me hours of stress.\""),
        ("Sandra K.", "Property Manager", "\"Paid for itself in the first week. I had no idea how many miles I was logging each month.\""),
        ("David L.", "Landlord", "\"Finally an app that works in the background. I don't have to remember to open it.\"")
    ]

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("Property managers save\nan average of $3,200/year")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                Text("By tracking every business mile.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)

            ScrollView {
                VStack(spacing: 16) {
                    ForEach(testimonials, id: \.name) { t in
                        TestimonialCard(name: t.name, tag: t.tag, review: t.review)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
            }

            Button(action: { vm.advance() }) {
                Text("Sounds like me \u{2192}")
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

private struct TestimonialCard: View {
    let name: String
    let tag: String
    let review: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill").foregroundColor(.yellow).font(.caption)
                }
            }
            Text(review)
                .font(.subheadline)
                .italic()
            HStack {
                Text(name).font(.caption.bold())
                Text("\u{2022}").foregroundColor(.secondary).font(.caption)
                Text(tag).font(.caption).foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}
```

- [ ] **Step 2: Implement OB5TinderCardsView**

```swift
//
//  OB5TinderCardsView.swift
//  RealEstateMileageTracker
//

import SwiftUI

struct OB5TinderCardsView: View {
    @ObservedObject var vm: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("Which of these\ndo you relate to?")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                Text("Swipe right to agree, left to skip.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)

            Spacer()

            if vm.isTinderComplete {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    Text("Got it. LandMile\nwas built for this.")
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                }
                .transition(.scale.combined(with: .opacity))
            } else {
                ZStack {
                    // Background cards
                    ForEach((1...min(2, vm.tinderStatements.count - vm.tinderIndex - 1)).reversed(), id: \.self) { offset in
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemGray6))
                            .frame(width: 300 - CGFloat(offset * 10), height: 180)
                            .offset(y: CGFloat(offset * 8))
                    }

                    // Front card
                    TinderCard(text: vm.tinderStatements[vm.tinderIndex])
                        .offset(x: vm.tinderOffset)
                        .rotationEffect(.degrees(vm.tinderRotation))
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    vm.tinderOffset = value.translation.width
                                    vm.tinderRotation = Double(value.translation.width / 20)
                                }
                                .onEnded { value in
                                    if abs(value.translation.width) > 80 {
                                        vm.swipeTinderCard(direction: value.translation.width > 0 ? .right : .left)
                                    } else {
                                        withAnimation(.spring()) {
                                            vm.tinderOffset = 0
                                            vm.tinderRotation = 0
                                        }
                                    }
                                }
                        )
                }
                .frame(height: 220)

                HStack(spacing: 40) {
                    Button { vm.swipeTinderCard(direction: .left) } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.red.opacity(0.7))
                    }
                    Button { vm.swipeTinderCard(direction: .right) } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.green.opacity(0.8))
                    }
                }
                .padding(.top, 24)

                Text("\(vm.tinderIndex + 1) of \(vm.tinderStatements.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }

            Spacer()

            if vm.isTinderComplete {
                Button(action: { vm.advance() }) {
                    Text("Continue \u{2192}")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: vm.isTinderComplete)
    }
}

private struct TinderCard: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.title3)
            .italic()
            .multilineTextAlignment(.center)
            .padding(24)
            .frame(width: 300, height: 180)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
    }
}
```

- [ ] **Step 3: Build and verify**

```bash
xcodebuild -project RealEstateMileageTracker.xcodeproj -scheme RealEstateMileageTracker -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' build 2>&1 | tail -5
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add RealEstateMileageTracker/Views/Onboarding/Steps/OB4SocialProofView.swift
git add RealEstateMileageTracker/Views/Onboarding/Steps/OB5TinderCardsView.swift
git commit -m "feat: implement onboarding screens 4-5 (social proof, tinder cards)"
```

---

## Task 7: Implement OB6 Solution + OB7 Preference

**Files:**
- Modify: `RealEstateMileageTracker/Views/Onboarding/Steps/OB6SolutionView.swift`
- Modify: `RealEstateMileageTracker/Views/Onboarding/Steps/OB7PreferenceView.swift`

- [ ] **Step 1: Implement OB6SolutionView**

```swift
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
                Text("Sounds good \u{2192}")
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
```

- [ ] **Step 2: Implement OB7PreferenceView**

```swift
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
                Text("Continue \u{2192}")
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
```

- [ ] **Step 3: Build and verify**

```bash
xcodebuild -project RealEstateMileageTracker.xcodeproj -scheme RealEstateMileageTracker -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' build 2>&1 | tail -5
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add RealEstateMileageTracker/Views/Onboarding/Steps/OB6SolutionView.swift
git add RealEstateMileageTracker/Views/Onboarding/Steps/OB7PreferenceView.swift
git commit -m "feat: implement onboarding screens 6-7 (solution, preference)"
```

---

## Task 8: Implement OB8 Location Priming + OB9 Processing

**Files:**
- Modify: `RealEstateMileageTracker/Views/Onboarding/Steps/OB8LocationPrimingView.swift`
- Modify: `RealEstateMileageTracker/Views/Onboarding/Steps/OB9ProcessingView.swift`

- [ ] **Step 1: Implement OB8LocationPrimingView**

```swift
//
//  OB8LocationPrimingView.swift
//  RealEstateMileageTracker
//

import SwiftUI
import CoreLocation

struct OB8LocationPrimingView: View {
    @ObservedObject var vm: OnboardingViewModel
    @EnvironmentObject var tripManager: TripManager

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue.gradient)

                VStack(spacing: 8) {
                    Text("Track every mile\nautomatically.")
                        .font(.title.bold())
                        .multilineTextAlignment(.center)
                    Text("LandMile needs location access to detect\ntrips while you drive.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: 14) {
                    BenefitRow(icon: "play.circle.fill", text: "Trips start the moment you drive away")
                    BenefitRow(icon: "hand.raised.slash.fill", text: "No tapping, no manual logging")
                    BenefitRow(icon: "lock.shield.fill", text: "Your location is never shared with anyone")
                }
                .padding(.horizontal, 16)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .padding(.horizontal, 24)
            }

            Spacer()

            VStack(spacing: 12) {
                Button(action: requestLocation) {
                    Text("Enable Location \u{2192}")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }

                Button(action: { vm.advance() }) {
                    Text("Not now")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }

    private func requestLocation() {
        if tripManager.locationPermissionStatus == .notDetermined {
            tripManager.requestLocationPermission()
        } else {
            // Already determined — open Settings
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            vm.advance()
        }
    }
}

private struct BenefitRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            Text(text).font(.subheadline)
            Spacer()
        }
    }
}
```

**Note:** `TripManager` must expose a `requestLocationPermission()` method. Check `TripManager.swift` — if it doesn't exist, add it:
```swift
func requestLocationPermission() {
    locationManager.requestAlwaysAuthorization()
}
```

- [ ] **Step 2: Implement OB9ProcessingView**

```swift
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
        "Setting IRS rate ($0.67/mile)",
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
```

- [ ] **Step 3: Build and verify**

```bash
xcodebuild -project RealEstateMileageTracker.xcodeproj -scheme RealEstateMileageTracker -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' build 2>&1 | tail -5
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add RealEstateMileageTracker/Views/Onboarding/Steps/OB8LocationPrimingView.swift
git add RealEstateMileageTracker/Views/Onboarding/Steps/OB9ProcessingView.swift
git commit -m "feat: implement onboarding screens 8-9 (location priming, processing)"
```

---

## Task 9: Implement OB10 Paywall

**Files:**
- Modify: `RealEstateMileageTracker/Views/Onboarding/Steps/OB10PaywallView.swift`

- [ ] **Step 1: Implement OB10PaywallView**

```swift
//
//  OB10PaywallView.swift
//  RealEstateMileageTracker
//

import SwiftUI
import StoreKit

struct OB10PaywallView: View {
    @ObservedObject var vm: OnboardingViewModel
    var onComplete: () -> Void

    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
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
                }
                .padding(.horizontal, 24)

                // Featured review
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
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .padding(.horizontal, 24)

                // Pro features
                VStack(spacing: 14) {
                    ProFeatureRow(icon: "car.fill",              text: "Unlimited automatic trip tracking")
                    ProFeatureRow(icon: "doc.text.fill",         text: "IRS-compliant CSV export")
                    ProFeatureRow(icon: "tag.fill",              text: "Vehicle & purpose management")
                    ProFeatureRow(icon: "chart.bar.fill",        text: "Full trip history & reports")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .padding(.horizontal, 24)

                // Pricing plans
                if subscriptionManager.products.isEmpty {
                    ProgressView("Loading plans...")
                        .padding()
                } else {
                    VStack(spacing: 12) {
                        ForEach(subscriptionManager.products, id: \.id) { product in
                            PricingCard(
                                product: product,
                                isSelected: selectedProduct?.id == product.id,
                                badge: product.id.contains("annual") ? "Best Value" : nil
                            ) {
                                selectedProduct = product
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }

                // CTA
                VStack(spacing: 12) {
                    Button(action: purchase) {
                        Group {
                            if isPurchasing {
                                ProgressView().tint(.white)
                            } else {
                                Text(ctaText).font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedProduct != nil ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    }
                    .disabled(selectedProduct == nil || isPurchasing)
                    .padding(.horizontal, 24)

                    if let disclaimer = trialDisclaimer {
                        Text(disclaimer)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    Button("Maybe later") { onComplete() }
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Button("Restore Purchases") {
                        Task { await subscriptionManager.restorePurchases() }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)

                    HStack(spacing: 16) {
                        Link("Terms of Use", destination: URL(string: "https://imentos.github.io/LandMile/terms-of-use")!)
                        Link("Privacy Policy", destination: URL(string: "https://imentos.github.io/LandMile/privacy-policy")!)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            Task {
                if subscriptionManager.products.isEmpty {
                    await subscriptionManager.loadProducts()
                }
                selectedProduct = subscriptionManager.products.first {
                    $0.id == SubscriptionManager.ProductID.annual.rawValue
                } ?? subscriptionManager.products.first
            }
        }
        .alert("Purchase Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private var ctaText: String {
        guard let p = selectedProduct else { return "Select a Plan" }
        if p.id == SubscriptionManager.ProductID.annual.rawValue {
            return "Try Free for 7 Days, then \(p.displayPrice)/year"
        }
        return "Subscribe for \(p.displayPrice)/month"
    }

    private var trialDisclaimer: String? {
        guard let p = selectedProduct,
              p.id == SubscriptionManager.ProductID.annual.rawValue else { return nil }
        return "7-day free trial, then \(p.displayPrice)/year. Cancel anytime in Apple ID settings before trial ends to avoid charges."
    }

    private func purchase() {
        guard let product = selectedProduct else { return }
        isPurchasing = true
        Task {
            do {
                let success = try await subscriptionManager.purchase(product)
                isPurchasing = false
                if success { onComplete() }
            } catch {
                isPurchasing = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

private struct ProFeatureRow: View {
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

private struct PricingCard: View {
    let product: Product
    let isSelected: Bool
    let badge: String?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(product.displayName).font(.headline)
                        if let badge {
                            Text(badge)
                                .font(.caption.bold())
                                .foregroundColor(.blue)
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Color.blue.opacity(0.15))
                                .cornerRadius(6)
                        }
                    }
                    Text(product.id.contains("annual") ? "Billed annually" : "Billed monthly")
                        .font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Text(product.displayPrice).font(.title3.bold())
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? Color.blue : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
                    .background(RoundedRectangle(cornerRadius: 12).fill(isSelected ? Color.blue.opacity(0.08) : Color(.systemBackground)))
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}
```

- [ ] **Step 2: Build and verify**

```bash
xcodebuild -project RealEstateMileageTracker.xcodeproj -scheme RealEstateMileageTracker -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' build 2>&1 | tail -5
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add RealEstateMileageTracker/Views/Onboarding/Steps/OB10PaywallView.swift
git commit -m "feat: implement onboarding screen 10 — paywall"
```

---

## Task 10: Add debug reset + final integration test

**Files:**
- Modify: `RealEstateMileageTracker/Views/SettingsView.swift`

- [ ] **Step 1: Add debug reset button to SettingsView**

Add at the bottom of the `Form`, after the existing debug section:

```swift
#if DEBUG
Section("Developer") {
    Button("Reset Onboarding (Debug)") {
        tripStore.resetOnboarding()
    }
    .foregroundColor(.red)
}
#endif
```

- [ ] **Step 2: Build final**

```bash
xcodebuild -project RealEstateMileageTracker.xcodeproj -scheme RealEstateMileageTracker -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' build 2>&1 | tail -5
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Manual test checklist**

Run on simulator. Verify:
- [ ] Fresh launch shows OB1 Welcome, not main tabs
- [ ] Progress bar advances each screen
- [ ] Goal selection enables "That's me" button
- [ ] Pain points multi-select works
- [ ] Tinder swipe cards auto-advance after all 4 cards
- [ ] Location priming "Enable" triggers CLLocationManager dialog
- [ ] Processing animation auto-advances after ~2.5s
- [ ] "Maybe later" on paywall shows main tabs
- [ ] Settings → Developer → Reset Onboarding restores fresh state
- [ ] After reset, OB1 appears again on next launch

- [ ] **Step 4: Commit**

```bash
git add RealEstateMileageTracker/Views/SettingsView.swift
git commit -m "feat: add debug reset onboarding button; complete onboarding integration"
```

---

## Manual Step (user action required after all tasks)

Add the new Onboarding folder to the Xcode target:

1. Open `RealEstateMileageTracker.xcodeproj` in Xcode
2. Right-click the `Views` group → **Add Files to RealEstateMileageTracker...**
3. Select the `Views/Onboarding/` folder
4. Ensure **Add to targets: RealEstateMileageTracker** is checked
5. Click **Add**
6. **Cmd+B** to build, **Cmd+R** to run and verify
