//
//  LiveTVComponents.swift
//  MoviesApp
//

import SwiftUI
import AVKit

// MARK: - Logo Container
struct ChannelLogoView: View {
    let logoUrl: URL?
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Color.white.opacity(0.04)
            
            if let logoUrl = logoUrl {
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

// MARK: - Mini HLS Player View
struct LiveMiniPlayerView: View {
    let channel: IPTVChannel
    @Binding var selectedFullScreenChannel: IPTVChannel?
    @State private var userDataManager = UserDataManager.shared
    
    var body: some View {
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
                
                HStack(spacing: 14) {
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
                    
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        userDataManager.addToHistory(channel.toUnified)
                        selectedFullScreenChannel = channel
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
}

// MARK: - Favorites Carousel List
struct LiveFavoritesListView: View {
    let favorites: [IPTVChannel]
    @Binding var activeMiniPlayerChannel: IPTVChannel?
    
    var body: some View {
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
            
            if favorites.isEmpty {
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
                        ForEach(favorites) { channel in
                            Button(action: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    activeMiniPlayerChannel = channel
                                }
                            }) {
                                VStack(spacing: 8) {
                                    ChannelLogoView(logoUrl: channel.logoUrl, size: 50)
                                    
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
}

// MARK: - Recently Watched Carousel List
struct LiveRecentlyWatchedListView: View {
    let recentlyWatched: [IPTVChannel]
    @Binding var activeMiniPlayerChannel: IPTVChannel?
    
    var body: some View {
        Group {
            if !recentlyWatched.isEmpty {
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
                            ForEach(recentlyWatched) { channel in
                                Button(action: {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                        activeMiniPlayerChannel = channel
                                    }
                                }) {
                                    HStack(spacing: 10) {
                                        ChannelLogoView(logoUrl: channel.logoUrl, size: 40)
                                        
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
}

// MARK: - Trending Live Channels List
struct LiveTrendingListView: View {
    let trendingChannels: [IPTVChannel]
    @Binding var activeMiniPlayerChannel: IPTVChannel?
    
    var body: some View {
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
                    ForEach(Array(trendingChannels.enumerated()), id: \.element.id) { index, channel in
                        Button(action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                activeMiniPlayerChannel = channel
                            }
                        }) {
                            ZStack(alignment: .topLeading) {
                                VStack(spacing: 8) {
                                    ChannelLogoView(logoUrl: channel.logoUrl, size: 54)
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
}

// MARK: - Category Filters
struct LiveCategoryFiltersView: View {
    let categories: [String]
    @Binding var selectedCategory: String
    let onSelect: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Category Filters")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 10) {
                    ForEach(categories, id: \.self) { category in
                        Button(action: {
                            onSelect(category)
                        }) {
                            Text(category)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(selectedCategory == category ? .black : .white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedCategory == category ? Color.accentColor : Color.white.opacity(0.08))
                                .cornerRadius(18)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(Color.white.opacity(0.12), lineWidth: selectedCategory == category ? 0 : 1)
                                )
                        }
                        .buttonStyle(PressScaleButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

// MARK: - Main Channel List with EPG
struct LiveMainChannelListView: View {
    let filteredChannels: [IPTVChannel]
    @Binding var activeMiniPlayerChannel: IPTVChannel?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Main Channel List with EPG")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
            
            LazyVStack(spacing: 12) {
                if filteredChannels.isEmpty {
                    ContentUnavailableView {
                        Label("No Channels Found", systemImage: "tv.slash")
                    } description: {
                        Text("No live channels match your selection or search query.")
                    }
                } else {
                    ForEach(filteredChannels) { channel in
                        let epg = getMockEPG(for: channel.name)
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                activeMiniPlayerChannel = channel
                            }
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                        }) {
                            HStack(spacing: 14) {
                                ChannelLogoView(logoUrl: channel.logoUrl, size: 50)
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(channel.name)
                                            .font(.system(size: 14, weight: .black, design: .rounded))
                                            .foregroundColor(.primary)
                                            .lineLimit(1)
                                        
                                        Spacer()
                                        
                                        Text(channel.category ?? "General")
                                            .font(.system(size: 8, weight: .bold))
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .glassBackground(cornerRadius: 4)
                                    }
                                    
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
}

// MARK: - Custom Video Player Struct
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

// MARK: - EPG Data structures and helper
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
