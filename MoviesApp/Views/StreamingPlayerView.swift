//
//  StreamingPlayerView.swift

//

import SwiftUI
import AVKit
import AVFoundation
#if os(iOS)
import MediaPlayer
#endif
#if canImport(TVVLCKit)
import TVVLCKit
#elseif canImport(MobileVLCKit)
import MobileVLCKit
#endif

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
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
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
    
    // Video Quality State
    @AppStorage("preferred_video_quality") private var preferredVideoQuality: Double = 0
    @State private var showQualityActionSheet = false
    @State private var availableQualities: [Double] = []
    @State private var currentQuality: Double = 0
    
    // Sliders state
    @State private var brightnessLevel: Double = 0.5
    @State private var volumeLevel: Double = 0.5
    #if os(iOS)
    @State private var volumeSlider: UISlider? = nil
    #endif
    
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
            if playerManager.isUsingVLC {
                VLCPlayerRepresentable(player: playerManager.vlcPlayer, isAspectFill: isAspectFill)
                    .ignoresSafeArea()
            } else {
                PremiumPlayerRepresentable(player: playerManager.player, isAspectFill: isAspectFill, triggerPip: $triggerPip)
                    .ignoresSafeArea()
            }
            
            // 2. Invisible Gesture Zones
            if !isLocked {
                GestureController(
                    streamType: streamType,
                    onDoubleTap: { 
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { isAspectFill.toggle() }
                        triggerToast(isAspectFill ? "Zoom to Fill" : "Aspect Fit")
                    },
                    onSingleTap: { toggleControls() },
                    onSwipeLeft: { zapChannel(forward: true) },
                    onSwipeRight: { zapChannel(forward: false) },
                    onSeekDrag: { delta in
                        if !playerManager.isUserSeeking { playerManager.isUserSeeking = true }
                        sliderValue = max(0, min(playerManager.duration, playerManager.currentTime + Double(delta / 20.0)))
                    },
                    onSeekEnd: {
                        playerManager.isUserSeeking = false
                        if playerManager.isUsingVLC {
                            playerManager.vlcPlayer.time = VLCTime(int: Int32(sliderValue * 1000))
                        } else {
                            playerManager.player.seek(to: CMTime(seconds: sliderValue, preferredTimescale: 1))
                        }
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
                            #if os(iOS)
                            VerticalSliderView(value: Binding(get: { brightnessLevel }, set: { val in
                                brightnessLevel = val
                                UIScreen.main.brightness = CGFloat(val)
                                resetTimer()
                            }), icon: "sun.max.fill")
                            .padding(.leading, 40)
                            #endif
                            
                            Spacer()
                            centerControlsView
                            Spacer()
                            
                            #if os(iOS)
                            VerticalSliderView(value: Binding(get: { volumeLevel }, set: { val in
                                volumeLevel = val
                                volumeSlider?.value = Float(val)
                                resetTimer()
                            }), icon: "speaker.wave.3.fill")
                            .padding(.trailing, 40)
                            #endif
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
                    .transition(.move(edge: .trailing))
                    .zIndex(2)
            }
            
            // 6. Next Episode Countdown
            if showNextEpisodeOverlay && !isLocked {
                nextEpisodeOverlayView
            }
            
            // 6.5. Skip Intro Overlay
            if playerManager.showSkipIntro && !isLocked {
                skipIntroOverlayView
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
        .alert("Stream Error", isPresented: Binding(
            get: { playerManager.playbackError != nil },
            set: { if !$0 { playerManager.playbackError = nil } }
        )) {
            Button("Retry") {
                teardownPlayerView()
                setupPlayer()
            }
            Button("Go Back", role: .cancel) {
                dismiss()
            }
        } message: {
            Text(playerManager.playbackError ?? "Unknown error occurred.")
        }
        #if os(iOS)
        .statusBarHidden(true)
        #endif
        #if os(tvOS)
        .onPlayPauseCommand {
            withAnimation { showControls = true }
            togglePlay()
        }
        .onExitCommand {
            if showChannelDrawer {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    showChannelDrawer = false
                    showControls = true
                }
                resetTimer()
            } else if showControls {
                withAnimation { showControls = false }
                hideControlsTask?.cancel()
            } else {
                playerManager.stop()
                dismiss()
            }
        }
        .onMoveCommand { direction in
            switch direction {
            case .left:
                // Live TV: left/right doesn't zap — use up/down for that
                if streamType != .liveTV {
                    skip(by: -10)
                    showSkipIndicator(isForward: false)
                }
                withAnimation { showControls = true }
                resetTimer()
            case .right:
                if streamType != .liveTV {
                    skip(by: 10)
                    showSkipIndicator(isForward: true)
                }
                withAnimation { showControls = true }
                resetTimer()
            case .up:
                // Live TV: navigate to previous channel (Apple TV UX convention)
                if streamType == .liveTV {
                    zapChannel(forward: false)
                } else {
                    withAnimation { showControls = true }
                    resetTimer()
                }
            case .down:
                // Live TV: navigate to next channel
                if streamType == .liveTV {
                    zapChannel(forward: true)
                } else {
                    withAnimation { showControls = true }
                    resetTimer()
                }
            @unknown default:
                break
            }
        }
        #endif
        .onAppear {
            #if os(iOS)
            OrientationManager.shared.lockOrientation(.allButUpsideDown)
            #endif
            setupPlayer()
            setupVolumeView()
            syncSliders()
        }
        .onDisappear {
            #if os(iOS)
            OrientationManager.shared.lockOrientation(.portrait, rotateTo: .portrait)
            #endif
            teardownPlayerView()
        }
        .onChange(of: playerManager.currentTime) { _, newTime in
            if !playerManager.isUserSeeking { sliderValue = newTime }
            if playerManager.duration > 0 && newTime >= playerManager.duration - 15 && !showNextEpisodeOverlay && streamType == .tvSeries {
                withAnimation(.spring()) { showNextEpisodeOverlay = true }
            }
        }
        .confirmationDialog("Audio Tracks", isPresented: $showAudioActionSheet, titleVisibility: .visible) {
            ForEach(availableAudio, id: \.self) { option in
                Button(option.displayName) {
                    if let group = audioGroup {
                        playerManager.player.currentItem?.select(option, in: group)
                    }
                }
            }
        }
        .confirmationDialog("Subtitles", isPresented: $showSubtitleActionSheet, titleVisibility: .visible) {
            ForEach(availableSubtitles, id: \.self) { option in
                Button(option.displayName) {
                    if let group = subtitleGroup {
                        playerManager.player.currentItem?.select(option, in: group)
                    }
                }
            }
        }
        .confirmationDialog("Video Quality", isPresented: $showQualityActionSheet, titleVisibility: .visible) {
            ForEach(availableQualities, id: \.self) { quality in
                Button(qualityTitle(for: quality)) {
                    setQuality(quality)
                }
            }
        }
    }
    
    private func qualityTitle(for quality: Double) -> String {
        if quality == 0 {
            return "Auto"
        }
        return "\(Int(quality))p"
    }
    
    // MARK: - Subviews
    
    private var topOverlayView: some View {
        HStack(spacing: 16) {
            // Channel Logo
            if streamType == .liveTV {
                ZStack {
                    Color.white.opacity(0.2)
                    if let logoUrlStr = logoUrl, let url = URL(string: logoUrlStr) {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFit().padding(4)
                        } placeholder: {
                            Image(systemName: "tv").foregroundColor(.white.opacity(0.8))
                        }
                    } else {
                        Image(systemName: "tv").foregroundColor(.white.opacity(0.8))
                    }
                }
                #if os(tvOS)
                .frame(width: 56, height: 56)
                .cornerRadius(10)
                #else
                .frame(width: 32, height: 32)
                .cornerRadius(6)
                #endif
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    if streamType == .liveTV {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(Color.white)
                                #if os(tvOS)
                                .frame(width: 8, height: 8)
                                #else
                                .frame(width: 6, height: 6)
                                #endif
                                .scaleEffect(isLiveGlow ? 1.3 : 0.8)
                                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isLiveGlow)
                            Text("LIVE")
                                #if os(tvOS)
                                .font(.system(size: 13, weight: .black, design: .rounded))
                                #else
                                .font(.system(size: 9, weight: .black, design: .rounded))
                                #endif
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.red)
                        .clipShape(Capsule())
                        .onAppear { isLiveGlow = true }
                    } else if !currentUrl.pathExtension.isEmpty {
                        Text(currentUrl.pathExtension.uppercased())
                            #if os(tvOS)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            #else
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            #endif
                            .foregroundColor(.white)
                            .background(Color.white.opacity(0.25))
                            .clipShape(Capsule())
                    }
                    
                    Text(currentTitle)
                        #if os(tvOS)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        #else
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        #endif
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                
                if let sub = subtitle, !sub.isEmpty {
                    Text(sub)
                        #if os(tvOS)
                        .font(.system(size: 18, weight: .medium))
                        #else
                        .font(.system(size: 12, weight: .medium))
                        #endif
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                }
            }
            Spacer()
            // Action buttons
            HStack(spacing: 16) {
                #if os(tvOS)
                // tvOS: Audio & Subtitles always accessible via focusable buttons
                Button(action: {
                    Task {
                        await fetchMediaOptions()
                        showAudioActionSheet = true
                    }
                }) {
                    Image(systemName: "waveform")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(14)
                }
                .buttonStyle(PressScaleButtonStyle())
                
                Button(action: {
                    Task {
                        await fetchMediaOptions()
                        showSubtitleActionSheet = true
                    }
                }) {
                    Image(systemName: "captions.bubble")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(14)
                }
                .buttonStyle(PressScaleButtonStyle())
                
                if streamType == .liveTV {
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            showChannelDrawer.toggle()
                            if showChannelDrawer { showControls = false }
                        }
                    }) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(14)
                    }
                    .buttonStyle(PressScaleButtonStyle())
                }
                
                Button(action: {
                    playerManager.stop()
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(14)
                }
                .buttonStyle(PressScaleButtonStyle())
                #else
                // iOS: show options based on size class
                if verticalSizeClass != .regular {
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
                            .cornerRadius(12)
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
                            .cornerRadius(12)
                    }
                    if streamType != .liveTV {
                        Button(action: {
                            Task {
                                await fetchMediaOptions()
                                showQualityActionSheet = true
                            }
                        }) {
                            Image(systemName: "gearshape")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(12)
                        }
                    }
                }
                if streamType == .liveTV {
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            showChannelDrawer.toggle()
                            if showChannelDrawer { showControls = false }
                        }
                    }) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(12)
                    }
                }
                Button(action: {
                    playerManager.stop()
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(12)
                }
                #endif
            }
        }
        #if os(tvOS)
        .padding(.horizontal, 60)
        .padding(.top, 40)
        #else
        .padding(.horizontal, 40)
        .padding(.top, 20)
        #endif
    }
    
    private var centerControlsView: some View {
        #if os(tvOS)
        HStack(spacing: 80) {
            Button(action: { skip(by: -10) }) {
                Image(systemName: "gobackward.10")
                    .font(.system(size: 52))
                    .foregroundColor(.white)
            }
            .buttonStyle(PressScaleButtonStyle())
            
            Button(action: togglePlay) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 120, height: 120)
                        .overlay(Circle().stroke(Color.white.opacity(0.25), lineWidth: 1.5))
                    
                    Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 56))
                        .foregroundColor(.white)
                        .offset(x: playerManager.isPlaying ? 0 : 3)
                }
            }
            .buttonStyle(PressScaleButtonStyle())
            
            Button(action: { skip(by: 10) }) {
                Image(systemName: "goforward.10")
                    .font(.system(size: 52))
                    .foregroundColor(.white)
            }
            .buttonStyle(PressScaleButtonStyle())
        }
        #else
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
        #endif
    }
    
    private var bottomControlsView: some View {
        #if os(tvOS)
        // tvOS: Clean 10-foot experience — progress bar + time, no iOS-specific controls
        VStack(spacing: 20) {
            if streamType == .liveTV {
                let epg = getMockEPG(for: currentTitle)
                VStack(alignment: .leading, spacing: 6) {
                    Text(epg.currentShow)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    Text("Up Next: \(epg.nextShow)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 60)
            }
            
            HStack(spacing: 20) {
                Text(formatTime(playerManager.currentTime))
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
                    .frame(width: 80, alignment: .leading)
                
                if streamType == .liveTV {
                    let epg = getMockEPG(for: currentTitle)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.25))
                                .frame(height: 6)
                            Capsule()
                                .fill(Color.red)
                                .frame(width: geo.size.width * epg.progress, height: 6)
                        }
                    }
                    .frame(height: 6)
                } else {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.25))
                                .frame(height: 6)
                            Capsule()
                                .fill(Color.accentColor)
                                .frame(width: playerManager.duration > 0 ? geo.size.width * CGFloat(sliderValue / playerManager.duration) : 0, height: 6)
                        }
                    }
                    .frame(height: 6)
                }
                
                Text(formatTime(playerManager.duration))
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
                    .frame(width: 80, alignment: .trailing)
            }
            .padding(.horizontal, 60)
            
            // tvOS hint: show what Menu button does
            HStack(spacing: 0) {
                Spacer()
                if let onPlayNext = onPlayNext {
                    Button(action: { onPlayNext() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "forward.end.fill")
                                .font(.system(size: 18))
                            Text("Next Episode")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(14)
                    }
                    .buttonStyle(PressScaleButtonStyle())
                    .padding(.trailing, 60)
                }
            }
        }
        .padding(.bottom, 50)
        #else
        // iOS: Full controls
        VStack(spacing: 16) {
            if streamType == .liveTV {
                let epg = getMockEPG(for: currentTitle)
                VStack(alignment: .leading, spacing: 4) {
                    Text(epg.currentShow)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Up Next: \(epg.nextShow)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 40)
            }
            
            HStack(spacing: 16) {
                Text(formatTime(playerManager.currentTime))
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.8))
                
                if streamType == .liveTV {
                    let epg = getMockEPG(for: currentTitle)
                    ProgressView(value: epg.progress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: Color.red))
                } else {
                    Slider(value: $sliderValue, in: 0...max(1, playerManager.duration), onEditingChanged: { editing in
                        playerManager.isUserSeeking = editing
                        if !editing {
                            if playerManager.isUsingVLC {
                                playerManager.vlcPlayer.time = VLCTime(int: Int32(sliderValue * 1000))
                            } else {
                                playerManager.player.seek(to: CMTime(seconds: sliderValue, preferredTimescale: 1))
                            }
                            resetTimer()
                        }
                    })
                    .tint(Color.accentColor)
                }
                
                Text(formatTime(playerManager.duration))
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 40)
            
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
                        .cornerRadius(12)
                }
                
                // AirPlay & PiP — landscape only
                if verticalSizeClass != .regular {
                    AirPlayView()
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(12)
                    
                    Button(action: { triggerPip = true }) {
                        Image(systemName: "pip.enter")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(12)
                    }
                }
                
                // Lock Button
                Button(action: {
                    let gen = UIImpactFeedbackGenerator(style: .medium)
                    gen.impactOccurred()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        isLocked = true
                        showControls = false
                    }
                }) {
                    Image(systemName: "lock.open.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(12)
                }
                
                Spacer()
                
                if let onPlayNext = onPlayNext {
                    Button(action: { onPlayNext() }) {
                        Image(systemName: "forward.end.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal, 40)
        }
        .padding(.bottom, 30)
        #endif
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
        GeometryReader { geo in
            HStack(spacing: 0) {
                Color.black.opacity(0.01)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { showChannelDrawer = false }
                    }
                
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Live Channels")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Spacer()
                    }.padding(20)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            Text("All")
                                .font(.system(size: 13, weight: .bold))
                                .padding(.horizontal, 16).padding(.vertical, 8)
                                .background(Color.white).foregroundColor(.black).cornerRadius(12)
                            Text("Favorites")
                                .font(.system(size: 13, weight: .bold))
                                .padding(.horizontal, 16).padding(.vertical, 8)
                                .background(Color.white.opacity(0.1)).foregroundColor(.white).cornerRadius(12)
                            Text("Sports")
                                .font(.system(size: 13, weight: .bold))
                                .padding(.horizontal, 16).padding(.vertical, 8)
                                .background(Color.white.opacity(0.1)).foregroundColor(.white).cornerRadius(12)
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 16)
                    
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(IPTVDataManager.shared.liveChannels.prefix(30)) { channel in
                                let epg = getMockEPG(for: channel.name)
                                Button(action: {
                                    swapChannel(to: channel)
                                }) {
                                    HStack(spacing: 12) {
                                        ZStack {
                                            Color.white.opacity(0.1)
                                            if let logoUrl = channel.logoUrl {
                                                AsyncImage(url: logoUrl) { image in
                                                    image.resizable().scaledToFit().padding(4)
                                                } placeholder: {
                                                    Image(systemName: "tv").foregroundColor(.white)
                                                }
                                            } else {
                                                Image(systemName: "tv").foregroundColor(.white)
                                            }
                                        }
                                        .frame(width: 40, height: 40)
                                        .cornerRadius(6)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(channel.name).font(.system(size: 14, weight: .bold)).foregroundColor(.white).lineLimit(1)
                                            Text(epg.currentShow).font(.system(size: 11)).foregroundColor(.white.opacity(0.5)).lineLimit(1)
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
                .frame(width: max(300, geo.size.width * 0.35))
                .background(.ultraThinMaterial)
            }
        }
        .ignoresSafeArea()
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
    
    private var skipIntroOverlayView: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    if let end = playerManager.currentIntroMarker?.end {
                        playerManager.player.seek(to: CMTime(seconds: end, preferredTimescale: 1))
                        playerManager.showSkipIntro = false
                        resetTimer()
                        #if os(iOS)
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        #endif
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "forward.frame.fill")
                            .font(.system(size: 14))
                        Text("Skip Intro")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .cornerRadius(8)
                }
                .padding(.trailing, 40)
                .padding(.bottom, showControls ? 140 : 40)
            }
        }
        .transition(.move(edge: .trailing).combined(with: .opacity))
        .animation(.spring(), value: showControls)
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
        
        playerManager.play(url: finalUrl, title: currentTitle, artwork: logoUrl, isLive: isLive, streamId: streamId, subtitle: subtitle, nextEpisodeTitle: nextEpisodeTitle, onPlayNext: onPlayNext)
        
        if let targetId = streamId {
            let progress = UserDataManager.shared.getProgress(id: targetId)
            if progress > 0 { playerManager.player.seek(to: CMTime(seconds: progress, preferredTimescale: 1)) }
        }
        
        saveToHistory()
        resetTimer()
        
        // Fetch qualities right away so we can apply preferences or show the button
        Task {
            await fetchMediaOptions()
        }
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
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        #endif
        
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
        #if os(iOS)
        let view = MPVolumeView()
        for subview in view.subviews {
            if let slider = subview as? UISlider {
                volumeSlider = slider
                break
            }
        }
        #endif
    }
    
    private func syncSliders() {
        #if os(iOS)
        brightnessLevel = Double(UIScreen.main.brightness)
        if let slider = volumeSlider {
            volumeLevel = Double(slider.value)
        }
        #endif
    }
    
    private func toggleControls() {
        withAnimation(.easeInOut(duration: 0.35)) { showControls.toggle() }
        if showControls { resetTimer() }
    }
    
    private func resetTimer() {
        hideControlsTask?.cancel()
        hideControlsTask = Task {
            #if os(tvOS)
            // tvOS: longer timeout — Siri Remote requires more deliberate interaction
            try? await Task.sleep(for: .seconds(5))
            #else
            try? await Task.sleep(for: .seconds(3))
            #endif
            guard !Task.isCancelled else { return }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { showControls = false }
        }
    }
    
    private func togglePlay() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        #endif
        playerManager.togglePlayPause()
        resetTimer()
    }
    
    private func skip(by seconds: Double) {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        #endif
        let newTime = max(0, min(playerManager.duration, playerManager.currentTime + seconds))
        if playerManager.isUsingVLC {
            playerManager.vlcPlayer.time = VLCTime(int: Int32(newTime * 1000))
        } else {
            playerManager.player.seek(to: CMTime(seconds: newTime, preferredTimescale: 1))
        }
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
        
        if #available(iOS 15.0, *) {
            if let urlAsset = item.asset as? AVURLAsset {
                do {
                    let variants = try await urlAsset.load(.variants)
                    let heights = variants.compactMap { variant -> Double? in
                        guard let height = variant.videoAttributes?.presentationSize.height else { return nil }
                        return Double(height)
                    }
                    let uniqueHeights = Array(Set(heights)).sorted(by: >)
                    
                    await MainActor.run {
                        self.availableQualities = uniqueHeights
                        // Apply preferred quality automatically if it exists, but only do this once per stream load
                        if self.currentQuality == 0 {
                            if self.preferredVideoQuality > 0 && uniqueHeights.contains(self.preferredVideoQuality) {
                                self.setQuality(self.preferredVideoQuality)
                            } else if self.preferredVideoQuality == 0 {
                                self.setQuality(0)
                            }
                        }
                    }
                } catch {
                    print("Failed to load variants: \(error)")
                }
            }
        }
    }
    
    private func setQuality(_ quality: Double) {
        currentQuality = quality
        preferredVideoQuality = quality // Save globally
        
        if let item = playerManager.player.currentItem {
            if quality == 0 {
                // Reset to Auto
                item.preferredMaximumResolution = .zero
                triggerToast("Quality: Auto")
            } else {
                // Find a variant that matches this height to get the proper CGSize, or construct one
                // Usually width is proportional, but providing just height/width max limit works.
                // We'll set a large width to ensure height is the limiting factor.
                item.preferredMaximumResolution = CGSize(width: 9999, height: quality)
                triggerToast("Quality: \(Int(quality))p")
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
                #if os(iOS)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            let height = geometry.size.height
                            let newValue = 1.0 - (gesture.location.y / height)
                            value = max(0, min(1, Double(newValue)))
                        }
                )
                #endif
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
