//
//  SplashView.swift
//  MoviesApp
//
//  Created by Antigravity on 18/05/26.
//

import SwiftUI

struct SplashView: View {
    var onFinished: () -> Void
    
    // Animation States
    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0.0
    @State private var logoBlur: CGFloat = 15
    
    @State private var rippleScale: CGFloat = 0.6
    @State private var rippleOpacity: Double = 0.6
    
    @State private var particles: [NeonParticle] = []
    @State private var animateParticles = false
    
    var body: some View {
        ZStack {
            // 1. Cinematic Ambient Gradient Backdrop
            LinearGradient(
                stops: [
                    .init(color: Color(red: 0.05, green: 0.05, blue: 0.07), location: 0),
                    .init(color: Color(red: 0.01, green: 0.01, blue: 0.02), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // 2. Slow-Drifting Neon Dust Particles
            if animateParticles {
                ZStack {
                    ForEach(particles) { particle in
                        Circle()
                            .fill(particle.color)
                            .frame(width: particle.size, height: particle.size)
                            .opacity(particle.opacity)
                            .blur(radius: particle.blur)
                            .position(
                                x: particle.x + (animateParticles ? particle.driftX : 0),
                                y: particle.y + (animateParticles ? particle.driftY : 0)
                            )
                    }
                }
            }
            
            // 3. Central Ambient Glowing Ripples
            ZStack {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.4), Color.cyan.opacity(0.2)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 140, height: 140)
                    .scaleEffect(rippleScale)
                    .opacity(rippleOpacity)
                
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.cyan.opacity(0.3), Color.purple.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: 140, height: 140)
                    .scaleEffect(rippleScale * 1.4)
                    .opacity(rippleOpacity * 0.7)
            }
            
            // 4. Stylized Cinematic Emblem & Tracking Title
            VStack(spacing: 20) {
                // TV Glowing Capsule Emblem
                ZStack {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(Color.white.opacity(0.02))
                        .frame(width: 140, height: 140)
                        .glassBackground(cornerRadius: 32)
                        .shadow(color: Color.purple.opacity(0.15), radius: 20, x: 0, y: 10)
                    
                    Image(systemName: "sparkles.tv")
                        .font(.system(size: 68, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.purple, Color.cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color.purple.opacity(0.6), radius: 15, x: 0, y: 5)
                        .shadow(color: Color.cyan.opacity(0.4), radius: 25, x: 0, y: 8)
                }
                
                // Tracked Text
                VStack(spacing: 8) {
                    Text("IPTV PLAYER")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .tracking(10)
                        .foregroundStyle(.white)
                        .shadow(color: Color.purple.opacity(0.5), radius: 12, x: 0, y: 4)
                        .padding(.leading, 10) // Balances out the letter tracking offset
                    
                    Text("NEXT-GEN OTT PLATFORM")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .tracking(4)
                        .foregroundColor(.gray.opacity(0.7))
                        .padding(.leading, 4)
                }
            }
            .scaleEffect(logoScale)
            .opacity(logoOpacity)
            .blur(radius: logoBlur)
        }
        .onAppear {
            setupInitialState()
            
            // Trigger logo entrance (cinematic blur to sharp + scale bounce)
            withAnimation(.spring(response: 1.3, dampingFraction: 0.78, blendDuration: 0)) {
                logoScale = 1.0
                logoOpacity = 1.0
                logoBlur = 0
            }
            
            // Trigger endless concentric glowing ripples
            withAnimation(.easeOut(duration: 2.2).repeatForever(autoreverses: false)) {
                rippleScale = 2.2
                rippleOpacity = 0.0
            }
            
            // Trigger drifting neon background dust particles
            withAnimation(.easeInOut(duration: 8.0).repeatForever(autoreverses: true)) {
                animateParticles = true
            }
            
            // Perform self-dismiss and transition to Main Screen after 2.6 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
                onFinished()
            }
        }
    }
    
    private func setupInitialState() {
        // Generate neon ambient particles with safe screen bounds
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        var generatedParticles: [NeonParticle] = []
        for _ in 0..<20 {
            let p = NeonParticle(
                x: CGFloat.random(in: 40...(screenWidth - 40)),
                y: CGFloat.random(in: 40...(screenHeight - 40)),
                size: CGFloat.random(in: 3...8),
                opacity: Double.random(in: 0.15...0.45),
                blur: CGFloat.random(in: 1...3),
                color: Bool.random() ? Color.purple : Color.cyan,
                driftX: CGFloat.random(in: -30...30),
                driftY: CGFloat.random(in: -30...30)
            )
            generatedParticles.append(p)
        }
        self.particles = generatedParticles
    }
}

// Particle Helper Representation
struct NeonParticle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let opacity: Double
    let blur: CGFloat
    let color: Color
    let driftX: CGFloat
    let driftY: CGFloat
}

#Preview {
    SplashView(onFinished: {})
}
