//
//  VODMoviesView.swift
//  MoviesApp
//

import SwiftUI

struct VODMoviesView: View {
    @State private var viewModel = VODMoviesViewModel()
    @State private var selectedMovie: UnifiedMediaItem?
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search movies...", text: $viewModel.searchText)
                            .foregroundColor(.primary)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    .padding(10)
                    .background(Color.appCardBackground)
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView("Loading Categories...")
                        Spacer()
                    } else if let error = viewModel.errorMessage {
                        ContentUnavailableView("Error", systemImage: "exclamationmark.triangle", description: Text(error))
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 28) {
                                if viewModel.searchText.isEmpty {
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
                                    ForEach(viewModel.categories) { category in
                                        VODGenreRowView(category: category, viewModel: viewModel) { movie in
                                            UserDataManager.shared.addToHistory(movie)
                                            selectedMovie = movie
                                        }
                                    }
                                } else {
                                    // Search results grid view
                                    VStack(alignment: .leading, spacing: 16) {
                                        Text("Search Results")
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .padding(.horizontal)
                                        
                                        LazyVGrid(columns: columns, spacing: 16) {
                                            ForEach(viewModel.filteredMovies) { movie in
                                                UnifiedMediaCardView(item: movie, width: nil)
                                                    .onTapGesture {
                                                        UserDataManager.shared.addToHistory(movie)
                                                        selectedMovie = movie
                                                    }
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                    .padding(.top, 12)
                                }
                            }
                            .padding(.bottom, 30) // Clear custom tab bar
                        }
                        .ignoresSafeArea(edges: .top)
                    }
                }
            }
            .navigationTitle(Constants.StringConstants.tabMovies)
            .navigationBarTitleDisplayMode(.inline)
            .task {
                if viewModel.categories.isEmpty {
                    await viewModel.loadCategories()
                }
            }
            .fullScreenCover(item: $selectedMovie) { movie in
                if let streamUrl = movie.streamUrl {
                    StreamingPlayerView(url: streamUrl, title: movie.title, streamId: movie.id)
                } else {
                    ZStack(alignment: .topTrailing) {
                        Color.appBackground.ignoresSafeArea()
                        
                        ContentUnavailableView {
                            Label("Cannot Play", systemImage: "play.slash")
                        } description: {
                            Text("No playable link found for this movie.")
                                .foregroundColor(.secondary)
                        } actions: {
                            Button(action: {
                                selectedMovie = nil
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
                            selectedMovie = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.white.opacity(0.6))
                                .padding()
                        }
                    }
                }
            }
        }
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
                                    .fill(Color.appCardBackground)
                                    .frame(width: 140, height: 186.6)
                                    .overlay(
                                        ProgressView()
                                            .tint(.gray)
                                    )
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
