//
//  VODMoviesView.swift

//

import SwiftUI

struct VODMoviesView: View {
    @Bindable private var dataManager = IPTVDataManager.shared
    @State private var selectedCategory: XtreamCategory?
    @State private var selectedMovie: UnifiedMediaItem?
    
    private enum ActiveSheet: Identifiable {
        case categoryFilter
        case settings
        case search
        
        var id: Int { hashValue }
    }
    @State private var activeSheet: ActiveSheet?
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    private var gridColumns: [GridItem] {
        if horizontalSizeClass == .regular {
            return [GridItem(.adaptive(minimum: 160, maximum: 220), spacing: 20)]
        } else {
            return [GridItem(.adaptive(minimum: 110), spacing: 16)]
        }
    }
    
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
                        if horizontalSizeClass == .regular {
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
            .navigationTitle(selectedCategory?.name ?? Constants.StringConstants.tabMovies)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                trailingToolbarItems
            }
            .task {
                // Data is loaded globally by IPTVDataManager, no need to fetch here
            }
            .navigationDestination(item: $selectedMovie) { movie in
                UnifiedMediaDetailView(item: movie)
            }
            .fullScreenCover(item: $activeSheet) { sheet in
                switch sheet {
                case .categoryFilter:
                    CategoryFilterView(
                        categories: dataManager.vodCategories,
                        selectedCategory: selectedCategory,
                        onSelect: { category in
                            selectedCategory = category
                        }
                    )
                case .settings:
                    SettingsView()
                case .search:
                    SearchView()
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
                        Text("All / Featured")
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
                .buttonStyle(PlainButtonStyle())
                
                ForEach(dataManager.vodCategories) { cat in
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            selectedCategory = cat
                        }
                    }) {
                        HStack {
                            Text(cat.name)
                                .font(.system(size: 14, weight: selectedCategory?.id == cat.id ? .bold : .medium))
                                .foregroundColor(selectedCategory?.id == cat.id ? .white : .gray)
                                .lineLimit(1)
                            Spacer()
                            if selectedCategory?.id == cat.id {
                                Image(systemName: "checkmark")
                                    .font(.caption.bold())
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(selectedCategory?.id == cat.id ? Color.accentColor.opacity(0.15) : Color.clear)
                        .cornerRadius(8)
                        .padding(.horizontal, 8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.bottom, 20)
        }
    }
    
    @ViewBuilder
    private var skeletonView: some View {
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
    
    @ViewBuilder
    private var contentView: some View {
        ScrollView {
            if let category = selectedCategory {
                LazyVGrid(columns: gridColumns, spacing: horizontalSizeClass == .regular ? 20 : 16) {
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
                .padding(.horizontal, horizontalSizeClass == .regular ? 24 : 16)
                .padding(.top, 16)
                .padding(.bottom, 30)
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
            // 2. Continue Watching (Movies only)
            let continueWatching = UserDataManager.shared.recentlyWatched.filter { $0.mediaType == .movie }
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
            Button {
                activeSheet = .search
            } label: {
                Image(systemName: "magnifyingglass")
            }
            Button {
                activeSheet = .settings
            } label: {
                Image(systemName: "gearshape.fill")
            }
            if horizontalSizeClass != .regular {
                categoryMenu
            }
        }
    }
    
    @ViewBuilder
    private var categoryMenu: some View {
        Button {
            activeSheet = .categoryFilter
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
