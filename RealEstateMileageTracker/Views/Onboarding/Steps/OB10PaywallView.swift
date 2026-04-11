import SwiftUI
struct OB10PaywallView: View {
    @ObservedObject var vm: OnboardingViewModel
    var onComplete: () -> Void
    var body: some View {
        VStack { Text("OB10 Paywall").font(.title); Button("Maybe later") { onComplete() }.buttonStyle(.borderedProminent) }
    }
}
