//
//  StreamingPlayerView.swift
//  MoviesApp
//

import SwiftUI
import AVKit
import AVFoundation
import MediaPlayer

struct StreamingPlayerView: View {
    let initialUrl: URL
    let initialTitle: String
    var streamId: String? = nil
    var subtitle: String? = nil
    var isLive: Bool = false
    var logoUrl: String? = nil
    var nextEpisodeTitle: String? = nil
    var onPlayNext: (() -> Void)? = nil
    
    @Environment(\.dismiss) var dismiss
    
    // Dynamic Properties for Zapping
    @State private var currentUrl: URL
    @State private var currentTitle: String
    
    // Player State
    @ObservedObject private var playerManager = GlobalPlayerManager.shared
    @State private var sliderValue: Double = 0
    
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
    
    @State private var triggerPip = false
    @State private var showSubtitleActionSheet = false
    @State private var showAudioActionSheet = false
    @State private var availableSubtitles: [AVMediaSelectionOption] = []
    @State private var availableAudio: [AVMediaSelectionOption] = []
    @State private var subtitleGroup: AVMediaSelectionGroup? = nil
    @State private var audioGroup: AVMediaSelectionGroup? = nil
    @State private var hideControlsTask: Task<Void, Never>? = nil
    @State private var lastProgressSaveTime: Date = .distantPast
    private let progressSaveInterval: TimeInterval = 15
    
    // Sliders state
    @State private var brightnessLevel: Double = 0.5
    @State private var volumeLevel: Double = 0.5
    @State private var volumeSlider: UISlider? = nil
    
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
    
    init(url: URL, title: String, streamId: String? = nil, subtitle: String? = nil, isLive: Bool = false, logoUrl: String? = nil, nextEpisodeTitle: String? = nil, onPlayNext: (() -> Void)? = nil) {
        self.initialUrl = url
        self.initialTitle = title
        self.streamId = streamId
        self.subtitle = subtitle
        self.isLive = isLive
        self.logoUrl = logoUrl
        self.nextEpisodeTitle = nextEpisodeTitle
        self.onPlayNext = onPlayNext
        self._currentUrl = State(initialValue: url)
        self._currentTitle = State(initialValue: title)
    }
    
    var body: some View {
        ZStack {
            // 1. Core Native Player
            PremiumPlayerRepresentable(player: playerManager.player, isAspectFill: isAspectFill, triggerPip: $triggerPip)
                .ignoresSafeArea()
            
            // 2. Invisible Gesture Zones
            if !isLocked {
                GestureController(
                    streamType: streamType,
                    onDoubleTapLeft: { skip(by: -10); showSkipIndicator(isForward: false) },
                    onDoubleTapRight: { skip(by: 10); showSkipIndicator(isForward: true) },
                    onSingleTap: { toggleControls() },
                    onSwipeUp: { zapChannel(forward: true) },
                    onSwipeDown: { zapChannel(forward: false) },
                    onSeekDrag: { delta in
                        if !playerManager.isUserSeeking { playerManager.isUserSeeking = true }
                        sliderValue = max(0, min(playerManager.duration, playerManager.currentTime + Double(delta / 20.0)))
                    },
                    onSeekEnd: {
                        playerManager.isUserSeeking = false
                        playerManager.player.seek(to: CMTime(seconds: sliderValue, preferredTimescale: 1))
                        resetTimer()
                    }
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
                        HStack {
                            VerticalSliderView(value: Binding(get: { brightnessLevel }, set: { val in
                                brightnessLevel = val
                                UIScreen.main.brightness = CGFloat(val)
                                resetTimer()
                            }), icon: "sun.max.fill")
                            .padding(.leading, 40)
                            
                            Spacer()
                            centerControlsView
                            Spacer()
                            
                            VerticalSliderView(value: Binding(get: { volumeLevel }, set: { val in
                                volumeLevel = val
                                volumeSlider?.value = Float(val)
                                resetTimer()
                            }), icon: "speaker.wave.3.fill")
                            .padding(.trailing, 40)
                        }
                        Spacer()
                        bottomControlsView
                    }
                    .onAppear {
                        syncSliders()
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
            
            // 9. Error Overlay
            if let errorMsg = playerManager.playbackError {
                errorOverlayView(message: errorMsg)
            }
        }
        .statusBarHidden(true)
        .onAppear {
            OrientationManager.shared.lockOrientation(.allButUpsideDown)
            setupPlayer()
            setupVolumeView()
            syncSliders()
        }
        .onDisappear {
            OrientationManager.shared.lockOrientation(.portrait, rotateTo: .portrait)
            teardownPlayerView()
        }
        .onChange(of: playerManager.currentTime) { _, newTime in
            if !playerManager.isUserSeeking { sliderValue = newTime }
            if playerManager.duration > 0 && newTime >= playerManager.duration - 15 && !showNextEpisodeOverlay && streamType == .tvSeries {
                withAnimation(.spring()) { showNextEpisodeOverlay = true }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var topOverlayView: some View {
        HStack(spacing: 16) {
            Button(action: {
                playerManager.minimize()
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
            
            // AirPlay Button
            AirPlayView()
                .frame(width: 44, height: 44)
                .background(Color.white.opacity(0.15))
                .clipShape(Circle())
            
            // PiP Button
            Button(action: { triggerPip = true }) {
                Image(systemName: "pip.enter")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Circle())
            }
            
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
                    
                    Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 42))
                        .foregroundColor(.white)
                        .offset(x: playerManager.isPlaying ? 0 : 2)
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
                    Text(formatTime(playerManager.currentTime))
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Slider(value: $sliderValue, in: 0...max(1, playerManager.duration), onEditingChanged: { editing in
                        playerManager.isUserSeeking = editing
                        if !editing {
                            playerManager.player.seek(to: CMTime(seconds: sliderValue, preferredTimescale: 1))
                            resetTimer()
                        }
                    })
                    .tint(Color.accentColor)
                    
                    Text(formatTime(playerManager.duration))
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, 40)
            }
            
            HStack(spacing: 20) {
                Button(action: {
                    isMuted.toggle()
                    playerManager.player.isMuted = isMuted
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
                
                Button(action: { 
                    Task {
                        await fetchMediaOptions()
                        showAudioActionSheet = true
                    }
                }) {
                    Image(systemName: "waveform")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                }
                .confirmationDialog("Select Audio Track", isPresented: $showAudioActionSheet, titleVisibility: .visible) {
                    ForEach(0..<availableAudio.count, id: \.self) { index in
                        let option = availableAudio[index]
                        Button(option.displayName) {
                            if let group = audioGroup {
                                playerManager.player.currentItem?.select(option, in: group)
                            }
                            triggerToast("Audio: \(option.displayName)")
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                }
                
                Button(action: { 
                    Task {
                        await fetchMediaOptions()
                        showSubtitleActionSheet = true
                    }
                }) {
                    Image(systemName: "captions.bubble")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                }
                .confirmationDialog("Select Subtitles", isPresented: $showSubtitleActionSheet, titleVisibility: .visible) {
                    ForEach(0..<availableSubtitles.count, id: \.self) { index in
                        let option = availableSubtitles[index]
                        Button(option.displayName) {
                            if let group = subtitleGroup {
                                playerManager.player.currentItem?.select(option, in: group)
                            }
                            triggerToast("Subtitles: \(option.displayName)")
                        }
                    }
                    Button("Turn Off Subtitles", role: .destructive) {
                        if let group = subtitleGroup {
                            playerManager.player.currentItem?.select(nil, in: group)
                        }
                        triggerToast("Subtitles: Off")
                    }
                    Button("Cancel", role: .cancel) {}
                }
                
                Button(action: {
                    if let vlcUrl = URL(string: "vlc://\(currentUrl.absoluteString)"), UIApplication.shared.canOpenURL(vlcUrl) {
                        UIApplication.shared.open(vlcUrl)
                    } else {
                        triggerToast("VLC is not installed")
                    }
                }) {
                    Image(systemName: "v.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.orange)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                }
                
                if let onPlayNext = onPlayNext {
                    Button(action: {
                        onPlayNext()
                    }) {
                        Image(systemName: "forward.end.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Circle())
                    }
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
                    if let title = nextEpisodeTitle {
                        Text(title).font(.system(size: 16, weight: .black)).foregroundColor(.white)
                    } else {
                        Text("Next Episode").font(.system(size: 16, weight: .black)).foregroundColor(.white)
                    }
                    HStack(spacing: 12) {
                        Button(action: { 
                            withAnimation { showNextEpisodeOverlay = false }
                            onPlayNext?()
                        }) {
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
    
    private func errorOverlayView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.yellow)
            
            Text("Stream Error")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            HStack(spacing: 20) {
                Button(action: {
                    dismiss()
                }) {
                    Text("Go Back")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)
                }
                
                Button(action: {
                    teardownPlayerView()
                    setupPlayer()
                }) {
                    Text("Retry")
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .cornerRadius(12)
                }
            }
            .padding(.top, 10)
        }
        .padding(30)
        .background(Color.black.opacity(0.85))
        .cornerRadius(20)
    }
    
    // MARK: - Logic Helpers
    
    private func setupPlayer(with playbackURL: URL? = nil) {
        let finalUrl = playbackURL ?? currentUrl
        
        playerManager.play(url: finalUrl, title: currentTitle, artwork: logoUrl)
        
        if let targetId = streamId {
            let progress = UserDataManager.shared.getProgress(id: targetId)
            if progress > 0 { playerManager.player.seek(to: CMTime(seconds: progress, preferredTimescale: 1)) }
        }
        
        saveToHistory()
        resetTimer()
    }
    
    private func teardownPlayerView() {
        saveCurrentProgress()
        hideControlsTask?.cancel()
    }
    
    private func swapChannel(to channel: IPTVChannel) {
        currentTitle = channel.name
        currentUrl = channel.streamUrl
        teardownPlayerView()
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
        guard playerManager.currentTime.isFinite, let targetId = streamId else { return }
        UserDataManager.shared.updateProgress(id: targetId, seconds: playerManager.currentTime)
        lastProgressSaveTime = Date()
    }
    
    private func saveToHistory() {
        let id = streamId ?? currentUrl.absoluteString
        let item = UnifiedMediaItem(
            id: id,
            title: currentTitle,
            overview: nil,
            posterPath: logoUrl,
            backdropPath: nil,
            mediaType: streamType,
            source: .iptv,
            releaseDate: nil,
            voteAverage: nil,
            runtime: nil,
            genres: nil,
            streamUrl: currentUrl,
            epgId: nil
        )
        UserDataManager.shared.addToHistory(item)
    }
    
    private func setupVolumeView() {
        let view = MPVolumeView()
        for subview in view.subviews {
            if let slider = subview as? UISlider {
                volumeSlider = slider
                break
            }
        }
    }
    
    private func syncSliders() {
        brightnessLevel = Double(UIScreen.main.brightness)
        if let slider = volumeSlider {
            volumeLevel = Double(slider.value)
        }
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
        playerManager.togglePlayPause()
        resetTimer()
    }
    
    private func skip(by seconds: Double) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        let newTime = max(0, min(playerManager.duration, playerManager.currentTime + seconds))
        playerManager.player.seek(to: CMTime(seconds: newTime, preferredTimescale: 1))
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
                if let onPlayNext = onPlayNext {
                    onPlayNext()
                } else {
                    dismiss()
                }
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
    
    private func fetchMediaOptions() async {
        guard let item = playerManager.player.currentItem else { return }
        
        do {
            _ = try await item.asset.load(.availableMediaCharacteristicsWithMediaSelectionOptions)
        } catch {
            print("Failed to load media characteristics: \(error)")
        }
        
        if let legibleGroup = try? await item.asset.loadMediaSelectionGroup(for: .legible) {
            let options = legibleGroup.options
            await MainActor.run {
                self.subtitleGroup = legibleGroup
                self.availableSubtitles = options
            }
        }
        
        if let audibleGroup = try? await item.asset.loadMediaSelectionGroup(for: .audible) {
            let options = audibleGroup.options
            await MainActor.run {
                self.audioGroup = audibleGroup
                self.availableAudio = options
            }
        }
    }
}

struct VerticalSliderView: View {
    @Binding var value: Double
    var icon: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.white)
                .font(.system(size: 16))
            
            GeometryReader { geometry in
                ZStack(alignment: .bottom) {
                    Capsule()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 6, height: geometry.size.height)
                    
                    Capsule()
                        .fill(Color.accentColor)
                        .frame(width: 6, height: geometry.size.height * CGFloat(value))
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            let height = geometry.size.height
                            let newValue = 1.0 - (gesture.location.y / height)
                            value = max(0, min(1, Double(newValue)))
                        }
                )
            }
            .frame(width: 20, height: 120)
        }
    }
}

struct AirPlayView: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let routePickerView = AVRoutePickerView()
        routePickerView.backgroundColor = .clear
        routePickerView.tintColor = .white
        routePickerView.activeTintColor = .red
        return routePickerView
    }
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}
