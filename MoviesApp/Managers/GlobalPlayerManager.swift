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
    
    // Playback state
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var isUserSeeking: Bool = false
    
    // Metadata for the Mini-Player
    @Published var currentTitle: String?
    @Published var currentArtwork: String?
    
    @Published var playbackError: String?
    
    // Internal observation
    private var timeObserver: Any?
    private var itemObservation: AnyCancellable?
    private var statusObservation: AnyCancellable?
    
    private init() {
        setupAudioSession()
        setupObservers()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func setupObservers() {
        let timeScale = CMTimeScale(NSEC_PER_SEC)
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: timeScale), queue: .main) { [weak self] time in
            guard let self = self else { return }
            if !self.isUserSeeking {
                self.currentTime = time.seconds
            }
            if let d = self.player.currentItem?.duration {
                let seconds = d.seconds
                if seconds.isFinite && seconds > 0 { self.duration = seconds }
            }
        }
        
        statusObservation = player.publisher(for: \.timeControlStatus).sink { [weak self] status in
            self?.isPlaying = (status == .playing)
        }
    }
    
    func play(url: URL, title: String?, artwork: String?) {
        // If it's already playing the exact same stream, just maximize
        if let currentItem = player.currentItem, let asset = currentItem.asset as? AVURLAsset, asset.url == url {
            playbackError = nil
            maximize()
            return
        }
        
        // Prepare new stream
        playbackError = nil
        let options: [String: Any] = ["AVURLAssetHTTPHeaderFieldsKey": ["User-Agent": "VLC/3.0.11 LibVLC/3.0.11"]]
        let asset = AVURLAsset(url: url, options: options)
        let item = AVPlayerItem(asset: asset)
        item.preferredForwardBufferDuration = 10.0
        
        // Observe item status for errors like timeouts
        itemObservation?.cancel()
        itemObservation = item.publisher(for: \.status).sink { [weak self] status in
            guard let self = self else { return }
            if status == .failed, let error = item.error {
                self.playbackError = error.localizedDescription
                self.isPlaying = false
                print("GlobalPlayerManager Error: \(error.localizedDescription)")
            }
        }
        
        player.automaticallyWaitsToMinimizeStalling = false
        player.replaceCurrentItem(with: item)
        player.play()
        
        self.currentTitle = title
        self.currentArtwork = artwork
        self.isPlaying = true
        self.isMinimized = false
    }
    
    func stop() {
        player.pause()
        itemObservation?.cancel()
        itemObservation = nil
        player.replaceCurrentItem(with: nil)
        self.isPlaying = false
        self.isMinimized = false
        self.playbackError = nil
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
