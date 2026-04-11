import SwiftUI
struct OB4SocialProofView: View {
    @ObservedObject var vm: OnboardingViewModel
    var body: some View {
        VStack { Text("OB4 Social Proof").font(.title); Button("Continue") { vm.advance() }.buttonStyle(.borderedProminent) }
    }
}
