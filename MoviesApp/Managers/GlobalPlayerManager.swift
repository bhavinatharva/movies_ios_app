//
//  GlobalPlayerManager.swift
//  MoviesApp
//
//  Created by Antigravity on 14/05/26.
//

import SwiftUI
import Combine
import AVFoundation

@MainActor
final class GlobalPlayerManager: ObservableObject {
    static let shared = GlobalPlayerManager()
    
    @Published var player: AVPlayer = AVPlayer()
    @Published var isPlaying: Bool = false
    @Published var isMinimized: Bool = false
    
    // Metadata for the Mini-Player
    @Published var currentTitle: String?
    @Published var currentArtwork: String?
    
    // Internal observation
    private var timeObserver: Any?
    
    private init() {
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    func play(url: URL, title: String?, artwork: String?) {
        // If it's already playing the exact same stream, just maximize
        if let currentItem = player.currentItem, let asset = currentItem.asset as? AVURLAsset, asset.url == url {
            maximize()
            return
        }
        
        // Prepare new stream
        let options: [String: Any] = ["AVURLAssetHTTPHeaderFieldsKey": ["User-Agent": "VLC/3.0.11 LibVLC/3.0.11"]]
        let asset = AVURLAsset(url: url, options: options)
        let item = AVPlayerItem(asset: asset)
        
        player.replaceCurrentItem(with: item)
        player.play()
        
        self.currentTitle = title
        self.currentArtwork = artwork
        self.isPlaying = true
        self.isMinimized = false
    }
    
    func stop() {
        player.pause()
        player.replaceCurrentItem(with: nil)
        self.isPlaying = false
        self.isMinimized = false
        self.currentTitle = nil
        self.currentArtwork = nil
    }
    
    func togglePlayPause() {
        if player.timeControlStatus == .playing {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }
    
    func minimize() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isMinimized = true
        }
    }
    
    func maximize() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isMinimized = false
        }
    }
}
