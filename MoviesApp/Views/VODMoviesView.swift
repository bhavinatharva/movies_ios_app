//
//  VODMoviesView.swift
//  MoviesApp
//

import SwiftUI

struct VODMoviesView: View {
    @State private var viewModel = VODMoviesViewModel()
    @State private var selectedMovie: UnifiedMediaItem?
    
    private let columns = [
        GridItem(.adaptive(minimum: 110), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if viewModel.isLoading {
                        skeletonView
                    } else if let error = viewModel.errorMessage {
                        ContentUnavailableView("Error", systemImage: "exclamationmark.triangle", description: Text(error))
                    } else {
                        contentView
                    }
                }
            }
            .navigationTitle(viewModel.selectedCategory?.categoryName ?? Constants.StringConstants.tabMovies)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SearchView()) {
                        Image(systemName: "magnifyingglass")
                    }
                    
                    Menu {
                        Button("All (Home)") {
                            viewModel.selectedCategory = nil
                        }
                        
                        ForEach(viewModel.categories, id: \.id) { category in
                            Button(category.categoryName ?? category.id) {
                                viewModel.selectedCategory = category
                                Task {
                                    await viewModel.loadMoviesIfNeeded(for: category.id)
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .task {
                if viewModel.categories.isEmpty {
                    await viewModel.loadCategories()
                }
            }
            .fullScreenCover(item: $selectedMovie) { movie in
                UnifiedMediaDetailView(item: movie)
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
            if let category = viewModel.selectedCategory {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 16)], spacing: 16) {
                    ForEach(viewModel.moviesByGenre[category.id] ?? []) { movie in
                        GeometryReader { geo in
                            UnifiedMediaCardView(item: movie, width: geo.size.width)
                                .onTapGesture {
                                    UserDataManager.shared.addToHistory(movie)
                                    selectedMovie = movie
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
        .ignoresSafeArea(edges: viewModel.selectedCategory == nil ? .top : .init())
    }
    
    @ViewBuilder
    private var homeRailsView: some View {
        LazyVStack(spacing: 28) {
            // 1. Hero Featured Movie
            if let hero = viewModel.heroMovie {
                IPTVHeroHeaderView(item: hero) {
                    UserDataManager.shared.addToHistory(hero)
                    selectedMovie = hero
                }
            }
            // 2. Continue Watching
            if !viewModel.continueWatching.isEmpty {
                UnifiedMediaListView(
                    header: "Continue Watching",
                    items: viewModel.continueWatching,
                    onSelect: { item in
                        UserDataManager.shared.addToHistory(item)
                        selectedMovie = item
                    }
                )
            }
            
            // 3. Trending Movies
            if !viewModel.trendingMovies.isEmpty {
                UnifiedMediaListView(
                    header: "Trending Movies",
                    items: viewModel.trendingMovies,
                    onSelect: { item in
                        UserDataManager.shared.addToHistory(item)
                        selectedMovie = item
                    }
                )
            }
            
            // 4. New Releases
            if !viewModel.newReleases.isEmpty {
                UnifiedMediaListView(
                    header: "New Releases",
                    items: viewModel.newReleases,
                    onSelect: { item in
                        UserDataManager.shared.addToHistory(item)
                        selectedMovie = item
                    }
                )
            }
            
            // 5. Recommended
            if !viewModel.recommended.isEmpty {
                UnifiedMediaListView(
                    header: "Recommended For You",
                    items: viewModel.recommended,
                    onSelect: { item in
                        UserDataManager.shared.addToHistory(item)
                        selectedMovie = item
                    }
                )
            }
            
            // 6. Top Rated
            if !viewModel.topRated.isEmpty {
                UnifiedMediaListView(
                    header: "Top Rated Movies",
                    items: viewModel.topRated,
                    onSelect: { item in
                        UserDataManager.shared.addToHistory(item)
                        selectedMovie = item
                    }
                )
            }
            
            // 7. Vertical Genre Sections with Horizontal Sliders
            ForEach(viewModel.categories) { cat in
                VODGenreRowView(category: cat, viewModel: viewModel) { movie in
                    UserDataManager.shared.addToHistory(movie)
                    selectedMovie = movie
                }
            }
        }
        .padding(.bottom, 30) // Clear custom tab bar
    }
}

// MARK: - Lazy Loading Genre Row View
struct VODGenreRowView: View {
    let category: XtreamCategory
    var viewModel: VODMoviesViewModel
    let onSelect: (UnifiedMediaItem) -> Void
    
    var body: some View {
        Group {
            if let items = viewModel.moviesByGenre[category.id] {
                if !items.isEmpty {
                    UnifiedMediaListView(
                        header: category.name,
                        items: items,
                        onSelect: onSelect
                    )
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text(category.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(0..<4, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.15))
                                    .frame(width: 140, height: 186.6)
                                    .shimmer()
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .task {
                    await viewModel.loadMoviesIfNeeded(for: category.id)
                }
            }
        }
    }
}
