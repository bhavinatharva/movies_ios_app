//
//  HomeView.swift
//  MoviesApp
//

import SwiftUI

struct HomeView: View {
    @AppStorage("has_default_playlist") private var hasDefaultPlaylist = false
    @AppStorage("active_playlist_url") private var activePlaylistUrl = ""
    @State private var viewModel = HomeViewModel()
    @State private var detailNavigationPath = NavigationPath()
    @State private var selectedPlayableItem: UnifiedMediaItem?
    
    var body: some View {
        NavigationStack(path: $detailNavigationPath) {
            ZStack {
                // Premium dark theatrical gradient background
                LinearGradient(
                    stops: [
                        .init(color: Color(red: 0.05, green: 0.05, blue: 0.07), location: 0),
                        .init(color: Color(red: 0.01, green: 0.01, blue: 0.02), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header title / logo
                    HStack {
                        Text("IPTV PLAYER")
                            .font(.title2)
                            .fontWeight(.black)
                            .foregroundColor(.accentColor)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 5)
                    
                    if !hasDefaultPlaylist {
                        emptyPlaylistView
                    } else {
                        switch viewModel.homeStatus {
                        case .notstarted, .loading:
                            if viewModel.liveChannels.isEmpty {
                                Spacer()
                                ProgressView("Loading channels...")
                                    .tint(.white)
                                    .foregroundColor(.white)
                                Spacer()
                            } else {
                                contentView
                            }
                        case .success:
                            contentView
                        case .error(let error):
                            ContentUnavailableView(
                                "Connection Error",
                                systemImage: "wifi.exclamationmark",
                                description: Text(error.localizedDescription)
                            )
                            .foregroundColor(.white)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .task(id: activePlaylistUrl) {
                if hasDefaultPlaylist {
                    await viewModel.refreshContent()
                }
            }
            .fullScreenCover(item: $selectedPlayableItem) { item in
                if let url = item.streamUrl {
                    StreamingPlayerView(url: url, title: item.title, streamId: item.id)
                } else {
                    ContentUnavailableView("Cannot Play", systemImage: "play.slash", description: Text("No streamable link found for this item."))
                }
            }
        }
    }
    
    private var emptyPlaylistView: some View {
        ContentUnavailableView {
            Label("No Playlist Loaded", systemImage: "tv.slash")
        } description: {
            Text("Go to the Settings tab to add your IPTV M3U Playlist URL and start watching.")
        }
        .foregroundColor(.white)
    }
    
    private var contentView: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                // 1. Featured Banner
                if let featured = viewModel.featuredItem {
                    IPTVHeroHeaderView(item: featured) {
                        UserDataManager.shared.addToHistory(featured)
                        selectedPlayableItem = featured
                    }
                }
                
                // 2. Continue Watching / Recently Watched
                if !viewModel.continueWatching.isEmpty {
                    UnifiedMediaListView(
                        header: "Continue Watching",
                        items: viewModel.continueWatching,
                        onSelect: { item in
                            UserDataManager.shared.addToHistory(item)
                            selectedPlayableItem = item
                        }
                    )
                }
                
                // 3. Categories Carousels
                ForEach(viewModel.categorizedChannels.keys.sorted(), id: \.self) { category in
                    if let channels = viewModel.categorizedChannels[category] {
                        UnifiedMediaListView(
                            header: category,
                            items: channels.map { $0.toUnified },
                            onSelect: { item in
                                UserDataManager.shared.addToHistory(item)
                                selectedPlayableItem = item
                            }
                        )
                    }
                }
            }
            .padding(.bottom, 30) // Extra padding to clear custom tab bar
        }
    }
}

struct IPTVHeroHeaderView: View {
    let item: UnifiedMediaItem
    let onPlay: () -> Void
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Header Backdrop Art
            AsyncImage(url: URL(string: item.posterPath ?? "")) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(height: 380)
                    .clipped()
                    .overlay {
                        // Double-layer premium theatrical vignette gradients
                        LinearGradient(
                            stops: [
                                .init(color: .black.opacity(0.6), location: 0),
                                .init(color: .clear, location: 0.3),
                                .init(color: .clear, location: 0.65),
                                .init(color: .black, location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
            } placeholder: {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 380)
                    .shimmer()
            }
            
            // Text & Control Overlay
            VStack(spacing: 14) {
                // Floating category tag
                if let category = item.genres?.first {
                    Text(category.uppercased())
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundColor(.accentColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .glassBackground(cornerRadius: 12)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                
                Text(item.title)
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.55) // Automatically scale font down up to 55% to fit without cutting!
                    .padding(.horizontal, 24)
                    .shadow(color: .black.opacity(0.8), radius: 8, x: 0, y: 4)
                
                // Play Action Trigger
                Button(action: {
                    // Visual haptic pop
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    onPlay()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "play.fill")
                            .font(.body)
                        Text("Stream Now")
                            .fontWeight(.black)
                    }
                    .font(.system(size: 15, design: .rounded))
                    .padding(.horizontal, 34)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .foregroundColor(.black)
                    .cornerRadius(28)
                    .shadow(color: .white.opacity(0.25), radius: 10, x: 0, y: 5)
                }
                .buttonStyle(PressScaleButtonStyle())
            }
            .padding(.bottom, 28)
        }
        .frame(height: 380)
        .cornerRadius(24)
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .shadow(color: .black.opacity(0.5), radius: 15, x: 0, y: 10)
    }
}
