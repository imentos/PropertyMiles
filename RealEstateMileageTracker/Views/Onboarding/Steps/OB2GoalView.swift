import SwiftUI
struct OB2GoalView: View {
    @ObservedObject var vm: OnboardingViewModel
    var body: some View {
        VStack { Text("OB2 Goal").font(.title); Button("Continue") { vm.advance() }.buttonStyle(.borderedProminent) }
    }
}
