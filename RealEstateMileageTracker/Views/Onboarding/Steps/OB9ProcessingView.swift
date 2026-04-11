import SwiftUI
struct OB9ProcessingView: View {
    @ObservedObject var vm: OnboardingViewModel
    var body: some View {
        VStack { Text("OB9 Processing").font(.title) }
            .onAppear { vm.runProcessingAnimation { vm.advance() } }
    }
}
