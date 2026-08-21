//
//  LiveTVComponents.swift
//  MoviesApp
//

import SwiftUI
import AVKit

// MARK: - Live TV Hero Header View (Auto-playing banner)
struct LiveTVHeroHeaderView: View {
    let channel: IPTVChannel
    let onSelect: () -> Void
    
    @State private var epg = MockEPGInfo(currentShow: "Loading...", nextShow: "Loading...", progress: 0.0)
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Full-bleed mini player serving as live background
            LiveMiniPlayerView(url: channel.streamUrl)
                .frame(height: 480)
                .clipped()
            
            // Animated Gradient for readability
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.4),
                    .init(color: .black.opacity(0.6), location: 0.7),
                    .init(color: .appBackground, location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 480)
            
            // Metadata
            VStack(alignment: .leading, spacing: 12) {
                // Live Badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                    Text("LIVE NOW")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundColor(.red)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.red.opacity(0.2))
                .clipShape(Capsule())
                
                Text(channel.name)
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.8), radius: 4, y: 2)
                
                Text(epg.currentShow)
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack(spacing: 12) {
                    Button(action: onSelect) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                            Text("Details")
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .cornerRadius(8)
                    }
                    .buttonStyle(PressScaleButtonStyle())
                    
                    Button(action: {
                        UserDataManager.shared.toggleFavorite(id: channel.toUnified.id)
                    }) {
                        Image(systemName: UserDataManager.shared.isFavorite(id: channel.toUnified.id) ? "star.fill" : "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(8)
                    }
                    .buttonStyle(PressScaleButtonStyle())
                }
                .padding(.top, 4)
            }
            .padding(24)
        }
        .onAppear {
            epg = getMockEPG(for: channel.name)
        }
    }
}

// MARK: - Auto-Playing Background Player without Controls
struct LiveMiniPlayerView: View {
    let url: URL
    @State private var player: AVPlayer?
    
    var body: some View {
        VideoPlayer(player: player)
            .disabled(true) // Disable interactions
            .onAppear {
                let options: [String: Any] = ["AVURLAssetHTTPHeaderFieldsKey": ["User-Agent": "VLC/3.0.11 LibVLC/3.0.11"]]
                let asset = AVURLAsset(url: url, options: options)
                let playerItem = AVPlayerItem(asset: asset)
                let avPlayer = AVPlayer(playerItem: playerItem)
                avPlayer.isMuted = true // Always muted for background hero
                self.player = avPlayer
                avPlayer.play()
            }
            .onDisappear {
                player?.pause()
                player = nil
            }
            .onChange(of: url) { _, newUrl in
                player?.pause()
                let options: [String: Any] = ["AVURLAssetHTTPHeaderFieldsKey": ["User-Agent": "VLC/3.0.11 LibVLC/3.0.11"]]
                let asset = AVURLAsset(url: newUrl, options: options)
                let playerItem = AVPlayerItem(asset: asset)
                let avPlayer = AVPlayer(playerItem: playerItem)
                avPlayer.isMuted = true
                self.player = avPlayer
                avPlayer.play()
            }
    }
}

// MARK: - Live Channel Horizontal Rail
struct LiveChannelHorizontalRowView: View {
    let title: String
    let icon: String
    let iconColor: Color
    let channels: [IPTVChannel]
    let onSelect: (IPTVChannel) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                if !icon.isEmpty {
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                        .font(.body)
                }
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 24)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(channels) { channel in
                        Button(action: {
                            onSelect(channel)
                        }) {
                            LiveChannelCardView(channel: channel)
                        }
                        .buttonStyle(PressScaleButtonStyle())
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

// MARK: - Premium Channel Card View
struct LiveChannelCardView: View {
    let channel: IPTVChannel
    @State private var epg = MockEPGInfo(currentShow: "Loading...", nextShow: "", progress: 0.0)
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        let w: CGFloat = horizontalSizeClass == .regular ? 240 : 160
        let h: CGFloat = horizontalSizeClass == .regular ? 135 : 90
        
        VStack(spacing: 0) {
            // Backdrop / Logo Area
            ZStack(alignment: .topTrailing) {
                Color.white.opacity(0.03)
                
                if let logoUrl = channel.logoUrl {
                    AsyncImage(url: logoUrl) { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .padding(20)
                    } placeholder: {
                        Image(systemName: "tv").font(.title).foregroundColor(.white.opacity(0.1))
                    }
                } else {
                    Image(systemName: "tv").font(.title).foregroundColor(.white.opacity(0.1))
                }
                
                // Live indicator
                Circle()
                    .fill(Color.red)
                    .frame(width: 6, height: 6)
                    .padding(10)
            }
            .frame(width: w, height: h)
            
            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color.white.opacity(0.1))
                    Rectangle().fill(Color.red).frame(width: geo.size.width * epg.progress)
                }
            }
            .frame(height: 3)
            
            // Metadata Area
            VStack(alignment: .leading, spacing: 4) {
                Text(channel.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(epg.currentShow)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .padding(12)
            .frame(width: w, alignment: .leading)
            .background(Color.white.opacity(0.02))
        }
        .premiumCardStyle()
        .onAppear {
            epg = getMockEPG(for: channel.name)
        }
    }
}

// MARK: - Legacy / Required Helper Types
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
