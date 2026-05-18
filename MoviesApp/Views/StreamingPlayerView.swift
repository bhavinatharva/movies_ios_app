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
    var streamId: String? = nil
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()
            
            PremiumPlayerRepresentable(url: url, streamId: streamId) {
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
    var streamId: String? = nil
    let onDismiss: () -> Void
    
    class Coordinator: NSObject, AVPlayerViewControllerDelegate {
        var parent: PremiumPlayerRepresentable
        var timeObserver: Any?
        weak var player: AVPlayer?
        
        init(_ parent: PremiumPlayerRepresentable) {
            self.parent = parent
        }
        
        deinit {
            if let timeObserver = timeObserver, let player = player {
                player.removeTimeObserver(timeObserver)
            }
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
        
        // Progress auto-resume seek
        if let targetId = streamId {
            let progress = UserDataManager.shared.getProgress(id: targetId)
            if progress > 0 {
                let time = CMTime(seconds: progress, preferredTimescale: 1)
                player.seek(to: time)
            }
            
            // Progress auto-saving observer
            let timeScale = CMTimeScale(NSEC_PER_SEC)
            let observer = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 2.0, preferredTimescale: timeScale), queue: .main) { [weak player] time in
                guard let player = player else { return }
                let seconds = time.seconds
                UserDataManager.shared.updateProgress(id: targetId, seconds: seconds)
            }
            context.coordinator.timeObserver = observer
            context.coordinator.player = player
        }
        
        player.play()
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // No-op
    }
}
