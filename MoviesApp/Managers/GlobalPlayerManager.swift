//
//  GlobalPlayerManager.swift

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
    
    // Metadata for the Mini-Player & Global Full Screen Player
    @Published var currentTitle: String?
    @Published var currentArtwork: String?
    @Published var streamId: String?
    @Published var subtitle: String?
    @Published var isLive: Bool = false
    @Published var nextEpisodeTitle: String?
    @Published var onPlayNext: (() -> Void)?
    
    @Published var playbackError: String?
    
    private var currentUrl: URL?
    private var retryCount: Int = 0
    
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
    
    func play(url: URL, title: String?, artwork: String?, isLive: Bool = false, streamId: String? = nil, subtitle: String? = nil, nextEpisodeTitle: String? = nil, onPlayNext: (() -> Void)? = nil) {
        // If it's already playing the exact same stream, just maximize.
        // We check currentUrl instead of the AVPlayerItem to prevent a race condition 
        // where StreamingPlayerView might re-trigger play before the first background load completes.
        if self.currentUrl == url {
            playbackError = nil
            maximize()
            return
        }
        
        self.currentUrl = url
        self.isLive = isLive
        self.retryCount = 0
        self.currentTitle = title
        self.currentArtwork = artwork
        self.streamId = streamId
        self.subtitle = subtitle
        self.nextEpisodeTitle = nextEpisodeTitle
        self.onPlayNext = onPlayNext
        
        setupNewItem(url: url)
        
        self.isPlaying = true
        self.isMinimized = false
    }
    
    private func setupNewItem(url: URL) {
        playbackError = nil
        let options: [String: Any] = ["AVURLAssetHTTPHeaderFieldsKey": ["User-Agent": "VLC/3.0.11 LibVLC/3.0.11"]]
        
        Task.detached {
            let asset = AVURLAsset(url: url, options: options)
            let item = AVPlayerItem(asset: asset)
            
            await MainActor.run {
                if self.isLive {
                    item.preferredForwardBufferDuration = 1.0
                } else {
                    item.preferredForwardBufferDuration = 10.0
                }
                
                // Observe item status for errors like timeouts
                self.itemObservation?.cancel()
                self.itemObservation = item.publisher(for: \.status).sink { [weak self] status in
                    guard let self = self else { return }
                    if status == .failed, let error = item.error {
                        print("GlobalPlayerManager Error: \(error.localizedDescription)")
                        
                        if self.isLive && self.retryCount < 3 {
                            self.retryCount += 1
                            print("GlobalPlayerManager: Retrying live stream (\(self.retryCount)/3)...")
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                if self.currentUrl == url {
                                    self.setupNewItem(url: url)
                                }
                            }
                        } else {
                            self.playbackError = error.localizedDescription
                            self.isPlaying = false
                        }
                    }
                }
                
                self.player.automaticallyWaitsToMinimizeStalling = true
                self.player.replaceCurrentItem(with: item)
                self.player.play()
            }
        }
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
        self.currentUrl = nil
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
