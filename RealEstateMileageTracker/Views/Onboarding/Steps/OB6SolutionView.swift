import SwiftUI
struct OB6SolutionView: View {
    @ObservedObject var vm: OnboardingViewModel
    var body: some View {
        VStack { Text("OB6 Solution").font(.title); Button("Continue") { vm.advance() }.buttonStyle(.borderedProminent) }
    }
}
