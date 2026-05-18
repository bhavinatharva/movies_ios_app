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
                                LiveMiniPlayerView(
                                    channel: activeChannel,
                                    selectedFullScreenChannel: $viewModel.selectedChannelForFullScreen
                                )
                                .padding(.horizontal, 16)
                            }
                            
                            // 2. Favorites Channels Section
                            LiveFavoritesListView(
                                favorites: viewModel.favorites,
                                activeMiniPlayerChannel: $viewModel.activeChannelForMiniPlayer
                            )
                            
                            // 3. Recently Watched Section
                            LiveRecentlyWatchedListView(
                                recentlyWatched: viewModel.recentlyWatched,
                                activeMiniPlayerChannel: $viewModel.activeChannelForMiniPlayer
                            )
                            
                            // 4. Trending Live Channels Section
                            LiveTrendingListView(
                                trendingChannels: viewModel.trendingChannels,
                                activeMiniPlayerChannel: $viewModel.activeChannelForMiniPlayer
                            )
                            
                            // 5. Category Filters Section (Horizontal Chips)
                            LiveCategoryFiltersView(
                                categories: viewModel.categories,
                                selectedCategory: $viewModel.selectedCategory,
                                onSelect: { category in
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                        viewModel.selectCategory(category)
                                    }
                                }
                            )
                            
                            // 6. Main Channel List with EPG
                            LiveMainChannelListView(
                                filteredChannels: viewModel.filteredChannels,
                                activeMiniPlayerChannel: $viewModel.activeChannelForMiniPlayer
                            )
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
            .onAppear {
                viewModel.updateUserData()
            }
            .onChange(of: UserDataManager.shared.favorites) { _, _ in
                viewModel.updateUserData()
            }
            .onChange(of: UserDataManager.shared.recentlyWatched) { _, _ in
                viewModel.updateUserData()
            }
        }
    }
    
    private var emptyPlaylistView: some View {
        ContentUnavailableView {
            Label("No Playlist Loaded", systemImage: "tv.slash")
        } description: {
            Text("Go to the Settings tab to add your IPTV M3U Playlist URL and start watching.")
        }
    }
}
