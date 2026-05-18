//
//  LiveTVView.swift
//  MoviesApp
//

import SwiftUI
import AVKit

struct LiveTVView: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("has_default_playlist") private var hasDefaultPlaylist = false
    @AppStorage("active_playlist_url") private var activePlaylistUrl = ""
    @State private var viewModel = LiveTVViewModel()
    @State private var userDataManager = UserDataManager.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Dynamic Premium ambient background
                if colorScheme == .light {
                    Color.appBackground.ignoresSafeArea()
                } else {
                    LinearGradient(
                        stops: [
                            .init(color: Color(red: 0.05, green: 0.05, blue: 0.07), location: 0),
                            .init(color: Color(red: 0.01, green: 0.01, blue: 0.02), location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                }
                
                if !hasDefaultPlaylist {
                    emptyPlaylistView
                } else if viewModel.isLoading {
                    ProgressView("Loading Live TV...")
                } else if let error = viewModel.errorMessage {
                    ContentUnavailableView("Error", systemImage: "exclamationmark.triangle", description: Text(error))
                } else {
                    ScrollView {
                        LazyVStack(spacing: 24) {
                            
                            // 1. Mini Live Player Section
                            if let activeChannel = viewModel.activeChannelForMiniPlayer {
                                miniPlayerView(activeChannel)
                                    .padding(.horizontal, 16)
                            }
                            
                            // 2. Favorites Channels Section
                            favoritesSection
                            
                            // 3. Recently Watched Section
                            recentlyWatchedSection
                            
                            // 4. Trending Live Channels Section
                            trendingSection
                            
                            // 5. Category Filters Section (Horizontal Chips)
                            categoryFiltersSection
                            
                            // 6. Main Channel List with EPG
                            mainChannelSection
                        }
                        .padding(.vertical, 16)
                    }
                    .searchable(text: $viewModel.searchQuery, prompt: "Search channels...")
                    .onChange(of: viewModel.searchQuery) { _, _ in
                        viewModel.filterChannels()
                    }
                }
            }
            .navigationTitle(Constants.StringConstants.tabLiveTV)
            .navigationBarTitleDisplayMode(.inline)
            .task(id: activePlaylistUrl) {
                if hasDefaultPlaylist {
                    await viewModel.loadData()
                }
            }
            .fullScreenCover(item: $viewModel.selectedChannelForFullScreen) { channel in
                StreamingPlayerView(url: channel.streamUrl, title: channel.name)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var emptyPlaylistView: some View {
        ContentUnavailableView {
            Label("No Playlist Loaded", systemImage: "tv.slash")
        } description: {
            Text("Go to the Settings tab to add your IPTV M3U Playlist URL and start watching.")
        }
    }
    
    // 1. Mini Live Player
    private func miniPlayerView(_ channel: IPTVChannel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                MiniVideoPlayer(url: channel.streamUrl)
                    .aspectRatio(16/9, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            }
            
            HStack(spacing: 16) {
                // Info block
                VStack(alignment: .leading, spacing: 4) {
                    Text(channel.name)
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(channel.category ?? "General")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Play Controls
                HStack(spacing: 14) {
                    // Favorite Toggle Button
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        userDataManager.toggleFavorite(id: channel.toUnified.id)
                    }) {
                        Image(systemName: userDataManager.isFavorite(id: channel.toUnified.id) ? "star.fill" : "star")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(userDataManager.isFavorite(id: channel.toUnified.id) ? .yellow : .white)
                            .padding(10)
                            .glassBackground(cornerRadius: 10)
                    }
                    .buttonStyle(PressScaleButtonStyle())
                    
                    // Go Fullscreen Button
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        userDataManager.addToHistory(channel.toUnified)
                        viewModel.selectedChannelForFullScreen = channel
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.system(size: 13, weight: .bold))
                            Text("Full Screen")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .cornerRadius(10)
                    }
                    .buttonStyle(PressScaleButtonStyle())
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(12)
        .glassBackground(cornerRadius: 18)
    }
    
    // 2. Favorites Channels Section
    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.body)
                Text("Favorites Channels")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 16)
            
            let favs = viewModel.favorites
            if favs.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "star.slash")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary.opacity(0.6))
                        Text("No Favorite Channels Added Yet")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 16)
                    Spacer()
                }
                .padding(.horizontal, 16)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(favs) { channel in
                            Button(action: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    viewModel.activeChannelForMiniPlayer = channel
                                }
                            }) {
                                VStack(spacing: 8) {
                                    logoContainer(for: channel, size: 50)
                                    
                                    Text(channel.name)
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                        .frame(width: 80)
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 8)
                                .frame(width: 96)
                                .glassBackground(cornerRadius: 14)
                            }
                            .buttonStyle(PressScaleButtonStyle())
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }
    
    // 3. Recently Watched
    private var recentlyWatchedSection: some View {
        let watched = viewModel.recentlyWatched
        return Group {
            if !watched.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(.accentColor)
                            .font(.body)
                        Text("Recently Watched")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 16)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 12) {
                            ForEach(watched) { channel in
                                Button(action: {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                        viewModel.activeChannelForMiniPlayer = channel
                                    }
                                }) {
                                    HStack(spacing: 10) {
                                        logoContainer(for: channel, size: 40)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(channel.name)
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.primary)
                                                .lineLimit(1)
                                            
                                            Text(channel.category ?? "General")
                                                .font(.system(size: 9))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .frame(width: 170, alignment: .leading)
                                    .glassBackground(cornerRadius: 12)
                                }
                                .buttonStyle(PressScaleButtonStyle())
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
        }
    }
    
    // 4. Trending Live Channels Section
    private var trendingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                    .font(.body)
                Text("Trending Live Channels")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    let trendings = viewModel.trendingChannels
                    ForEach(Array(trendings.enumerated()), id: \.element.id) { index, channel in
                        Button(action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                viewModel.activeChannelForMiniPlayer = channel
                            }
                        }) {
                            ZStack(alignment: .topLeading) {
                                VStack(spacing: 8) {
                                    logoContainer(for: channel, size: 54)
                                        .padding(.top, 8)
                                    
                                    Text(channel.name)
                                        .font(.system(size: 12, weight: .black))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                        .frame(width: 100)
                                    
                                    Text(channel.category ?? "General")
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundColor(.white.opacity(0.6))
                                        .lineLimit(1)
                                        .frame(width: 100)
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 10)
                                .frame(width: 120, height: 130)
                                .glassBackground(cornerRadius: 16)
                                
                                // Trending Badge
                                Text("#\(index + 1)")
                                    .font(.system(size: 9, weight: .black))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.orange)
                                    .clipShape(UnevenRoundedRectangle(topLeadingRadius: 16, bottomTrailingRadius: 12))
                            }
                        }
                        .buttonStyle(PressScaleButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    // 5. Category Filters Section
    private var categoryFiltersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Category Filters")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 10) {
                    ForEach(viewModel.categories, id: \.self) { category in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                viewModel.selectCategory(category)
                            }
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                        }) {
                            Text(category)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(viewModel.selectedCategory == category ? .black : .white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(viewModel.selectedCategory == category ? Color.accentColor : Color.white.opacity(0.08))
                                .cornerRadius(18)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(Color.white.opacity(0.12), lineWidth: viewModel.selectedCategory == category ? 0 : 1)
                                )
                        }
                        .buttonStyle(PressScaleButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    // 6. Main Channel List with EPG
    private var mainChannelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Main Channel List with EPG")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
            
            LazyVStack(spacing: 12) {
                let filtered = viewModel.filteredChannels
                if filtered.isEmpty {
                    ContentUnavailableView {
                        Label("No Channels Found", systemImage: "tv.slash")
                    } description: {
                        Text("No live channels match your selection or search query.")
                    }
                } else {
                    ForEach(filtered) { channel in
                        let epg = getMockEPG(for: channel.name)
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                viewModel.activeChannelForMiniPlayer = channel
                            }
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                        }) {
                            HStack(spacing: 14) {
                                // Rounded logo
                                logoContainer(for: channel, size: 50)
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(channel.name)
                                            .font(.system(size: 14, weight: .black, design: .rounded))
                                            .foregroundColor(.primary)
                                            .lineLimit(1)
                                        
                                        Spacer()
                                        
                                        // Category badge
                                        Text(channel.category ?? "General")
                                            .font(.system(size: 8, weight: .bold))
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .glassBackground(cornerRadius: 4)
                                    }
                                    
                                    // EPG Block details
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack(spacing: 4) {
                                            Circle()
                                                .fill(Color.red)
                                                .frame(width: 4, height: 4)
                                            Text(epg.currentShow)
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(.accentColor)
                                                .lineLimit(1)
                                        }
                                        
                                        Text(epg.nextShow)
                                            .font(.system(size: 9))
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                    
                                    // Premium visual EPG progress bar
                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            Capsule()
                                                .fill(Color.white.opacity(0.12))
                                            Capsule()
                                                .fill(Color.red)
                                                .frame(width: geo.size.width * epg.progress)
                                        }
                                    }
                                    .frame(height: 3)
                                }
                            }
                            .padding(12)
                            .glassBackground(cornerRadius: 16)
                            .padding(.horizontal, 16)
                        }
                        .buttonStyle(PressScaleButtonStyle())
                    }
                }
            }
        }
    }
    
    // Shared logo container helper
    private func logoContainer(for channel: IPTVChannel, size: CGFloat) -> some View {
        ZStack {
            Color.white.opacity(0.04)
            
            if let logoUrl = channel.logoUrl {
                AsyncImage(url: logoUrl) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .padding(6)
                    case .failure, .empty:
                        defaultChannelIcon
                    @unknown default:
                        defaultChannelIcon
                    }
                }
            } else {
                defaultChannelIcon
            }
        }
        .frame(width: size, height: size)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
    
    private var defaultChannelIcon: some View {
        Image(systemName: "tv")
            .font(.body)
            .foregroundColor(.white.opacity(0.4))
    }
}

// MARK: - Custom Video Player Toggler Struct
struct MiniVideoPlayer: View {
    let url: URL
    @State private var player: AVPlayer?
    @State private var isMuted = false
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VideoPlayer(player: player)
                .onAppear {
                    let avPlayer = AVPlayer(url: url)
                    avPlayer.isMuted = isMuted
                    self.player = avPlayer
                    avPlayer.play()
                }
                .onDisappear {
                    player?.pause()
                    player = nil
                }
                .onChange(of: url) { _, newUrl in
                    player?.pause()
                    let avPlayer = AVPlayer(url: newUrl)
                    avPlayer.isMuted = isMuted
                    self.player = avPlayer
                    avPlayer.play()
                }
            
            // Inline player mute/unmute
            Button(action: {
                isMuted.toggle()
                player?.isMuted = isMuted
            }) {
                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.white)
                    .padding(8)
                    .glassBackground(cornerRadius: 8)
            }
            .buttonStyle(PressScaleButtonStyle())
            .padding(8)
        }
    }
}

// MARK: - EPG Data structures
struct MockEPGInfo {
    let currentShow: String
    let nextShow: String
    let progress: Double
}

func getMockEPG(for channelName: String) -> MockEPGInfo {
    let hash = abs(channelName.hashValue)
    
    let currentShows = [
        "Live Premier League Football",
        "World News Live Tonight",
        "Classic Movie Afternoon Block",
        "Action Cinema Spotlight",
        "The Breakfast Show Live",
        "Evening Business Report",
        "Formula 1 Live Practice",
        "Discovery: Deep Blue Oceans",
        "Classic Hits Countdown",
        "Weekend Comedy Festival"
    ]
    
    let nextShows = [
        "Up Next: Post-Match Analysis",
        "Up Next: Financial Headlines",
        "Up Next: Late Night Crime Thriller",
        "Up Next: Making of the Blockbuster",
        "Up Next: Global Weather Tracker",
        "Up Next: Stock Market Summary",
        "Up Next: Live Qualifiers Analysis",
        "Up Next: Wonders of the Solar System",
        "Up Next: Acoustic Sessions Special",
        "Up Next: Late Night Satirical Review"
    ]
    
    let current = currentShows[hash % currentShows.count]
    let next = nextShows[(hash + 1) % nextShows.count]
    let progress = Double((hash % 60) + 20) / 100.0
    
    return MockEPGInfo(currentShow: current, nextShow: next, progress: progress)
}
