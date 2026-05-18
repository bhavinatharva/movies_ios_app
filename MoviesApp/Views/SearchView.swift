//
//  SearchView.swift
//  MoviesApp
//
//  Created by Bhavin Parghi on 12/11/25.
//

import SwiftUI

struct SearchView: View {
    @State private var searchByMovies = true
    @State private var searchText = ""
    @State private var searchViewModel = SearchViewModel()
    @State private var navigationPath = NavigationPath()
    @State private var selectedPlayableItem: UnifiedMediaItem? = nil
    
    private var isIPTVActive: Bool {
        IPTVDataManager.shared.homeStatus == .success && !IPTVDataManager.shared.availableTabs.isEmpty
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                ScrollView {
                    if let error = searchViewModel.errorMessage {
                        ContentUnavailableView("Search Error", systemImage: "exclamationmark.magnifyingglass", description: Text(error))
                    } else if isIPTVActive && searchText.isEmpty {
                        // Empty/Start state description for IPTV search
                        ContentUnavailableView {
                            Label("Search IPTV Content", systemImage: "magnifyingglass")
                        } description: {
                            Text("Find Live TV channels, VOD movies, and series from your M3U playlist instantly.")
                        }
                        .padding(.top, 60)
                    } else if isIPTVActive && searchViewModel.iptvResults.isEmpty && !searchText.isEmpty {
                        ContentUnavailableView {
                            Label("No Matches Found", systemImage: "magnifyingglass")
                        } description: {
                            Text("No Live TV, Movies, or Series matching '\(searchText)' in your loaded playlist.")
                        }
                        .padding(.top, 60)
                    } else {
                        // Render Grid View
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                            if isIPTVActive {
                                ForEach(searchViewModel.iptvResults) { item in
                                    UnifiedMediaCardView(item: item, width: nil)
                                        .onTapGesture {
                                            let generator = UIImpactFeedbackGenerator(style: .medium)
                                            generator.impactOccurred()
                                            selectedPlayableItem = item
                                        }
                                }
                            } else {
                                ForEach(searchViewModel.searchingMovies) { title in
                                    MovieCardView(movie: title, width: nil)
                                        .onTapGesture {
                                            navigationPath.append(title)
                                        }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    }
                }
            }
            .navigationTitle(isIPTVActive ? "Search IPTV" : (searchByMovies ? Constants.StringConstants.movieSearch : Constants.StringConstants.tvSearch))
            .toolbar {
                if !isIPTVActive {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            searchByMovies.toggle()
                            Task {
                                await searchViewModel.getSearchMovies(for: searchByMovies ? "movie" : "tv", searchPhase: searchText)
                            }
                        } label: {
                            Image(systemName: searchByMovies ? Constants.ImageConstants.movie : Constants.ImageConstants.tv)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: Constants.StringConstants.search)
            .task(id: searchText) {
                try? await Task.sleep(for: .milliseconds(300))
                
                if Task.isCancelled {
                    return
                }
                
                if isIPTVActive {
                    await searchViewModel.getSearchIPTV(searchPhase: searchText)
                } else {
                    await searchViewModel.getSearchMovies(for: searchByMovies ? "movie" : "tv", searchPhase: searchText)
                }
            }
            .navigationDestination(for: TrendingModel.self) { trendingModel in
                MovieDetailView(title: trendingModel)
            }
            .fullScreenCover(item: $selectedPlayableItem) { item in
                if let url = item.streamUrl {
                    StreamingPlayerView(url: url, title: item.title, streamId: item.id)
                } else {
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
            }
        }
    }
}

#Preview {
    SearchView()
}
