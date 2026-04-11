import SwiftUI
struct OB1WelcomeView: View {
    @ObservedObject var vm: OnboardingViewModel
    var body: some View {
        VStack { Text("OB1 Welcome").font(.title); Button("Continue") { vm.advance() }.buttonStyle(.borderedProminent) }
    }
}
