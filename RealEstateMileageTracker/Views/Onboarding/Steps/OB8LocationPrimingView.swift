import SwiftUI
struct OB8LocationPrimingView: View {
    @ObservedObject var vm: OnboardingViewModel
    var body: some View {
        VStack { Text("OB8 Location").font(.title); Button("Continue") { vm.advance() }.buttonStyle(.borderedProminent) }
    }
}
