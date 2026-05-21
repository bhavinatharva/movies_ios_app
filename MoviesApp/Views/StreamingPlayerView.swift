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
    
    // Player State
    @State private var player = AVPlayer()
    @State private var isPlaying = false
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var sliderValue: Double = 0
    @State private var isSeeking = false
    
    // UI state variables
    @State private var showControls = true
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
    
    var body: some View {
        ZStack {
            // 1. Core Native Player
            PremiumPlayerRepresentable(player: player)
                .aspectRatio(contentMode: isAspectFill ? .fill : .fit)
                .ignoresSafeArea()
                .onTapGesture {
                    toggleControls()
                }
                .gesture(
                    streamType == .liveTV ? DragGesture(minimumDistance: 50)
                        .onEnded { value in
                            if abs(value.translation.height) > abs(value.translation.width) {
                                if value.translation.height < 0 {
                                    // Swipe Up -> Next Channel
                                    zapChannel(forward: true)
                                } else {
                                    // Swipe Down -> Previous Channel
                                    zapChannel(forward: false)
                                }
                            }
                        }
                    : nil
                )
            
            // 2. Gesture overlays for Double Tap to Seek
            HStack(spacing: 0) {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        skip(by: -10)
                        showSkipIndicator(isForward: false)
                    }
                    .onTapGesture {
                        toggleControls()
                    }
                
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        skip(by: 10)
                        showSkipIndicator(isForward: true)
                    }
                    .onTapGesture {
                        toggleControls()
                    }
            }
            .ignoresSafeArea()
            
            // 3. Double-Tap Indicator Overlays
            if showSkipLeft {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.4))
                        .frame(width: 80, height: 80)
                    VStack(spacing: 4) {
                        Image(systemName: "gobackward.10")
                            .font(.title)
                        Text("10s")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                }
                .transition(.scale.combined(with: .opacity))
            }
            
            if showSkipRight {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.4))
                        .frame(width: 80, height: 80)
                    VStack(spacing: 4) {
                        Image(systemName: "goforward.10")
                            .font(.title)
                        Text("10s")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                }
                .transition(.scale.combined(with: .opacity))
            }
            
            // 4. Premium Top, Center, and Bottom Overlays
            if showControls {
                ZStack {
                    // Subtle background vignette vignette for crisp legibility
                    LinearGradient(
                        colors: [.black.opacity(0.6), .clear, .black.opacity(0.65)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                    
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
            
            // 5. Live TV Side Drawer (Fast Channel Switching)
            if showChannelDrawer {
                channelDrawerOverlayView
            }
            
            // 6. Next Episode Countdown Overlay (Series-only)
            if showNextEpisodeOverlay {
                nextEpisodeOverlayView
            }
            
            // 7. Dynamic Info Toast
            if showToast {
                VStack {
                    Spacer()
                    Text(toastMessage)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .glassBackground(cornerRadius: 12)
                        .padding(.bottom, 120)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .statusBarHidden(!showControls)
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            teardownPlayer()
        }
        .onChange(of: currentTime) { _, newTime in
            if !isSeeking {
                sliderValue = newTime
            }
            
            // Auto trigger next episode overlay near video end for movies/series
            if duration > 0 && newTime >= duration - 15 && !showNextEpisodeOverlay && streamType == .tvSeries {
                withAnimation(.spring()) {
                    showNextEpisodeOverlay = true
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var topOverlayView: some View {
        HStack(spacing: 16) {
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .glassBackground(cornerRadius: 22)
            }
            .buttonStyle(PressScaleButtonStyle())
            
            // Metadata info
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
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                
                if let sub = subtitle, !sub.isEmpty {
                    Text(sub)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                } else if streamType == .tvSeries {
                    Text("Season 1 • Episode 1")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                } else if streamType == .movie {
                    Text("Cinematic VOD Movie")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            Spacer()
            
            // Quick Live TV Channel Switching Drawer toggle button
            if streamType == .liveTV {
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        showChannelDrawer.toggle()
                        if showChannelDrawer { showControls = false }
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "list.bullet.rectangle.portrait")
                            .font(.system(size: 14))
                        Text("Channels")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .glassBackground(cornerRadius: 18)
                }
                .buttonStyle(PressScaleButtonStyle())
            }
        }
        .padding(.horizontal)
        .padding(.top, 16)
    }
    
    private var centerControlsView: some View {
        HStack(spacing: 50) {
            // Skip Backward 10s
            Button(action: { skip(by: -10) }) {
                Image(systemName: "gobackward.10")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
            }
            .buttonStyle(PressScaleButtonStyle())
            
            // Massive Play/Pause Action Toggle
            Button(action: togglePlay) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 84, height: 84)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 38))
                        .foregroundColor(.white)
                        .offset(x: isPlaying ? 0 : 2)
                }
            }
            .buttonStyle(PressScaleButtonStyle())
            
            // Skip Forward 10s
            Button(action: { skip(by: 10) }) {
                Image(systemName: "goforward.10")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
            }
            .buttonStyle(PressScaleButtonStyle())
        }
    }
    
    private var bottomControlsView: some View {
        VStack(spacing: 16) {
            // Timeline progress bar
            if streamType != .liveTV {
                HStack(spacing: 12) {
                    Text(formatTime(currentTime))
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Slider(value: $sliderValue, in: 0...max(1, duration), onEditingChanged: { editing in
                        isSeeking = editing
                        if !editing {
                            player.seek(to: CMTime(seconds: sliderValue, preferredTimescale: 1))
                            resetTimer()
                        }
                    })
                    .tint(Color.accentColor)
                    
                    Text(formatTime(duration))
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal)
            } else {
                // Live EPG program timeline track
                let epg = getMockEPG(for: currentTitle)
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(epg.currentShow)
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundColor(.accentColor)
                        
                        Spacer()
                        
                        Text(epg.nextShow)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.12))
                            Capsule()
                                .fill(Color.red)
                                .frame(width: geo.size.width * epg.progress)
                        }
                    }
                    .frame(height: 4)
                }
                .padding(.horizontal)
            }
            
            // Extra functional quick buttons
            HStack {
                // Playback speed toggle
                Menu {
                    ForEach([0.5, 0.75, 1.0, 1.25, 1.5, 2.0], id: \.self) { speed in
                        Button(action: {
                            player.rate = Float(speed)
                            playbackSpeed = speed
                            triggerToast("Speed: \(speed)x")
                        }) {
                            HStack {
                                Text("\(speed, specifier: "%.2f")x")
                                if playbackSpeed == speed {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "speedometer")
                        Text("\(playbackSpeed, specifier: "%.1f")x")
                    }
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .glassBackground(cornerRadius: 18)
                }
                
                // Track selectors (Audio & Subtitles)
                Button(action: {
                    triggerToast("Audio Track: English Stereo")
                }) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .padding(10)
                        .glassBackground(cornerRadius: 18)
                }
                .buttonStyle(PressScaleButtonStyle())
                
                Button(action: {
                    triggerToast("Subtitles: Off")
                }) {
                    Image(systemName: "captions.bubble")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .padding(10)
                        .glassBackground(cornerRadius: 18)
                }
                .buttonStyle(PressScaleButtonStyle())
                
                Spacer()
                
                // Mute toggle
                Button(action: {
                    isMuted.toggle()
                    player.isMuted = isMuted
                    triggerToast(isMuted ? "Muted" : "Unmuted")
                }) {
                    Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.3.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .padding(10)
                        .glassBackground(cornerRadius: 18)
                }
                .buttonStyle(PressScaleButtonStyle())
                
                // Fullscreen Scale/Aspect Ratio Toggle
                Button(action: {
                    withAnimation(.spring()) {
                        isAspectFill.toggle()
                    }
                    triggerToast(isAspectFill ? "Zoom to Fill" : "Aspect Fit")
                }) {
                    Image(systemName: isAspectFill ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .padding(10)
                        .glassBackground(cornerRadius: 18)
                }
                .buttonStyle(PressScaleButtonStyle())
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
    }
    
    // Live TV side scrolling drawer view
    private var channelDrawerOverlayView: some View {
        HStack(spacing: 0) {
            Spacer()
            
            // Drawer Panel
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Live Channels")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.spring()) { showChannelDrawer = false }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.5))
                            .font(.title2)
                    }
                }
                .padding()
                
                Divider()
                    .background(Color.white.opacity(0.12))
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(IPTVDataManager.shared.liveChannels.prefix(30)) { channel in
                            Button(action: {
                                withAnimation {
                                    showChannelDrawer = false
                                    swapChannel(to: channel)
                                }
                            }) {
                                HStack(spacing: 12) {
                                    let encodedLogoUrl = channel.logoUrl?.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? channel.logoUrl?.absoluteString
                                    if let logoUrlString = encodedLogoUrl, let logoUrl = URL(string: logoUrlString) {
                                        AsyncImage(url: logoUrl) { phase in
                                            if let image = phase.image {
                                                image.resizable().scaledToFit().frame(width: 40, height: 40)
                                            } else {
                                                Image(systemName: "tv").frame(width: 40, height: 40)
                                            }
                                        }
                                    } else {
                                        Image(systemName: "tv").frame(width: 40, height: 40)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(channel.name)
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                        Text(channel.category ?? "Live TV")
                                            .font(.system(size: 10))
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                    Spacer()
                                    
                                    if channel.name == currentTitle {
                                        Circle()
                                            .fill(Color.accentColor)
                                            .frame(width: 8, height: 8)
                                    }
                                }
                                .padding(10)
                                .background(channel.name == currentTitle ? Color.white.opacity(0.1) : Color.clear)
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }
            }
            .frame(width: 280)
            .background(.ultraThinMaterial)
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
                    Text("Up Next")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.accentColor)
                    
                    Text("Episode 2")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            withAnimation { showNextEpisodeOverlay = false }
                        }) {
                            Text("Play Next (\(nextEpisodeCountdown))")
                                .font(.system(size: 11, weight: .black))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.white)
                                .foregroundColor(.black)
                                .cornerRadius(8)
                        }
                        
                        Button(action: {
                            withAnimation { showNextEpisodeOverlay = false }
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.white.opacity(0.12))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(16)
                .glassBackground(cornerRadius: 16)
                .frame(width: 220)
                .padding(.trailing, 24)
                .padding(.bottom, 120)
            }
        }
        .onAppear {
            startNextEpisodeTimer()
        }
    }
    
    // MARK: - Logic Helpers
    
    private func setupPlayer(with playbackURL: URL? = nil) {
        let playerItem = AVPlayerItem(url: playbackURL ?? currentUrl)
        player.replaceCurrentItem(with: playerItem)
        
        let timeScale = CMTimeScale(NSEC_PER_SEC)
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: timeScale), queue: .main) { time in
            if !isSeeking {
                currentTime = time.seconds
            }
            if let duration = player.currentItem?.duration {
                let seconds = duration.seconds
                if seconds.isFinite && seconds > 0 {
                    self.duration = seconds
                }
            }
            
            saveProgressIfNeeded(seconds: time.seconds)
        }
        
        if let targetId = streamId {
            let progress = UserDataManager.shared.getProgress(id: targetId)
            if progress > 0 {
                player.seek(to: CMTime(seconds: progress, preferredTimescale: 1))
            }
        }
        
        player.play()
        isPlaying = true
        resetTimer()
    }
    
    private func teardownPlayer() {
        saveCurrentProgress()
        player.pause()
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
            timeObserver = nil
        }
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
        guard seconds.isFinite,
              let targetId = streamId,
              Date().timeIntervalSince(lastProgressSaveTime) >= progressSaveInterval else {
            return
        }
        
        UserDataManager.shared.updateProgress(id: targetId, seconds: seconds)
        lastProgressSaveTime = Date()
    }

    private func saveCurrentProgress() {
        guard currentTime.isFinite, let targetId = streamId else {
            return
        }
        
        UserDataManager.shared.updateProgress(id: targetId, seconds: currentTime)
        lastProgressSaveTime = Date()
    }
    
    private func toggleControls() {
        withAnimation(.easeInOut(duration: 0.35)) {
            showControls.toggle()
        }
        if showControls {
            resetTimer()
        }
    }
    
    private func resetTimer() {
        hideControlsTask?.cancel()
        hideControlsTask = Task {
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.35)) {
                showControls = false
            }
        }
    }
    
    private func togglePlay() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
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
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                showSkipRight = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation { showSkipRight = false }
            }
        } else {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                showSkipLeft = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation { showSkipLeft = false }
            }
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
                dismiss() // Trigger Play Next / Dismiss flow
            }
        }
    }
    
    private func triggerToast(_ msg: String) {
        toastMessage = msg
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            showToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation { showToast = false }
        }
    }
    
    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite && seconds >= 0 else { return "00:00" }
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
}

// MARK: - Core Video Layer Wrapper

struct PremiumPlayerRepresentable: UIViewControllerRepresentable {
    let player: AVPlayer
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed setup PiP audio sessions: \(error)")
        }
        
        let controller = AVPlayerViewController()
        controller.player = player
        controller.allowsPictureInPicturePlayback = true
        controller.canStartPictureInPictureAutomaticallyFromInline = true
        controller.showsPlaybackControls = false // DISABLE native controls fully
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // No-op
    }
}
