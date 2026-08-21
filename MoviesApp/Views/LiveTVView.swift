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
    
    // Split View State
    @State private var selectedCategory: String? = "All"
    @State private var selectedChannelForDetail: IPTVChannel?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    var body: some View {
        if !hasDefaultPlaylist {
            emptyPlaylistView
        } else if viewModel.isLoading {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ProgressView("Loading Live TV...")
            }
            .task(id: activePlaylistUrl) {
                if hasDefaultPlaylist { await viewModel.loadData() }
            }
        } else if let error = viewModel.errorMessage {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ContentUnavailableView("Error", systemImage: "exclamationmark.triangle", description: Text(error))
            }
        } else {
            NavigationSplitView(columnVisibility: $columnVisibility) {
                // Sidebar: Categories
                List(selection: $selectedCategory) {
                    ForEach(viewModel.categories, id: \.self) { category in
                        NavigationLink(value: category) {
                            Text(category)
                                .font(.headline)
                        }
                    }
                }
                .navigationTitle("Live TV")
                .onChange(of: selectedCategory) { _, newCat in
                    if let cat = newCat {
                        viewModel.selectCategory(cat)
                    }
                }
            } content: {
                // Content: Channels List
                List(selection: $selectedChannelForDetail) {
                    if viewModel.filteredChannels.isEmpty {
                        if !viewModel.searchQuery.isEmpty {
                            ContentUnavailableView.search(text: viewModel.searchQuery)
                        } else {
                            ContentUnavailableView("No Channels", systemImage: "tv.slash")
                        }
                    } else {
                        ForEach(viewModel.filteredChannels) { channel in
                            NavigationLink(value: channel) {
                                LiveChannelCardView(channel: channel, isSelected: selectedChannelForDetail?.id == channel.id)
                            }
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                    }
                }
                .listStyle(.plain)
                .background(Color.appBackground.ignoresSafeArea())
                .navigationTitle(selectedCategory ?? "All Channels")
                .navigationBarTitleDisplayMode(.inline)
                .searchable(text: $viewModel.searchQuery, prompt: "Search channels...")
                .onChange(of: viewModel.searchQuery) { _, _ in
                    viewModel.filterChannels()
                }
            } detail: {
                // Detail: Player + Info
                if let channel = selectedChannelForDetail {
                    LiveTVDetailView(channel: channel)
                } else {
                    ZStack {
                        Color.appBackground.ignoresSafeArea()
                        ContentUnavailableView("Select a Channel", systemImage: "tv", description: Text("Choose a channel from the list to start watching."))
                    }
                }
            }
            .task(id: activePlaylistUrl) {
                if hasDefaultPlaylist {
                    await viewModel.loadData()
                    if selectedChannelForDetail == nil {
                        selectedChannelForDetail = viewModel.heroChannel ?? viewModel.allChannels.first
                    }
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
        }
    }
    
    private var emptyPlaylistView: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            ContentUnavailableView {
                Label("No Playlist Loaded", systemImage: "tv.slash")
            } description: {
                Text("Go to the Settings tab to add your IPTV M3U Playlist URL and start watching.")
            }
        }
    }
}
