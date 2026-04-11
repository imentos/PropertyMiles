import SwiftUI
struct OB7PreferenceView: View {
    @ObservedObject var vm: OnboardingViewModel
    var body: some View {
        VStack { Text("OB7 Preference").font(.title); Button("Continue") { vm.advance() }.buttonStyle(.borderedProminent) }
    }
}
