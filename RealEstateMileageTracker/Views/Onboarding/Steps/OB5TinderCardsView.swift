import SwiftUI
struct OB5TinderCardsView: View {
    @ObservedObject var vm: OnboardingViewModel
    var body: some View {
        VStack { Text("OB5 Tinder Cards").font(.title); Button("Continue") { vm.advance() }.buttonStyle(.borderedProminent) }
    }
}
