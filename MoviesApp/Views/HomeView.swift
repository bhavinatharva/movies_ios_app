//
//  HomeView.swift

//

import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("has_default_playlist") private var hasDefaultPlaylist = false
    @AppStorage("active_playlist_url") private var activePlaylistUrl = ""
    @State private var userDataManager = UserDataManager.shared
    @State private var viewModel = HomeViewModel()
    @State private var detailNavigationPath = NavigationPath()
    @State private var selectedPlayableItem: UnifiedMediaItem?
    @State private var selectedMovieForDetail: UnifiedMediaItem?
    @State private var selectedCollectionForDetail: MovieCollection?
    
    var body: some View {
        NavigationStack(path: $detailNavigationPath) {
            ZStack {
                // Dynamic Premium theatrical background
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
                    VStack(spacing: 0) {
                        headerView
                        emptyPlaylistView
                    }
                } else {
                    ZStack(alignment: .top) {
                        switch viewModel.homeStatus {
                        case .notstarted, .loading:
                            if viewModel.liveChannels.isEmpty {
                                VStack {
                                    Spacer()
                                    ProgressView("Loading...")
                                        .controlSize(.large)
                                        .tint(.accentColor)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                
                                headerView
                            } else {
                                contentView
                                headerView
                            }
                        case .success:
                            contentView
                            headerView
                        case .error(let error):
                            VStack(spacing: 0) {
                                headerView
                                ContentUnavailableView(
                                    "Connection Error",
                                    systemImage: "wifi.exclamationmark",
                                    description: Text(error.localizedDescription)
                                )
                            }
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
            .onAppear {
                viewModel.updateFavorites()
            }
            .onChange(of: UserDataManager.shared.favorites) { _, _ in
                viewModel.updateFavorites()
            }
            .background(
                EmptyView()
                    .fullScreenCover(item: $selectedMovieForDetail) { item in
                        UnifiedMediaDetailView(item: item)
                    }
            )
            .background(
                EmptyView()
                    .fullScreenCover(item: $selectedCollectionForDetail) { collection in
                        MovieCollectionDetailView(collection: collection) { movie in
                            selectedCollectionForDetail = nil
                            // Delay slightly to allow the collection cover to dismiss before showing movie detail
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                selectedMovieForDetail = movie
                            }
                        }
                    }
            )
            .background(
                EmptyView()
                    .fullScreenCover(item: $selectedPlayableItem) { _ in
                        ZStack(alignment: .topTrailing) {
                            Color.appBackground.ignoresSafeArea()
                            
                            ContentUnavailableView {
                                Label("Cannot Play", systemImage: "play.slash")
                            } description: {
                                Text("No streamable link found for this item.")
                                    .foregroundColor(.secondary)
                            } actions: {
                                Button(action: {
                                    selectedPlayableItem = nil
                                }) {
                                    Text("Close")
                                        .fontWeight(.bold)
                                        .frame(width: 120, height: 44)
                                        .background(Color.accentColor)
                                        .foregroundColor(.white)
                                        .cornerRadius(22)
                                }
                                .buttonStyle(PressScaleButtonStyle())
                            }
                            
                            Button(action: {
                                selectedPlayableItem = nil
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.white.opacity(0.6))
                                    .padding()
                            }
                        }
                    }
            )
        }
    }
    
    private var headerView: some View {
        HStack(spacing: 20) {
            Text("IPTV")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundColor(.accentColor)
            
            Spacer()
            
            HStack(spacing: 20) {
                NavigationLink(destination: SearchView()) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                if PlaylistManager.shared.fetchDefaultPlaylist()?.userConsentedAdult == true {
                    NavigationLink(destination: AdultView()) {
                        Text("Adult(18+)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 16)
        .background(
            LinearGradient(
                colors: [.black.opacity(0.85), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private func handleMediaSelection(_ item: UnifiedMediaItem) {
        if item.mediaType == .movie || item.mediaType == .tvSeries {
            selectedMovieForDetail = item
        } else {
            UserDataManager.shared.addToHistory(item)
            if let url = item.streamUrl {
                GlobalPlayerManager.shared.play(
                    url: url,
                    title: item.title,
                    artwork: item.posterPath,
                    isLive: item.mediaType == .liveTV,
                    streamId: item.id
                )
            } else {
                selectedPlayableItem = item
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
    
    private var contentView: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                // 1. Featured Banner
                if let featured = viewModel.featuredItem {
                    IPTVHeroHeaderView(item: featured) {
                        handleMediaSelection(featured)
                    }
                }
                
                // 2. Continue Watching
                if !viewModel.continueWatching.isEmpty {
                    UnifiedMediaListView(
                        header: "Continue Watching",
                        items: viewModel.continueWatching,
                        onSelect: handleMediaSelection
                    )
                }
                
                // 3. Live Channels
                if !viewModel.liveChannels.isEmpty {
                    UnifiedMediaListView(
                        header: "Live Channels",
                        items: Array(viewModel.liveChannels.prefix(15)).map { $0.toUnified },
                        onSelect: handleMediaSelection
                    )
                }
                
                // 4.5. Movie Collections
                if !viewModel.movieCollections.isEmpty {
                    MovieCollectionListView(
                        header: "Movie Collections",
                        collections: viewModel.movieCollections,
                        onSelect: { collection in
                            selectedCollectionForDetail = collection
                        }
                    )
                }
                
                // 5. Top 10
                if !viewModel.top10Movies.isEmpty {
                    UnifiedMediaListView(
                        header: "Top 10 Movies",
                        items: viewModel.top10Movies,
                        onSelect: handleMediaSelection
                    )
                }
                
                // 6. Recently Added
                if !viewModel.recentlyAdded.isEmpty {
                    UnifiedMediaListView(
                        header: "Recently Added",
                        items: viewModel.recentlyAdded,
                        onSelect: handleMediaSelection
                    )
                }
                
                // 7. Sports Live Now
                if !viewModel.sportsLiveNow.isEmpty {
                    UnifiedMediaListView(
                        header: "Sports Live Now",
                        items: viewModel.sportsLiveNow,
                        onSelect: handleMediaSelection
                    )
                }
                
                // 8. Recommended For You
                if !viewModel.recommended.isEmpty {
                    UnifiedMediaListView(
                        header: "Recommended For You",
                        items: viewModel.recommended,
                        onSelect: handleMediaSelection
                    )
                }
                
                // 9. Series Continue Watching
                if !viewModel.seriesContinueWatching.isEmpty {
                    UnifiedMediaListView(
                        header: "Series Continue Watching",
                        items: viewModel.seriesContinueWatching,
                        onSelect: handleMediaSelection
                    )
                }
                
                // 10. Favorites
                if !viewModel.favorites.isEmpty {
                    UnifiedMediaListView(
                        header: "My Favorites",
                        items: viewModel.favorites,
                        onSelect: handleMediaSelection
                    )
                }
                
                // 11. Uncategorized
                if !viewModel.uncategorized.isEmpty {
                    UnifiedMediaListView(
                        header: "Uncategorized",
                        items: viewModel.uncategorized,
                        onSelect: handleMediaSelection
                    )
                }
                
                // 12. Genres / Categories
                ForEach(Array(viewModel.categorizedChannels.keys.sorted().prefix(15)), id: \.self) { category in
                    let catLower = category.lowercased()
                    if catLower != "sports" && catLower != "sport" { // Avoid duplicate sports sections
                        HomeCategoryRowView(category: category, viewModel: viewModel, selectedPlayableItem: $selectedPlayableItem)
                    }
                }
            }
            .padding(.bottom, 30) // Extra padding to clear custom tab bar
        }
        .ignoresSafeArea(edges: .top)
    }
}

// MARK: - Lazy Loading Home Category Row View
struct HomeCategoryRowView: View {
    let category: String
    var viewModel: HomeViewModel
    @Binding var selectedPlayableItem: UnifiedMediaItem?
    
    var body: some View {
        Group {
            if let channels = viewModel.categorizedChannels[category], !channels.isEmpty {
                UnifiedMediaListView(
                    header: category,
                    // Limit to 20 items and map only when this view is rendered
                    items: channels.prefix(20).map { $0.toUnified },
                    onSelect: { item in
                        UserDataManager.shared.addToHistory(item)
                        if let url = item.streamUrl {
                            GlobalPlayerManager.shared.play(
                                url: url,
                                title: item.title,
                                artwork: item.posterPath,
                                isLive: item.mediaType == .liveTV,
                                streamId: item.id
                            )
                        } else {
                            selectedPlayableItem = item
                        }
                    }
                )
            }
        }
    }
}

struct IPTVHeroHeaderView: View {
    let item: UnifiedMediaItem
    let onPlay: () -> Void
    
    private var fallbackHeroBackground: some View {
        ZStack {
            LinearGradient(
                colors: [Color.accentColor.opacity(0.15), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 500)
            
            Image(systemName: "popcorn.fill")
                .font(.system(size: 80))
                .foregroundColor(.white.opacity(0.1))
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Header Backdrop Art
            if let posterPath = item.posterPath, !posterPath.isEmpty, let url = URL(string: posterPath) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(height: 500)
                            .clipped()
                            .overlay {
                                // Double-layer premium theatrical vignette gradients
                                LinearGradient(
                                    stops: [
                                        .init(color: .black.opacity(0.75), location: 0),
                                        .init(color: .clear, location: 0.3),
                                        .init(color: .clear, location: 0.6),
                                        .init(color: Color.appBackground, location: 1.0)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            }
                    case .failure, .empty:
                        fallbackHeroBackground
                    @unknown default:
                        fallbackHeroBackground
                    }
                }
            } else {
                fallbackHeroBackground
            }
            
            // Text & Control Overlay
            VStack(spacing: 16) {
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
                
            }
            .padding(.bottom, 24)
        }
        .frame(height: 500)
    }
}
