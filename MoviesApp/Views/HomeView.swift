//
//  HomeView.swift
//  MoviesApp
//

import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @State private var detailNavigationPath = NavigationPath()
    @State private var selectedPlayableItem: UnifiedMediaItem?
    
    var body: some View {
        NavigationStack(path: $detailNavigationPath) {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header title / log
                    HStack {
                        Text("IPTV PRO")
                            .font(.title)
                            .fontWeight(.black)
                            .foregroundColor(.accentColor)
                        Spacer()
                    }
                    .padding()
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // 1. Featured Banner
                            if let featured = viewModel.featuredItem {
                                IPTVHeroHeaderView(item: featured) {
                                    UserDataManager.shared.addToHistory(featured)
                                    selectedPlayableItem = featured
                                }
                            }
                            
                            // 2. Continue Watching / Recently Watched
                            if !viewModel.continueWatching.isEmpty {
                                UnifiedMediaListView(
                                    header: "Continue Watching",
                                    items: viewModel.continueWatching,
                                    onSelect: { item in
                                        UserDataManager.shared.addToHistory(item)
                                        selectedPlayableItem = item
                                    }
                                )
                            }
                            
                            // 3. Live Categories (Horizontal badges)
                            if !viewModel.liveCategories.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Live Categories")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            ForEach(viewModel.liveCategories.prefix(15)) { category in
                                                Text(category.name)
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                                    .padding(.horizontal, 14)
                                                    .padding(.vertical, 8)
                                                    .background(Color.gray.opacity(0.3))
                                                    .foregroundColor(.white)
                                                    .cornerRadius(15)
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                            
                            // 4. Movies Carousel
                            if !viewModel.moviesCarousel.isEmpty {
                                UnifiedMediaListView(
                                    header: "Featured Movies",
                                    items: viewModel.moviesCarousel,
                                    onSelect: { item in
                                        UserDataManager.shared.addToHistory(item)
                                        selectedPlayableItem = item
                                    }
                                )
                            }
                            
                            // 5. Series Carousel
                            if !viewModel.seriesCarousel.isEmpty {
                                UnifiedMediaListView(
                                    header: "Featured Series",
                                    items: viewModel.seriesCarousel,
                                    onSelect: { item in
                                        detailNavigationPath.append(item)
                                    }
                                )
                            }
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .task {
                await viewModel.refreshContent()
            }
            .navigationDestination(for: UnifiedMediaItem.self) { item in
                if item.mediaType == .tvSeries {
                    SeriesDetailView(series: item)
                } else if item.mediaType == .movie, let url = item.streamUrl {
                    StreamingPlayerView(url: url, title: item.title)
                }
            }
            .fullScreenCover(item: $selectedPlayableItem) { item in
                if let url = item.streamUrl {
                    StreamingPlayerView(url: url, title: item.title)
                } else {
                    ContentUnavailableView("Cannot Play", systemImage: "play.slash", description: Text("No streamable link found for this item."))
                }
            }
        }
    }
}

struct IPTVHeroHeaderView: View {
    let item: UnifiedMediaItem
    let onPlay: () -> Void
    
    var body: some View {
        ZStack(alignment: .bottom) {
            AsyncImage(url: URL(string: item.posterPath ?? "")) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 350)
                    .clipped()
                    .overlay {
                        LinearGradient(
                            stops: [
                                Gradient.Stop(color: .clear, location: 0.5),
                                Gradient.Stop(color: .black, location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 350)
            }
            
            VStack(spacing: 16) {
                Text(item.title)
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .shadow(radius: 10)
                
                HStack(spacing: 20) {
                    Button(action: onPlay) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Play")
                                .fontWeight(.bold)
                        }
                        .padding(.horizontal, 30)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(4)
                    }
                }
            }
            .padding(.bottom, 20)
        }
    }
}
