import SwiftUI

struct MovieActionButtons: View {
    let onPlayTapped: () -> Void
    let onTrailerTapped: () -> Void
    let hasTrailer: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                onPlayTapped()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 18))
                    Text("Play")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.white)
                .foregroundColor(.black)
                .cornerRadius(12)
            }
            .buttonStyle(PressScaleButtonStyle())
            
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                onTrailerTapped()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "film.fill")
                        .font(.system(size: 18))
                    Text("Trailer")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.white.opacity(0.15))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .buttonStyle(PressScaleButtonStyle())
            .opacity(hasTrailer ? 1.0 : 0.5)
            .disabled(!hasTrailer)
            
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .frame(width: 50, height: 50)
                    .background(Color.white.opacity(0.15))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .buttonStyle(PressScaleButtonStyle())
        }
        .padding(.horizontal, 24)
    }
}
