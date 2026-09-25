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
    // Removed individual sheet state variables; unified ActiveSheet enum will be used instead
    
    private enum ActiveSheet: Identifiable {
        case settings
        case search
        case movieDetail(UnifiedMediaItem)
        case seriesDetail(UnifiedMediaItem)
        case collectionDetail(MovieCollection)
        case playableItem(UnifiedMediaItem)
        
        var id: UUID { UUID() }
    }
    @State private var activeSheet: ActiveSheet?
    
    var body: some View {
        NavigationStack(path: $detailNavigationPath) {
            ZStack {
                // Dynamic Premium theatrical dark gradient background
                LinearGradient(
                    stops: [
                        .init(color: Color(red: 0.06, green: 0.06, blue: 0.08), location: 0),
                        .init(color: Color(red: 0.02, green: 0.02, blue: 0.03), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
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
                                HomeShimmerView()
                                
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
            .fullScreenCover(item: $activeSheet) { sheet in
                switch sheet {
                case .settings:
                    SettingsView()
                case .search:
                    SearchView()
                case .movieDetail(let item):
                    UnifiedMediaDetailView(item: item)
                case .seriesDetail(let item):
                    SeriesDetailView(
                        series: item,
                        resumeEpisodeId: UserDataManager.shared.lastWatchedEpisode[item.id]
                    )
                case .collectionDetail(let collection):
                    MovieCollectionDetailView(collection: collection) { movie in
                        activeSheet = .movieDetail(movie)
                    }
                case .playableItem(let item):
                    ZStack(alignment: .topTrailing) {
                        Color.appBackground.ignoresSafeArea()
                        ContentUnavailableView {
                            Label("Cannot Play", systemImage: "play.slash")
                        } description: {
                            Text("No streamable link found for this item.")
                                .foregroundColor(.secondary)
                        } actions: {
                            Button(action: {
                                activeSheet = nil
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
                    }
                    
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
                    // Sheet presentations are now handled by the unified .fullScreenCover above.
                }
            }}
    }
    
    private func handleMediaSelection(_ item: UnifiedMediaItem) {
        if item.mediaType == .tvSeries {
            activeSheet = .seriesDetail(item)
        } else if item.mediaType == .movie {
            activeSheet = .movieDetail(item)
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
                    activeSheet = .playableItem(item)
                }
            }
        }
        
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    private var headerView: some View {
        HStack(spacing: 20) {
            if horizontalSizeClass != .regular {
                #if os(tvOS)
                Text("IPTV")
                    .font(.system(size: 60, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                #else
                Text("IPTV")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                #endif
                
                Spacer()
                
                Button {
                    activeSheet = .search
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Button {
                    activeSheet = .settings
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
            } else {
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, horizontalSizeClass == .regular ? 8 : 16)
        .padding(.bottom, 16)
        .background(
            LinearGradient(
                colors: [.black.opacity(horizontalSizeClass == .regular ? 0.4 : 0.85), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
        
        private var emptyPlaylistView: some View {
            VStack(spacing: 20) {
                Image(systemName: "play.square.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 120)
                    .foregroundColor(.white.opacity(0.7))
                Text("No playlist available")
                    .font(.title2)
                    .foregroundColor(.white)
                Button(action: {
                    // Create a default playlist and update state
//                    UserDataManager.shared.createDefaultPlaylist()
                    hasDefaultPlaylist = true
                }) {
                    Text("Create Default Playlist")
                        .fontWeight(.semibold)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.8))
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
                                activeSheet = .collectionDetail(collection)
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
                            HomeCategoryRowView(category: category, viewModel: viewModel, onSelect: handleMediaSelection)
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
    let onSelect: (UnifiedMediaItem) -> Void
    
    var body: some View {
        Group {
            if let channels = viewModel.categorizedChannels[category], !channels.isEmpty {
                UnifiedMediaListView(
                    header: category,
                    // Limit to 20 items and map only when this view is rendered
                    items: channels.prefix(20).map { $0.toUnified },
                    onSelect: onSelect
                )
            }
        }
    }
}

struct IPTVHeroHeaderView: View {
    let item: UnifiedMediaItem
    let onPlay: () -> Void
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    private var heroHeight: CGFloat {
        #if os(tvOS)
        800
        #else
        horizontalSizeClass == .regular ? 460 : 440
        #endif
    }
    
    private var fallbackHeroBackground: some View {
        ZStack {
            LinearGradient(
                colors: [Color.accentColor.opacity(0.2), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: heroHeight)
            
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
                            .frame(height: heroHeight)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .overlay {
                                // Multi-directional gradient vignette
                                LinearGradient(
                                    stops: [
                                        .init(color: .black.opacity(0.7), location: 0),
                                        .init(color: .clear, location: 0.3),
                                        .init(color: .clear, location: 0.55),
                                        .init(color: Color(red: 0.06, green: 0.06, blue: 0.08), location: 1.0)
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
            VStack(spacing: 12) {
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
                    #if os(tvOS)
                    .font(.system(size: 64, weight: .black, design: .rounded))
                    #else
                    .font(.system(size: horizontalSizeClass == .regular ? 36 : 28, weight: .black, design: .rounded))
                    #endif
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 32)
                    .shadow(color: .black.opacity(0.8), radius: 8, x: 0, y: 4)
                
                // Hero Action Buttons
                HStack(spacing: 14) {
                    Button(action: onPlay) {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                                #if os(tvOS)
                                .font(.system(size: 24, weight: .bold))
                                #else
                                .font(.system(size: 16, weight: .bold))
                                #endif
                            Text("Watch Now")
                                #if os(tvOS)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                #else
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                #endif
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .shadow(color: .white.opacity(0.3), radius: 8, x: 0, y: 3)
                    }
                    .buttonStyle(PressScaleButtonStyle())
                    
                    Button(action: {
                        UserDataManager.shared.toggleFavorite(id: item.id)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: UserDataManager.shared.isFavorite(id: item.id) ? "star.fill" : "star")
                                #if os(tvOS)
                                .font(.system(size: 24, weight: .bold))
                                #else
                                .font(.system(size: 15, weight: .bold))
                                #endif
                                .foregroundColor(UserDataManager.shared.isFavorite(id: item.id) ? .yellow : .white)
                            Text("Favorite")
                                #if os(tvOS)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                #else
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                #endif
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(PressScaleButtonStyle())
                }
                .padding(.top, 4)
            }
            .padding(.bottom, 28)
            .frame(height: heroHeight)
        }
    }
}
// MARK: - Home Skeleton / Shimmer Loading View
struct HomeShimmerView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    /// Base fill for large skeleton blocks (hero, cards)
    private var blockFill: Color {
        colorScheme == .dark
        ? Color.white.opacity(0.18)
        : Color(UIColor.systemGray5)
    }
    
    /// Base fill for small skeleton lines (title, subtitle)
    private var lineFill: Color {
        colorScheme == .dark
        ? Color.white.opacity(0.14)
        : Color(UIColor.systemGray4)
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                
                // Hero banner placeholder
                RoundedRectangle(cornerRadius: 0)
                    .fill(blockFill)
                    .frame(maxWidth: .infinity)
                    .frame(height: 480)
                    .shimmer()
                
                // Section 1
                shimmerSection()
                
                // Section 2
                shimmerSection()
                
                // Section 3
                shimmerSection()
            }
        }
        .ignoresSafeArea(edges: .top)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func shimmerSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section title bar
            RoundedRectangle(cornerRadius: 6)
                .fill(lineFill)
                .frame(width: 160, height: 18)
                .shimmer()
                .padding(.horizontal, 16)
            
            // Horizontal row of card skeletons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(0..<6, id: \.self) { _ in
                        VStack(alignment: .leading, spacing: 8) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(blockFill)
                                .frame(width: 120, height: 170)
                                .shimmer()
                            RoundedRectangle(cornerRadius: 4)
                                .fill(lineFill)
                                .frame(width: 100, height: 12)
                                .shimmer()
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}
