//
//  StreamingPlayerView.swift
//  MoviesApp
//
//  Created by Antigravity on 14/05/26.
//

import SwiftUI
import AVKit

struct StreamingPlayerView: View {
    let url: URL
    let title: String
    @Environment(\.dismiss) var dismiss
    
    @State private var player = AVPlayer()
    @State private var isPlaying = true
    @State private var showControls = true
    @State private var controlsTimer: Timer?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // The Video Stream Player
            VideoPlayer(player: player)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showControls.toggle()
                    }
                    if showControls {
                        resetControlsTimer()
                    }
                }
            
            // Transparent Dark Vignette overlay
            if showControls {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showControls = false
                        }
                    }
            }
            
            // UI Overlay Controls
            VStack {
                // 1. Premium Glassmorphic Top Header
                if showControls {
                    HStack(spacing: 16) {
                        Button(action: {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title3)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .pressScaleEffect()
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(title)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            Text("Live IPTV Stream")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        // Dynamic Quality Indicator
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 6, height: 6)
                            Text("1080P HLS")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .glassBackground(cornerRadius: 8)
                    }
                    .padding()
                    .background(
                        VisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
                            .ignoresSafeArea(edges: .top)
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                Spacer()
                
                // 2. Play / Pause Middle Overlay
                if showControls {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .heavy)
                        generator.impactOccurred()
                        if isPlaying {
                            player.pause()
                        } else {
                            player.play()
                        }
                        withAnimation {
                            isPlaying.toggle()
                        }
                        resetControlsTimer()
                    }) {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .frame(width: 76, height: 76)
                            .background(Color.black.opacity(0.55))
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1.5))
                            .shadow(color: .black.opacity(0.4), radius: 10)
                    }
                    .buttonStyle(.plain)
                    .pressScaleEffect()
                    .transition(.scale.combined(with: .opacity))
                }
                
                Spacer()
                
                // 3. Bottom Modern Glowing Seek Bar
                if showControls {
                    VStack(spacing: 12) {
                        // Thin glowing track
                        HStack {
                            Text("00:00")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.white.opacity(0.15))
                                        .frame(height: 3)
                                    
                                    Capsule()
                                        .fill(Color.accentColor)
                                        .frame(width: geo.size.width * 0.85, height: 3)
                                        .shadow(color: Color.accentColor.opacity(0.8), radius: 4)
                                    
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 10, height: 10)
                                        .offset(x: geo.size.width * 0.85 - 5)
                                        .shadow(radius: 2)
                                }
                            }
                            .frame(height: 10)
                            
                            Text("LIVE")
                                .font(.caption2)
                                .foregroundColor(.red)
                                .fontWeight(.black)
                        }
                        .padding(.horizontal)
                        
                        // Volume icon indicator representation
                        HStack {
                            Image(systemName: "speaker.wave.3.fill")
                                .foregroundColor(.white)
                                .font(.footnote)
                            
                            Spacer()
                            
                            Image(systemName: "tv.and.mediabox.fill")
                                .foregroundColor(.white)
                                .font(.footnote)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 16)
                    .background(
                        VisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
                            .ignoresSafeArea(edges: .bottom)
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            player = AVPlayer(url: url)
            player.play()
            resetControlsTimer()
        }
        .onDisappear {
            player.pause()
            controlsTimer?.invalidate()
        }
    }
    
    private func resetControlsTimer() {
        controlsTimer?.invalidate()
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.4)) {
                showControls = false
            }
        }
    }
}
