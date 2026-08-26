//
//  LiveTVView.swift
//

import SwiftUI

struct LiveTVView: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("has_default_playlist") private var hasDefaultPlaylist = false
    @AppStorage("active_playlist_url") private var activePlaylistUrl = ""
    @Bindable private var dataManager = IPTVDataManager.shared
    
    // Split View State
    @State private var selectedCategory: String? = "All"
    @State private var selectedChannelForDetail: IPTVChannel?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var searchQuery: String = ""
    
    var categories: [String] {
        ["All"] + dataManager.categorizedChannels.keys.sorted()
    }
    
    var filteredChannels: [IPTVChannel] {
        let cat = selectedCategory ?? "All"
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        var result = cat == "All" ? dataManager.liveChannels : (dataManager.categorizedChannels[cat] ?? [])
        if !query.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(query) }
        }
        return result
    }
    
    var body: some View {
        if !hasDefaultPlaylist {
            emptyPlaylistView
        } else if dataManager.homeStatus == .loading || dataManager.homeStatus == .notstarted {
            loadingSkeletonView
        } else if case .error(let error) = dataManager.homeStatus {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ContentUnavailableView("Error", systemImage: "exclamationmark.triangle", description: Text(error.localizedDescription))
            }
        } else {
            NavigationSplitView(columnVisibility: $columnVisibility) {
                // Sidebar: Categories
                List(selection: $selectedCategory) {
                    ForEach(categories, id: \.self) { category in
                        NavigationLink(value: category) {
                            Text(category)
                                .font(.headline)
                        }
                    }
                }
                .navigationTitle("Live TV")
            } content: {
                // Content: Channels List
                LiveChannelListView(
                    filteredChannels: filteredChannels,
                    selectedChannelForDetail: $selectedChannelForDetail
                )
                .background(Color.appBackground.ignoresSafeArea())
                .navigationTitle(selectedCategory ?? "All Channels")
                .navigationBarTitleDisplayMode(.inline)
                .searchable(text: $searchQuery, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search channels...")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink(destination: SettingsView()) {
                            Image(systemName: "gearshape.fill")
                        }
                    }
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
            .onAppear {
                if selectedChannelForDetail == nil {
                    selectedChannelForDetail = dataManager.liveChannels.first
                }
            }
        }
    }
    
    private var loadingSkeletonView: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack {
                Spacer()
                ProgressView("Loading...")
                    .controlSize(.large)
                    .tint(.accentColor)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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

// MARK: - Extracted Channel List View to prevent parent re-evaluations
struct LiveChannelListView: View {
    let filteredChannels: [IPTVChannel]
    @Binding var selectedChannelForDetail: IPTVChannel?
    
    // We only need the search query environment value if we wanted to show it in the unavailable view
    @Environment(\.isSearching) private var isSearching
    
    var body: some View {
        ScrollView {
            if filteredChannels.isEmpty {
                ContentUnavailableView("No Channels Found", systemImage: "tv.slash")
                    .padding(.top, 40)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(filteredChannels) { channel in
                        Button(action: {
                            selectedChannelForDetail = channel
                        }) {
                            LiveChannelCardView(
                                channel: channel,
                                isSelected: selectedChannelForDetail?.id == channel.id
                            )
                        }
                        .buttonStyle(PressScaleButtonStyle())
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
}
