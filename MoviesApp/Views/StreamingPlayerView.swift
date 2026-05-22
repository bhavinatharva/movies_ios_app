//
//  StreamingPlayerView.swift
//  MoviesApp
//

import SwiftUI
import AVKit
import AVFoundation

struct StreamingPlayerView: View {
    let initialUrl: URL
    let initialTitle: String
    var streamId: String? = nil
    var subtitle: String? = nil
    var isLive: Bool = false
    var logoUrl: String? = nil
    
    @Environment(\.dismiss) var dismiss
    
    // Dynamic Properties for Zapping
    @State private var currentUrl: URL
    @State private var currentTitle: String
    
    // Player State
    @State private var player = AVPlayer()
    @State private var isPlaying = false
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var sliderValue: Double = 0
    @State private var isSeeking = false
    
    // UI state variables
    @State private var showControls = true
    @State private var isLocked = false
    @State private var playbackSpeed: Double = 1.0
    @State private var isMuted = false
    @State private var isAspectFill = false
    @State private var showSkipLeft = false
    @State private var showSkipRight = false
    @State private var isLiveGlow = false
    @State private var showChannelDrawer = false
    @State private var showNextEpisodeOverlay = false
    @State private var nextEpisodeCountdown = 10
    
    // Toast notification state
    @State private var toastMessage = ""
    @State private var showToast = false
    
    @State private var timeObserver: Any? = nil
    @State private var hideControlsTask: Task<Void, Never>? = nil
    @State private var lastProgressSaveTime: Date = .distantPast
    private let progressSaveInterval: TimeInterval = 15
    
    // Detect stream types
    var streamType: MediaType {
        let path = currentUrl.absoluteString.lowercased()
        if path.contains("/series/") {
            return .tvSeries
        } else if path.contains("/movie/") || path.hasSuffix(".mp4") || path.hasSuffix(".mkv") {
            return .movie
        } else {
            return isLive ? .liveTV : .liveTV
        }
    }
    
    init(url: URL, title: String, streamId: String? = nil, subtitle: String? = nil, isLive: Bool = false, logoUrl: String? = nil) {
        self.initialUrl = url
        self.initialTitle = title
        self.streamId = streamId
        self.subtitle = subtitle
        self.isLive = isLive
        self.logoUrl = logoUrl
        self._currentUrl = State(initialValue: url)
        self._currentTitle = State(initialValue: title)
    }
    
    var body: some View {
        ZStack {
            // 1. Core Native Player
            PremiumPlayerRepresentable(player: player, isAspectFill: isAspectFill)
                .ignoresSafeArea()
            
            // 2. Invisible Gesture Zones
            if !isLocked {
                GestureController(
                    streamType: streamType,
                    onDoubleTapLeft: { skip(by: -10); showSkipIndicator(isForward: false) },
                    onDoubleTapRight: { skip(by: 10); showSkipIndicator(isForward: true) },
                    onSingleTap: { toggleControls() },
                    onSwipeUp: { zapChannel(forward: true) },
                    onSwipeDown: { zapChannel(forward: false) }
                )
            }
            
            // 3. Double-Tap Indicator Overlays
            if showSkipLeft { skipIndicator(icon: "gobackward.10") }
            if showSkipRight { skipIndicator(icon: "goforward.10") }
            
            // 4. Premium Top, Center, and Bottom Overlays
            if showControls && !isLocked {
                ZStack {
                    LinearGradient(
                        colors: [.black.opacity(0.7), .clear, .black.opacity(0.75)],
                        startPoint: .top,
                        endPoint: .bottom
                    ).ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        topOverlayView
                        Spacer()
                        centerControlsView
                        Spacer()
                        bottomControlsView
                    }
                }
                .transition(.opacity)
            }
            
            // 5. Live TV Side Drawer
            if showChannelDrawer && !isLocked {
                channelDrawerOverlayView
            }
            
            // 6. Next Episode Countdown
            if showNextEpisodeOverlay && !isLocked {
                nextEpisodeOverlayView
            }
            
            // 7. Dynamic Info Toast
            if showToast {
                toastOverlayView
            }
            
            // 8. Lock Screen Controller
            if isLocked {
                LockScreenController(isLocked: $isLocked)
            }
        }
        .statusBarHidden(true)
        .onAppear {
            OrientationManager.shared.lockOrientation(.landscape, rotateTo: .landscapeRight)
            setupPlayer()
        }
        .onDisappear {
            OrientationManager.shared.lockOrientation(.allButUpsideDown, rotateTo: .portrait)
            teardownPlayer()
        }
        .onChange(of: currentTime) { _, newTime in
            if !isSeeking { sliderValue = newTime }
            if duration > 0 && newTime >= duration - 15 && !showNextEpisodeOverlay && streamType == .tvSeries {
                withAnimation(.spring()) { showNextEpisodeOverlay = true }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var topOverlayView: some View {
        HStack(spacing: 16) {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Circle())
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    if streamType == .liveTV {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 6, height: 6)
                                .scaleEffect(isLiveGlow ? 1.3 : 0.8)
                                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isLiveGlow)
                            Text("LIVE")
                                .font(.system(size: 9, weight: .black, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red)
                        .cornerRadius(6)
                        .onAppear { isLiveGlow = true }
                    }
                    
                    Text(currentTitle)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                
                if let sub = subtitle, !sub.isEmpty {
                    Text(sub)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                }
            }
            Spacer()
            
            // Lock Button
            Button(action: {
                let gen = UIImpactFeedbackGenerator(style: .medium)
                gen.impactOccurred()
                withAnimation(.spring()) {
                    isLocked = true
                    showControls = false
                }
            }) {
                Image(systemName: "lock.open.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Circle())
            }
            
            if streamType == .liveTV {
                Button(action: {
                    withAnimation(.spring()) {
                        showChannelDrawer.toggle()
                        if showChannelDrawer { showControls = false }
                    }
                }) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 40)
        .padding(.top, 20)
    }
    
    private var centerControlsView: some View {
        HStack(spacing: 60) {
            Button(action: { skip(by: -10) }) {
                Image(systemName: "gobackward.10")
                    .font(.system(size: 38))
                    .foregroundColor(.white)
            }
            .buttonStyle(PressScaleButtonStyle())
            
            Button(action: togglePlay) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 90, height: 90)
                        .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                    
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 42))
                        .foregroundColor(.white)
                        .offset(x: isPlaying ? 0 : 2)
                }
            }
            .buttonStyle(PressScaleButtonStyle())
            
            Button(action: { skip(by: 10) }) {
                Image(systemName: "goforward.10")
                    .font(.system(size: 38))
                    .foregroundColor(.white)
            }
            .buttonStyle(PressScaleButtonStyle())
        }
    }
    
    private var bottomControlsView: some View {
        VStack(spacing: 24) {
            if streamType != .liveTV {
                HStack(spacing: 16) {
                    Text(formatTime(currentTime))
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Slider(value: $sliderValue, in: 0...max(1, duration), onEditingChanged: { editing in
                        isSeeking = editing
                        if !editing {
                            player.seek(to: CMTime(seconds: sliderValue, preferredTimescale: 1))
                            resetTimer()
                        }
                    })
                    .tint(Color.accentColor)
                    
                    Text(formatTime(duration))
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, 40)
            }
            
            HStack(spacing: 20) {
                Button(action: {
                    isMuted.toggle()
                    player.isMuted = isMuted
                    triggerToast(isMuted ? "Muted" : "Unmuted")
                }) {
                    Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.3.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                }
                
                Button(action: {
                    withAnimation(.spring()) { isAspectFill.toggle() }
                    triggerToast(isAspectFill ? "Zoom to Fill" : "Aspect Fit")
                }) {
                    Image(systemName: isAspectFill ? "arrow.up.left.and.arrow.down.right" : "arrow.down.right.and.arrow.up.left")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                }
                Spacer()
                
                Button(action: { triggerToast("Subtitles: Off") }) {
                    Image(systemName: "captions.bubble")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 40)
        }
        .padding(.bottom, 30)
    }
    
    private func skipIndicator(icon: String) -> some View {
        ZStack {
            Circle().fill(Color.black.opacity(0.5)).frame(width: 90, height: 90)
            VStack(spacing: 4) {
                Image(systemName: icon).font(.title)
                Text("10s").font(.caption).fontWeight(.bold)
            }.foregroundColor(.white)
        }.transition(.scale.combined(with: .opacity))
    }
    
    private var channelDrawerOverlayView: some View {
        HStack(spacing: 0) {
            Spacer()
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Live Channels")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { withAnimation { showChannelDrawer = false } }) {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.white.opacity(0.5)).font(.title2)
                    }
                }.padding(20)
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(IPTVDataManager.shared.liveChannels.prefix(30)) { channel in
                            Button(action: {
                                withAnimation { showChannelDrawer = false; swapChannel(to: channel) }
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "tv").frame(width: 40, height: 40).foregroundColor(.white)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(channel.name).font(.system(size: 14, weight: .bold)).foregroundColor(.white).lineLimit(1)
                                        Text(channel.category ?? "Live TV").font(.system(size: 11)).foregroundColor(.white.opacity(0.5))
                                    }
                                    Spacer()
                                }
                                .padding(12)
                                .background(channel.name == currentTitle ? Color.white.opacity(0.15) : Color.clear)
                                .cornerRadius(12)
                            }
                        }
                    }.padding(.horizontal, 20)
                }
            }
            .frame(width: 300)
            .background(Color.black.opacity(0.8))
            .ignoresSafeArea()
            .transition(.move(edge: .trailing))
        }
    }
    
    private var nextEpisodeOverlayView: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack(alignment: .leading, spacing: 8) {
                    Text("Up Next").font(.system(size: 11, weight: .bold)).foregroundColor(.accentColor)
                    Text("Episode 2").font(.system(size: 16, weight: .black)).foregroundColor(.white)
                    HStack(spacing: 12) {
                        Button(action: { dismiss() }) {
                            Text("Play Next (\(nextEpisodeCountdown))")
                                .font(.system(size: 12, weight: .black))
                                .padding(.horizontal, 16).padding(.vertical, 10)
                                .background(Color.white).foregroundColor(.black).cornerRadius(8)
                        }
                        Button(action: { withAnimation { showNextEpisodeOverlay = false } }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                                .padding(10).background(Color.white.opacity(0.2)).cornerRadius(8)
                        }
                    }
                }
                .padding(20).background(Color.black.opacity(0.7)).cornerRadius(16)
                .padding(.trailing, 40).padding(.bottom, 120)
            }
        }.onAppear { startNextEpisodeTimer() }
    }
    
    private var toastOverlayView: some View {
        VStack {
            Spacer()
            Text(toastMessage)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.7))
                .cornerRadius(12)
                .padding(.bottom, 140)
        }.transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    // MARK: - Logic Helpers
    
    private func setupPlayer(with playbackURL: URL? = nil) {
        let finalUrl = playbackURL ?? currentUrl
        let options: [String: Any] = ["AVURLAssetHTTPHeaderFieldsKey": ["User-Agent": "VLC/3.0.11 LibVLC/3.0.11"]]
        let asset = AVURLAsset(url: finalUrl, options: options)
        let playerItem = AVPlayerItem(asset: asset)
        player.replaceCurrentItem(with: playerItem)
        
        let timeScale = CMTimeScale(NSEC_PER_SEC)
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: timeScale), queue: .main) { time in
            if !isSeeking { currentTime = time.seconds }
            if let d = player.currentItem?.duration {
                let seconds = d.seconds
                if seconds.isFinite && seconds > 0 { self.duration = seconds }
            }
            saveProgressIfNeeded(seconds: time.seconds)
        }
        
        if let targetId = streamId {
            let progress = UserDataManager.shared.getProgress(id: targetId)
            if progress > 0 { player.seek(to: CMTime(seconds: progress, preferredTimescale: 1)) }
        }
        
        player.play()
        isPlaying = true
        resetTimer()
    }
    
    private func teardownPlayer() {
        saveCurrentProgress()
        player.pause()
        if let observer = timeObserver { player.removeTimeObserver(observer); timeObserver = nil }
        hideControlsTask?.cancel()
    }
    
    private func swapChannel(to channel: IPTVChannel) {
        currentTitle = channel.name
        currentUrl = channel.streamUrl
        teardownPlayer()
        setupPlayer(with: channel.streamUrl)
        triggerToast("Swapped to \(channel.name)")
    }
    
    private func zapChannel(forward: Bool) {
        let channels = IPTVDataManager.shared.liveChannels
        guard !channels.isEmpty else { return }
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        
        if let currentIndex = channels.firstIndex(where: { $0.streamUrl == currentUrl }) {
            var newIndex = forward ? currentIndex + 1 : currentIndex - 1
            if newIndex < 0 { newIndex = channels.count - 1 }
            if newIndex >= channels.count { newIndex = 0 }
            swapChannel(to: channels[newIndex])
        } else {
            swapChannel(to: channels[0])
        }
    }

    private func saveProgressIfNeeded(seconds: Double) {
        guard seconds.isFinite, let targetId = streamId, Date().timeIntervalSince(lastProgressSaveTime) >= progressSaveInterval else { return }
        UserDataManager.shared.updateProgress(id: targetId, seconds: seconds)
        lastProgressSaveTime = Date()
    }

    private func saveCurrentProgress() {
        guard currentTime.isFinite, let targetId = streamId else { return }
        UserDataManager.shared.updateProgress(id: targetId, seconds: currentTime)
        lastProgressSaveTime = Date()
    }
    
    private func toggleControls() {
        withAnimation(.easeInOut(duration: 0.35)) { showControls.toggle() }
        if showControls { resetTimer() }
    }
    
    private func resetTimer() {
        hideControlsTask?.cancel()
        hideControlsTask = Task {
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.35)) { showControls = false }
        }
    }
    
    private func togglePlay() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        if isPlaying { player.pause() } else { player.play() }
        isPlaying.toggle()
        resetTimer()
    }
    
    private func skip(by seconds: Double) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        let newTime = max(0, min(duration, currentTime + seconds))
        player.seek(to: CMTime(seconds: newTime, preferredTimescale: 1))
        resetTimer()
    }
    
    private func showSkipIndicator(isForward: Bool) {
        if isForward {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { showSkipRight = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { withAnimation { showSkipRight = false } }
        } else {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { showSkipLeft = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { withAnimation { showSkipLeft = false } }
        }
    }
    
    private func startNextEpisodeTimer() {
        Task {
            for _ in 0..<10 {
                try? await Task.sleep(for: .seconds(1))
                if !showNextEpisodeOverlay { break }
                nextEpisodeCountdown -= 1
            }
            if showNextEpisodeOverlay {
                withAnimation { showNextEpisodeOverlay = false }
                dismiss()
            }
        }
    }
    
    private func triggerToast(_ message: String) {
        toastMessage = message
        withAnimation { showToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showToast = false }
        }
        resetTimer()
    }
    
    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite && !seconds.isNaN else { return "00:00" }
        let totalSeconds = Int(seconds)
        let h = totalSeconds / 3600
        let m = (totalSeconds % 3600) / 60
        let s = totalSeconds % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }
    
    private func getMockEPG(for channelName: String) -> (currentShow: String, nextShow: String, progress: Double) {
        return ("Evening News", "Late Night Movie", 0.65)
    }
}
