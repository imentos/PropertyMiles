import SwiftUI
struct OB3PainPointsView: View {
    @ObservedObject var vm: OnboardingViewModel
    var body: some View {
        VStack { Text("OB3 Pain Points").font(.title); Button("Continue") { vm.advance() }.buttonStyle(.borderedProminent) }
    }
}
