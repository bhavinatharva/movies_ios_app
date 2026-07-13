//
//  LiveTVView.swift
//  MoviesApp
//

import SwiftUI

struct LiveTVView: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("has_default_playlist") private var hasDefaultPlaylist = false
    @AppStorage("active_playlist_url") private var activePlaylistUrl = ""
    @State private var viewModel = LiveTVViewModel()
    @State private var selectedSegment: LiveSegment = .channels
    @State private var selectedCategory: String?
    
    // For navigation to detail
    @State private var selectedChannelForDetail: IPTVChannel?
    
    enum LiveSegment: String, CaseIterable {
        case channels = "Channels"
        case tvGuide = "TV Guide"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                if !hasDefaultPlaylist {
                    emptyPlaylistView
                } else {
                    VStack(spacing: 0) {
                        // Floating Segmented Picker
                        VStack {
                            Picker("Live View", selection: $selectedSegment) {
                                ForEach(LiveSegment.allCases, id: \.self) { segment in
                                    Text(segment.rawValue).tag(segment)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .padding(.top, 8)
                            .zIndex(1)
                        }
                        
                        if selectedSegment == .tvGuide {
                            EPGTimelineView()
                        } else {
                            if viewModel.isLoading {
                                Spacer()
                                ProgressView("Loading Live TV...")
                                Spacer()
                            } else if let error = viewModel.errorMessage {
                                Spacer()
                                ContentUnavailableView("Error", systemImage: "exclamationmark.triangle", description: Text(error))
                                Spacer()
                            } else {
                                ZStack {
                                    if viewModel.searchQuery.isEmpty {
                                        AdaptiveCategoryLayout(
                                            categories: viewModel.groupedChannels.map { $0.category },
                                            selectedCategory: $selectedCategory
                                        ) {
                                            ScrollView {
                                                LazyVStack(spacing: 32) {
                                                    
                                                    if selectedCategory == nil {
                                                        // 1. Hero Live Channel Section
                                                        if let hero = viewModel.heroChannel {
                                                            LiveTVHeroHeaderView(channel: hero) {
                                                                selectedChannelForDetail = hero
                                                            }
                                                        }
                                                        
                                                        // 2. Favorites Rail
                                                        if !viewModel.favorites.isEmpty {
                                                            LiveChannelHorizontalRowView(
                                                                title: "Favorites Channels",
                                                                icon: "star.fill",
                                                                iconColor: .yellow,
                                                                channels: viewModel.favorites
                                                            ) { channel in
                                                                selectedChannelForDetail = channel
                                                            }
                                                        }
                                                        
                                                        // 3. Recently Watched
                                                        if !viewModel.recentlyWatched.isEmpty {
                                                            LiveChannelHorizontalRowView(
                                                                title: "Recently Watched",
                                                                icon: "clock.arrow.circlepath",
                                                                iconColor: .accentColor,
                                                                channels: viewModel.recentlyWatched
                                                            ) { channel in
                                                                selectedChannelForDetail = channel
                                                            }
                                                        }
                                                    }
                                                    
                                                    // 4. Filtered Category Rails or Grid
                                                    let filteredGroups = selectedCategory == nil ? viewModel.groupedChannels : viewModel.groupedChannels.filter { $0.category == selectedCategory }
                                                    
                                                    ForEach(filteredGroups, id: \.category) { group in
                                                        if selectedCategory == nil {
                                                            // Horizontal Rail when showing all
                                                            LiveChannelHorizontalRowView(
                                                                title: group.category,
                                                                icon: "tv",
                                                                iconColor: .primary,
                                                                channels: group.channels
                                                            ) { channel in
                                                                selectedChannelForDetail = channel
                                                            }
                                                        } else {
                                                            // Vertical Grid when a specific category is selected
                                                            VStack(alignment: .leading, spacing: 16) {
                                                                Text(group.category)
                                                                    .font(.title2)
                                                                    .fontWeight(.bold)
                                                                    .foregroundColor(.white)
                                                                    .padding(.horizontal)
                                                                
                                                                let columns = [GridItem(.adaptive(minimum: 150), spacing: 16)]
                                                                LazyVGrid(columns: columns, spacing: 16) {
                                                                    ForEach(group.channels) { channel in
                                                                        LiveChannelCardView(channel: channel)
                                                                            .onTapGesture {
                                                                                selectedChannelForDetail = channel
                                                                            }
                                                                    }
                                                                }
                                                                .padding(.horizontal)
                                                            }
                                                        }
                                                    }
                                                }
                                                .padding(.bottom, 40)
                                            }
                                        }
                                    } else {
                                        // Search Results Grid
                                        ScrollView {
                                            if viewModel.filteredChannels.isEmpty {
                                                ContentUnavailableView.search(text: viewModel.searchQuery)
                                            } else {
                                                VStack(alignment: .leading, spacing: 16) {
                                                    Text("Search Results")
                                                        .font(.title3)
                                                        .fontWeight(.bold)
                                                        .foregroundColor(.white)
                                                        .padding(.horizontal)
                                                    
                                                    let columns = [GridItem(.adaptive(minimum: 150), spacing: 16)]
                                                    LazyVGrid(columns: columns, spacing: 16) {
                                                        ForEach(viewModel.filteredChannels) { channel in
                                                            LiveChannelCardView(channel: channel)
                                                                .onTapGesture {
                                                                    selectedChannelForDetail = channel
                                                                }
                                                        }
                                                    }
                                                    .padding(.horizontal)
                                                }
                                                .padding(.top, 16)
                                            }
                                        }
                                    }
                                }
                                .searchable(text: $viewModel.searchQuery, prompt: "Search live channels...")
                                .onChange(of: viewModel.searchQuery) { _, _ in
                                    viewModel.filterChannels()
                                }
                            }
                        }
                    }
                }
            }
            .task(id: activePlaylistUrl) {
                if hasDefaultPlaylist {
                    await viewModel.loadData()
                }
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
            .fullScreenCover(item: $selectedChannelForDetail) { channel in
                LiveTVDetailView(channel: channel)
            }
            .fullScreenCover(item: $viewModel.selectedChannelForFullScreen) { channel in
                StreamingPlayerView(url: channel.streamUrl, title: channel.name)
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
