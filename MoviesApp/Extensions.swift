//
//  Extensions.swift
//  MoviesApp
//
//  Created by Bhavin Parghi on 10/11/25.
//

import Foundation
import SwiftUI
import UIKit

// MARK: - Premium Glassmorphic Blur View
struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: effect)
        return view
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = effect
    }
}

// MARK: - Modern Typography & Style Modifiers
extension Text {
    func ghostButton() -> some View {
        self
            .foregroundStyle(.buttonText)
            .frame(width: 100, height: 50)
            .bold()
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(.buttonBorder, lineWidth: 1)
            }
    }
}

extension View {
    func netflixStyleGradient() -> some View {
        self.overlay {
            LinearGradient(
                stops: [
                    Gradient.Stop(color: .clear, location: 0.4),
                    Gradient.Stop(color: .black.opacity(0.85), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    /// Upgraded card style with larger 16pt corner radius and clean depth-shadow
    func cardStyle() -> some View {
        self
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 6)
    }
    
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
    
    /// Adds a gorgeous interactive spring-scale reaction on finger presses (legacy fallback, standardise on PressScaleButtonStyle)
    func pressScaleEffect() -> some View {
        self
    }
    
    /// Glassmorphic background modifier
    func glassBackground(cornerRadius: CGFloat = 16) -> some View {
        self.background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .background(VisualEffectView(effect: UIBlurEffect(style: .systemMaterialDark)).clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }
}

// MARK: - Skeleton Shimmer Animation
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: phase - 0.25),
                            .init(color: .white.opacity(0.15), location: phase),
                            .init(color: .clear, location: phase + 0.25)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + (phase * geometry.size.width * 2))
                }
            )
            .mask(content)
            .onAppear {
                withAnimation(Animation.linear(duration: 1.6).repeatForever(autoreverses: false)) {
                    phase = 1.0
                }
            }
    }
}

// MARK: - Premium Tap Micro-Interaction Button Style
struct PressScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .shadow(color: .black.opacity(configuration.isPressed ? 0.15 : 0.4), radius: configuration.isPressed ? 4 : 8, x: 0, y: configuration.isPressed ? 3 : 6)
            .animation(.spring(response: 0.3, dampingFraction: 0.65, blendDuration: 0), value: configuration.isPressed)
    }
}

