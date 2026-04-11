//
//  OB5TinderCardsView.swift
//  RealEstateMileageTracker
//

import SwiftUI

struct OB5TinderCardsView: View {
    @ObservedObject var vm: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("Which of these\ndo you relate to?")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                Text("Swipe right to agree, left to skip.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)

            Spacer()

            if vm.isTinderComplete {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    Text("Got it. LandMile\nwas built for this.")
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                }
                .transition(.scale.combined(with: .opacity))
            } else {
                ZStack {
                    ForEach((1...min(2, max(1, vm.tinderStatements.count - vm.tinderIndex - 1))).reversed(), id: \.self) { offset in
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemGray6))
                            .frame(width: 300 - CGFloat(offset * 10), height: 180)
                            .offset(y: CGFloat(offset * 8))
                    }

                    TinderCard(text: vm.tinderStatements[vm.tinderIndex])
                        .offset(x: vm.tinderOffset)
                        .rotationEffect(.degrees(vm.tinderRotation))
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    vm.tinderOffset = value.translation.width
                                    vm.tinderRotation = Double(value.translation.width / 20)
                                }
                                .onEnded { value in
                                    if abs(value.translation.width) > 80 {
                                        vm.swipeTinderCard(direction: value.translation.width > 0 ? .right : .left)
                                    } else {
                                        withAnimation(.spring()) {
                                            vm.tinderOffset = 0
                                            vm.tinderRotation = 0
                                        }
                                    }
                                }
                        )
                }
                .frame(height: 220)

                HStack(spacing: 40) {
                    Button { vm.swipeTinderCard(direction: .left) } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.red.opacity(0.7))
                    }
                    Button { vm.swipeTinderCard(direction: .right) } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.green.opacity(0.8))
                    }
                }
                .padding(.top, 24)

                Text("\(vm.tinderIndex + 1) of \(vm.tinderStatements.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }

            Spacer()

            if vm.isTinderComplete {
                Button(action: { vm.advance() }) {
                    Text("Continue →")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: vm.isTinderComplete)
    }
}

private struct TinderCard: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.title3)
            .italic()
            .multilineTextAlignment(.center)
            .padding(24)
            .frame(width: 300, height: 180)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
    }
}
