import SwiftUI

struct LockScreenController: View {
    @Binding var isLocked: Bool
    @State private var showUnlockButton: Bool = false
    @State private var hideTask: Task<Void, Never>? = nil
    
    var body: some View {
        ZStack {
            // Invisible hit test blocker covering the whole screen
            Color.white.opacity(0.001)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring()) {
                        showUnlockButton.toggle()
                    }
                    if showUnlockButton {
                        resetTimer()
                    }
                }
            
            if showUnlockButton {
                VStack {
                    Spacer()
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .heavy)
                        generator.impactOccurred()
                        withAnimation(.spring()) {
                            isLocked = false
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.fill")
                            Text("Tap to Unlock")
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.6))
                        .glassBackground(cornerRadius: 24)
                        .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
                    }
                    .buttonStyle(PressScaleButtonStyle())
                    .padding(.bottom, 40)
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            showUnlockButton = true
            resetTimer()
        }
    }
    
    private func resetTimer() {
        hideTask?.cancel()
        hideTask = Task {
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            withAnimation(.spring()) {
                showUnlockButton = false
            }
        }
    }
}
