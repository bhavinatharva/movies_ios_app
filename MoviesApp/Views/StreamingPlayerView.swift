//
//  StreamingPlayerView.swift
//  MoviesApp
//
//  Created by Antigravity on 14/05/26.
//

import SwiftUI
import AVKit
import AVFoundation

struct StreamingPlayerView: View {
    let url: URL
    let title: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()
            
            PremiumPlayerRepresentable(url: url) {
                dismiss()
            }
            .ignoresSafeArea()
            
            // Custom floating close button on top-left of player view
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                dismiss()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                    Text("Close")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .glassBackground(cornerRadius: 18)
                .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 3)
            }
            .buttonStyle(PressScaleButtonStyle())
            .padding(.leading, 16)
            .padding(.top, 16)
        }
        .navigationBarHidden(true)
    }
}

struct PremiumPlayerRepresentable: UIViewControllerRepresentable {
    let url: URL
    let onDismiss: () -> Void
    
    class Coordinator: NSObject, AVPlayerViewControllerDelegate {
        var parent: PremiumPlayerRepresentable
        
        init(_ parent: PremiumPlayerRepresentable) {
            self.parent = parent
        }
        
        func playerViewController(_ playerViewController: AVPlayerViewController, willEndFullScreenPresentationWithAnimationCoordinator coordinator: any UIViewControllerTransitionCoordinator) {
            coordinator.animate(alongsideTransition: nil) { _ in
                self.parent.onDismiss()
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        // Setup AVAudioSession for native Picture-in-Picture support
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set AVAudioSession category for PiP support: \(error)")
        }
        
        let controller = AVPlayerViewController()
        let player = AVPlayer(url: url)
        controller.player = player
        controller.delegate = context.coordinator
        controller.allowsPictureInPicturePlayback = true
        controller.canStartPictureInPictureAutomaticallyFromInline = true
        controller.showsPlaybackControls = true
        
        player.play()
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // No-op
    }
}
