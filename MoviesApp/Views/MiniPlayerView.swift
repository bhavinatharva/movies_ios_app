//
//  MiniPlayerView.swift
//  MoviesApp
//
//  Created by Antigravity on 14/05/26.
//

import SwiftUI
import AVKit

struct MiniPlayerView: View {
    @ObservedObject var playerManager = GlobalPlayerManager.shared
    @State private var dragOffset: CGSize = .zero
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        if playerManager.isMinimized && playerManager.player.currentItem != nil {
            VStack {
                Spacer()
                
                HStack(spacing: 12) {
                    // Placeholder or Live Video (Using VideoPlayer disables interaction if disabled, but here we can just show title/icon to keep it lightweight, or a small player layer)
                    ZStack {
                        Color.black.opacity(0.3)
                        Image(systemName: "tv.fill")
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .frame(width: 80, height: 50)
                    .cornerRadius(6)
                    .clipped()
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(playerManager.currentTitle ?? "Live TV")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text("Now Playing")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Play / Pause Button
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        playerManager.togglePlayPause()
                    }) {
                        Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(8)
                    }
                    .buttonStyle(PressScaleButtonStyle())
                    
                    // Close Button
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        playerManager.stop()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(8)
                    }
                    .buttonStyle(PressScaleButtonStyle())
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    VisualEffectView(effect: UIBlurEffect(style: .systemThickMaterialDark))
                )
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
                .padding(.horizontal, 16)
                // Position above standard TabBar on iPhone, flush with bottom on iPad
                .padding(.bottom, horizontalSizeClass == .regular ? 20 : 60)
                
                // Drag Gesture to Dismiss
                .offset(y: dragOffset.height > 0 ? dragOffset.height : 0) // Only allow dragging downwards
                .opacity(1.0 - Double(dragOffset.height / 150.0)) // Fade out as it drags down
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.height > 0 {
                                dragOffset = value.translation
                            }
                        }
                        .onEnded { value in
                            if value.translation.height > 60 {
                                // Threshold met, stop player
                                playerManager.stop()
                            }
                            withAnimation(.spring()) {
                                dragOffset = .zero
                            }
                        }
                )
                // Tap to maximize
                .onTapGesture {
                    playerManager.maximize()
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            .zIndex(100)
        }
    }
}
