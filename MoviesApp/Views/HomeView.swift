//
//  HomeView.swift
//  MoviesApp
//

import SwiftUI

struct HomeView: View {
    @AppStorage("has_default_playlist") private var hasDefaultPlaylist = false
    @State private var viewModel = HomeViewModel()
    @State private var detailNavigationPath = NavigationPath()
    @State private var selectedPlayableItem: UnifiedMediaItem?
    
    var body: some View {
        NavigationStack(path: $detailNavigationPath) {
            ZStack {
                Color.black.ignoresSafeArea()
                
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
            .task {
                if hasDefaultPlaylist {
                    await viewModel.refreshContent()
                }
            }
            .fullScreenCover(item: $selectedPlayableItem) { item in
                if let url = item.streamUrl {
                    StreamingPlayerView(url: url, title: item.title)
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
            VStack(spacing: 24) {
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
            .padding(.bottom, 20)
        }
    }
}

struct IPTVHeroHeaderView: View {
    let item: UnifiedMediaItem
    let onPlay: () -> Void
    
    var body: some View {
        ZStack(alignment: .bottom) {
            AsyncImage(url: URL(string: item.posterPath ?? "")) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 350)
                    .clipped()
                    .overlay {
                        LinearGradient(
                            stops: [
                                Gradient.Stop(color: .clear, location: 0.5),
                                Gradient.Stop(color: .black, location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 350)
            }
            
            VStack(spacing: 16) {
                Text(item.title)
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .shadow(radius: 10)
                
                HStack(spacing: 20) {
                    Button(action: onPlay) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Play")
                                .fontWeight(.bold)
                        }
                        .padding(.horizontal, 30)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(4)
                    }
                }
            }
            .padding(.bottom, 20)
        }
    }
}
