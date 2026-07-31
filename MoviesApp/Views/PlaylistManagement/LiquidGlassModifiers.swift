import SwiftUI

// MARK: - Liquid Glass Modifier
struct LiquidGlassModifier: ViewModifier {
    var cornerRadius: CGFloat
    var blurRadius: CGFloat
    var opacity: Double
    
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color(UIColor.systemBackground).opacity(colorScheme == .dark ? opacity * 0.5 : opacity))
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(colorScheme == .dark ? 0.3 : 0.8),
                                        .clear,
                                        .black.opacity(colorScheme == .dark ? 0.8 : 0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.5 : 0.1), radius: blurRadius, x: 0, y: blurRadius / 2)
    }
}

// MARK: - Press & Lift Animation Modifier
struct PressLiftModifier: ViewModifier {
    @State private var isPressed = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(reduceMotion ? .none : .interactiveSpring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.1), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.prepare()
                            generator.impactOccurred()
                            isPressed = true
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                    }
            )
    }
}

// MARK: - View Extensions
extension View {
    func liquidGlass(cornerRadius: CGFloat = 20, blurRadius: CGFloat = 15, opacity: Double = 0.6) -> some View {
        self.modifier(LiquidGlassModifier(cornerRadius: cornerRadius, blurRadius: blurRadius, opacity: opacity))
    }
    
    func pressLiftEffect() -> some View {
        self.modifier(PressLiftModifier())
    }
}
