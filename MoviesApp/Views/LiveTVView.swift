//
//  LiveTVView.swift
//

import SwiftUI

struct LiveTVView: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("has_default_playlist") private var hasDefaultPlaylist = false
    @AppStorage("active_playlist_url") private var activePlaylistUrl = ""
    @Bindable private var dataManager = IPTVDataManager.shared
    
    @State private var selectedCategory: String? = nil
    @State private var selectedChannel: IPTVChannel?
    @State private var searchQuery: String = ""
    
    private enum ActiveSheet: Identifiable {
        case categoryFilter
        case settings
        
        var id: Int { hashValue }
    }
    @State private var activeSheet: ActiveSheet?
    
    var categories: [String] {
        dataManager.categorizedChannels.keys.sorted()
    }
    
    var filteredChannels: [IPTVChannel] {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            return dataManager.liveChannels.filter { $0.name.localizedCaseInsensitiveContains(query) }
        }
        let cat = selectedCategory
        return cat == nil ? Array(dataManager.liveChannels.prefix(50)) : (dataManager.categorizedChannels[cat!] ?? [])
    }
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    private var gridColumns: [GridItem] {
        #if os(tvOS)
        return [GridItem(.adaptive(minimum: 220, maximum: 280), spacing: 28)]
        #else
        if horizontalSizeClass == .regular {
            return [GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 18)]
        } else {
            return [GridItem(.adaptive(minimum: 110), spacing: 14)]
        }
        #endif
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if !hasDefaultPlaylist {
                        emptyPlaylistView
                    } else if dataManager.homeStatus == .loading || dataManager.homeStatus == .notstarted {
                        loadingSkeletonView
                    } else if case .error(let error) = dataManager.homeStatus {
                        ContentUnavailableView("Error", systemImage: "exclamationmark.triangle", description: Text(error.localizedDescription))
                    } else {
                        if horizontalSizeClass == .regular {
                            // iPad: Native side-by-side category and channel browser
                            HStack(spacing: 0) {
                                categorySidebar
                                    .frame(width: 240)
                                    .background(Color.black.opacity(0.3))
                                    .overlay(
                                        Rectangle()
                                            .frame(width: 0.5)
                                            .foregroundColor(Color.white.opacity(0.1)),
                                        alignment: .trailing
                                    )
                                
                                contentView
                            }
                        } else {
                            contentView
                        }
                    }
                }
            }
            .navigationTitle(selectedCategory ?? "Live TV")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchQuery, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search channels...")
            #else
            .searchable(text: $searchQuery, prompt: "Search channels...")
            #endif
            .toolbar {
                trailingToolbarItems
            }
            .navigationDestination(item: $selectedChannel) { channel in
                LiveTVDetailView(channel: channel)
            }
            .fullScreenCover(item: $activeSheet) { sheet in
                switch sheet {
                case .categoryFilter:
                    LiveCategoryFilterSheet(
                        categories: categories,
                        selectedCategory: selectedCategory,
                        onSelect: { category in
                            selectedCategory = category
                        }
                    )
                case .settings:
                    SettingsView()
                }
            }
            .onAppear {
                if selectedCategory == nil {
                    selectedCategory = categories.first
                }
            }
            .onChange(of: dataManager.homeStatus) { _, status in
                if status == .success && selectedCategory == nil {
                    selectedCategory = categories.first
                }
            }
        }
    }
    
    // iPad Category Selector Sidebar
    private var categorySidebar: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                Text("CATEGORIES")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 6)
                
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        selectedCategory = nil
                    }
                }) {
                    HStack {
                        Text("All Channels")
                            .font(.system(size: 14, weight: selectedCategory == nil ? .bold : .medium))
                            .foregroundColor(selectedCategory == nil ? .white : .gray)
                        Spacer()
                        if selectedCategory == nil {
                            Image(systemName: "checkmark")
                                .font(.caption.bold())
                                .foregroundColor(.accentColor)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(selectedCategory == nil ? Color.accentColor.opacity(0.15) : Color.clear)
                    .cornerRadius(8)
                    .padding(.horizontal, 8)
                }
                #if os(tvOS)
                .buttonStyle(PressScaleButtonStyle())
                #else
                .buttonStyle(PlainButtonStyle())
                #endif
                
                ForEach(categories, id: \.self) { cat in
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            selectedCategory = cat
                        }
                    }) {
                        HStack {
                            Text(cat)
                                .font(.system(size: 14, weight: selectedCategory == cat ? .bold : .medium))
                                .foregroundColor(selectedCategory == cat ? .white : .gray)
                                .lineLimit(1)
                            Spacer()
                            if selectedCategory == cat {
                                Image(systemName: "checkmark")
                                    .font(.caption.bold())
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(selectedCategory == cat ? Color.accentColor.opacity(0.15) : Color.clear)
                        .cornerRadius(8)
                        .padding(.horizontal, 8)
                    }
                    #if os(tvOS)
                    .buttonStyle(PressScaleButtonStyle())
                    #else
                    .buttonStyle(PlainButtonStyle())
                    #endif
                }
            }
            .padding(.bottom, 20)
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Continue Watching (Live TV only)
                let continueWatching = UserDataManager.shared.recentlyWatched.filter { $0.mediaType == .liveTV }
                if !continueWatching.isEmpty {
                    UnifiedMediaListView(
                        header: "Continue Watching",
                        items: continueWatching,
                        onSelect: { item in
                            UserDataManager.shared.addToHistory(item)
                            if let url = item.streamUrl {
                                GlobalPlayerManager.shared.play(
                                    url: url,
                                    title: item.title,
                                    artwork: item.posterPath,
                                    isLive: true,
                                    streamId: item.id
                                )
                            }
                        }
                    )
                    .padding(.top, 12)
                }

                // Channel grid
                if filteredChannels.isEmpty {
                    ContentUnavailableView("No Channels Found", systemImage: "tv.slash")
                        .padding(.top, 40)
                } else {
                    LazyVGrid(columns: gridColumns, spacing: horizontalSizeClass == .regular ? 20 : 16) {
                        ForEach(filteredChannels) { channel in
                            #if os(tvOS)
                            Button {
                                selectedChannel = channel
                            } label: {
                                LiveChannelGridCardView(channel: channel)
                            }
                            .buttonStyle(.card)
                            #else
                            LiveChannelGridCardView(channel: channel)
                                .onTapGesture {
                                    selectedChannel = channel
                                }
                            #endif
                        }
                    }
                    .padding(.horizontal, horizontalSizeClass == .regular ? 24 : 16)
                    .padding(.top, 16)
                    .padding(.bottom, 30)
                }
            }
        }
    }
    
    @ToolbarContentBuilder
    private var trailingToolbarItems: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button {
                activeSheet = .settings
            } label: {
                Image(systemName: "gearshape.fill")
            }
            if horizontalSizeClass != .regular {
                Button {
                    activeSheet = .categoryFilter
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
        }
    }
    
    private var loadingSkeletonView: some View {
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
    
    private var emptyPlaylistView: some View {
        ContentUnavailableView {
            Label("No Playlist Loaded", systemImage: "tv.slash")
        } description: {
            Text("Go to the Settings tab to add your IPTV M3U Playlist URL and start watching.")
        }
    }
}

// MARK: - Filter Sheet
struct LiveCategoryFilterSheet: View {
    let categories: [String]
    let selectedCategory: String?
    let onSelect: (String?) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Button(action: {
                    onSelect(nil)
                    dismiss()
                }) {
                    HStack {
                        Text("All Channels")
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedCategory == nil {
                            Image(systemName: "checkmark").foregroundColor(.accentColor)
                        }
                    }
                }
                
                ForEach(categories, id: \.self) { category in
                    Button(action: {
                        onSelect(category)
                        dismiss()
                    }) {
                        HStack {
                            Text(category)
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedCategory == category {
                                Image(systemName: "checkmark").foregroundColor(.accentColor)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Category")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                    }
                }
            }
            #else
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                    }
                }
            }
            #endif
        }
    }
}
