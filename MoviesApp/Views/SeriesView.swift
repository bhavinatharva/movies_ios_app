//
//  SeriesView.swift

//

import SwiftUI

struct SeriesView: View {
    @Bindable private var dataManager = IPTVDataManager.shared
    @State private var selectedCategory: XtreamCategory?
    @State private var selectedDetailSeries: UnifiedMediaItem?
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
            .navigationTitle(selectedCategory?.name ?? Constants.StringConstants.tabSeries)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                trailingToolbarItems
            }
            .navigationDestination(item: $selectedDetailSeries) { series in
                SeriesDetailView(series: series)
            }
            .task {
                // Loaded globally
            }
            .sheet(isPresented: $showingCategoryFilter) {
                CategoryFilterView(
                    categories: dataManager.seriesCategories,
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
                    ForEach(dataManager.categorizedSeries[category.id] ?? []) { series in
                        GeometryReader { geo in
                            UnifiedMediaCardView(item: series, width: geo.size.width)
                                .onTapGesture {
                                    selectedDetailSeries = series
                                }
                        }
                        .aspectRatio(3/4, contentMode: .fit)
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
            // 1. Featured Hero Series
                if let hero = dataManager.heroSeries {
                    IPTVHeroHeaderView(item: hero) {
                        selectedDetailSeries = hero
                    }
                }
                
                // 2. Continue Watching
                let continueWatching = UserDataManager.shared.recentlyWatched.filter { $0.mediaType == .tvSeries }
                if !continueWatching.isEmpty {
                    UnifiedMediaListView(
                        header: "Continue Watching",
                        items: continueWatching,
                        onSelect: { item in
                            selectedDetailSeries = item
                        }
                    )
                }
                
                // 3. Trending Series
                if !dataManager.trendingSeries.isEmpty {
                    UnifiedMediaListView(
                        header: "Trending Series",
                        items: dataManager.trendingSeries,
                        onSelect: { item in
                            selectedDetailSeries = item
                        }
                    )
                }
                
                // 4. New Releases
                if !dataManager.newReleaseSeries.isEmpty {
                    UnifiedMediaListView(
                        header: "New Releases",
                        items: dataManager.newReleaseSeries,
                        onSelect: { item in
                            selectedDetailSeries = item
                        }
                    )
                }
                
                // 5. Recommended For You
                if !dataManager.recommendedSeries.isEmpty {
                    UnifiedMediaListView(
                        header: "Recommended For You",
                        items: dataManager.recommendedSeries,
                        onSelect: { item in
                            selectedDetailSeries = item
                        }
                    )
                }
                
                // 6. Top Rated
                if !dataManager.topRatedSeries.isEmpty {
                    UnifiedMediaListView(
                        header: "Top Rated Series",
                        items: dataManager.topRatedSeries,
                        onSelect: { item in
                            selectedDetailSeries = item
                        }
                    )
                }
                
                // 7. Vertical Genre Sections with Horizontal Sliders
                ForEach(dataManager.seriesCategories.prefix(15)) { category in
                    SeriesGenreRowView(category: category, dataManager: dataManager) { series in
                        selectedDetailSeries = series
                    }
                }
        }
        .padding(.bottom, 30) // Clear tab bar space
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

// MARK: - Lazy Loading Genre Row View for Series
struct SeriesGenreRowView: View {
    let category: XtreamCategory
    var dataManager: IPTVDataManager
    let onSelect: (UnifiedMediaItem) -> Void
    
    var body: some View {
        Group {
            if let items = dataManager.categorizedSeries[category.id], !items.isEmpty {
                UnifiedMediaListView(
                    header: category.name,
                    items: items,
                    onSelect: onSelect
                )
            }
        }
    }
}
