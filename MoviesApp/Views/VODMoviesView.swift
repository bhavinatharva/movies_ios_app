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
                            LazyVStack(spacing: 24) {
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
                                }
                                
                                // 3. Quick Filters (chips)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(viewModel.categories) { category in
                                            Button(action: {
                                                viewModel.selectCategory(category)
                                            }) {
                                                Text(category.name)
                                                    .font(.subheadline)
                                                    .fontWeight(.bold)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 8)
                                                    .background(viewModel.selectedCategory?.id == category.id ? Color.accentColor : Color.appCardBackground)
                                                    .foregroundColor(viewModel.selectedCategory?.id == category.id ? .white : .primary)
                                                    .cornerRadius(20)
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                                .padding(.vertical, 8)
                                
                                if viewModel.searchText.isEmpty {
                                    // 4. Trending Movies
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
                                    
                                    // 5. New Releases
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
                                    
                                    // 6. Recommended
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
                                    
                                    // 7. Top Rated
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
                                }
                                
                                // 8. Grid Browse Section
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(viewModel.selectedCategory?.name ?? "Browse Movies")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal)
                                    
                                    if viewModel.isLoadingMovies {
                                        ProgressView("Loading movies...")
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 24)
                                    } else {
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
                    ContentUnavailableView("Cannot Play", systemImage: "play.slash", description: Text("No playable link found for this movie."))
                }
            }
        }
    }
}
