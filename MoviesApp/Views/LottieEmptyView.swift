//
//  LottieEmptyView.swift
//

import SwiftUI
import Lottie

/// A reusable empty-state view that plays the bundled Lottie animation
/// with a title and optional subtitle below it.
struct LottieEmptyView: View {
    var title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(spacing: 16) {
            LottieView(animation: .named("empty_animation"))
                .playing(loopMode: .loop)
                .frame(width: 220, height: 220)

            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    LottieEmptyView(
        title: "Nothing Here Yet",
        subtitle: "Add a playlist to get started."
    )
    .preferredColorScheme(.dark)
}
