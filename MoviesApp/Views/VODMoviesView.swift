//
//  VODMoviesView.swift

//

import SwiftUI

struct VODMoviesView: View {
    @Bindable private var dataManager = IPTVDataManager.shared
    @State private var selectedCategory: XtreamCategory?
    @State private var selectedMovie: UnifiedMediaItem?
    @State private var showingCategoryFilter = false
    
    private let columns = [
        GridItem(.adaptive(minimum: 110), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if dataManager.homeStatus == .loading {
                        skeletonView
                    } else if case .error(let underlyingError) = dataManager.homeStatus {
                        ContentUnavailableView("Error", systemImage: "exclamationmark.triangle", description: Text(underlyingError.localizedDescription))
                    } else {
                        contentView
                    }
                }
            }
            .navigationTitle(selectedCategory?.name ?? Constants.StringConstants.tabMovies)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                trailingToolbarItems
            }
            .task {
                // Data is loaded globally by IPTVDataManager, no need to fetch here
            }
            .navigationDestination(item: $selectedMovie) { movie in
                UnifiedMediaDetailView(item: movie)
            }
            .sheet(isPresented: $showingCategoryFilter) {
                CategoryFilterView(
                    categories: dataManager.vodCategories,
                    selectedCategory: selectedCategory,
                    onSelect: { category in
                        selectedCategory = category
                    }
                )
            }
        }
    }
    
    @ViewBuilder
    private var skeletonView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Skeleton Hero Header
                Rectangle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 450)
                    .shimmer()
                
                // Skeleton Rails
                ForEach(0..<3, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: 12) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: 140, height: 20)
                            .padding(.horizontal, 16)
                            .shimmer()
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(0..<4, id: \.self) { _ in
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.1))
                                        .frame(width: 140, height: 210)
                                        .shimmer()
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
            }
            .padding(.bottom, 40)
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        ScrollView {
            if let category = selectedCategory {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 16)], spacing: 16) {
                    ForEach(dataManager.categorizedMovies[category.id] ?? []) { movie in
                        GeometryReader { geo in
                            UnifiedMediaCardView(item: movie, width: geo.size.width)
                                .onTapGesture {
                                    UserDataManager.shared.addToHistory(movie)
                                    selectedMovie = movie
                                }
                        }
                        .aspectRatio(2/3, contentMode: .fit)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            } else {
                homeRailsView
            }
        }
        .ignoresSafeArea(edges: selectedCategory == nil ? .top : .init())
    }
    
    @ViewBuilder
    private var homeRailsView: some View {
        LazyVStack(spacing: 28) {
            // 1. Hero Featured Movie
            if let hero = dataManager.heroMovie {
                IPTVHeroHeaderView(item: hero) {
                    UserDataManager.shared.addToHistory(hero)
                    selectedMovie = hero
                }
            }
            // 2. Continue Watching
            let continueWatching = UserDataManager.shared.recentlyWatched.filter { $0.mediaType != .tvSeries }
            if !continueWatching.isEmpty {
                UnifiedMediaListView(
                    header: "Continue Watching",
                    items: continueWatching,
                    onSelect: { item in
                        UserDataManager.shared.addToHistory(item)
                        selectedMovie = item
                    }
                )
            }
            
            // 3. Trending Movies
            if !dataManager.trendingMovies.isEmpty {
                UnifiedMediaListView(
                    header: "Trending Movies",
                    items: dataManager.trendingMovies,
                    onSelect: { item in
                        UserDataManager.shared.addToHistory(item)
                        selectedMovie = item
                    }
                )
            }
            
            // 4. New Releases
            if !dataManager.newReleases.isEmpty {
                UnifiedMediaListView(
                    header: "New Releases",
                    items: dataManager.newReleases,
                    onSelect: { item in
                        UserDataManager.shared.addToHistory(item)
                        selectedMovie = item
                    }
                )
            }
            
            // 5. Recommended
            if !dataManager.recommendedMovies.isEmpty {
                UnifiedMediaListView(
                    header: "Recommended For You",
                    items: dataManager.recommendedMovies,
                    onSelect: { item in
                        UserDataManager.shared.addToHistory(item)
                        selectedMovie = item
                    }
                )
            }
            
            // 6. Top Rated
            if !dataManager.topRatedMovies.isEmpty {
                UnifiedMediaListView(
                    header: "Top Rated Movies",
                    items: dataManager.topRatedMovies,
                    onSelect: { item in
                        UserDataManager.shared.addToHistory(item)
                        selectedMovie = item
                    }
                )
            }
            
            // 7. Vertical Genre Sections with Horizontal Sliders
            ForEach(dataManager.vodCategories.prefix(15)) { cat in
                VODGenreRowView(category: cat, dataManager: dataManager) { movie in
                    UserDataManager.shared.addToHistory(movie)
                    selectedMovie = movie
                }
            }
        }
        .padding(.bottom, 30) // Clear custom tab bar
    }
    
    @ToolbarContentBuilder
    private var trailingToolbarItems: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            NavigationLink(destination: SearchView()) {
                Image(systemName: "magnifyingglass")
            }
            categoryMenu
        }
    }
    
    @ViewBuilder
    private var categoryMenu: some View {
        Button {
            showingCategoryFilter = true
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
        }
    }
}

// MARK: - Lazy Loading Genre Row View
struct VODGenreRowView: View {
    let category: XtreamCategory
    var dataManager: IPTVDataManager
    let onSelect: (UnifiedMediaItem) -> Void
    
    var body: some View {
        Group {
            if let items = dataManager.categorizedMovies[category.id], !items.isEmpty {
                UnifiedMediaListView(
                    header: category.name,
                    items: items,
                    onSelect: onSelect
                )
            }
        }
    }
}
