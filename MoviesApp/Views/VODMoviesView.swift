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
                        // Category Horizontal Bar
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
                            .padding(.vertical, 8)
                        }
                        
                        if viewModel.isLoadingMovies {
                            Spacer()
                            ProgressView("Loading Movies...")
                            Spacer()
                        } else {
                            ScrollView {
                                LazyVGrid(columns: columns, spacing: 16) {
                                    ForEach(viewModel.filteredMovies) { movie in
                                        UnifiedMediaCardView(item: movie, width: nil)
                                            .onTapGesture {
                                                UserDataManager.shared.addToHistory(movie)
                                                selectedMovie = movie
                                            }
                                    }
                                }
                                .padding()
                            }
                        }
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
