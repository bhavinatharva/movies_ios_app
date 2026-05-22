//
//  MovieDetailView.swift
//  MoviesApp
//

import SwiftUI
import SwiftData

struct MovieDetailView: View {
    
    let title: TrendingModel
    @State private var viewModel = MovieDetailViewModel()
    @Environment(\.modelContext) var modelContext
    @State private var selectedVideo: VideoModel? = nil
    @State private var selectedPlayableItem: UnifiedMediaItem? = nil
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            switch viewModel.status {
            case .notstarted, .loading:
                ProgressView()
                    .scaleEffect(1.5)
            case .success:
                if let movie = viewModel.movieDetail {
                    detailContent(movie: movie)
                }
            case .error(let error):
                ContentUnavailableView("Connection Error", systemImage: "wifi.exclamationmark", description: Text(error.localizedDescription))
            }
        }
        .navigationBarHidden(true)
        .task {
            if let id = title.id {
                await viewModel.getMovieDetail(id: id)
            }
        }
    }
    
    @ViewBuilder
    private func detailContent(movie: MovieDetailModel) -> some View {
        GeometryReader { geo in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    // 1. Cinematic Hero Header
                    MovieHeroHeader(movie: movie, geometry: geo)
                    
                    VStack(alignment: .leading, spacing: 32) {
                        // 2. Metadata Chips
                        MovieMetadataChips(movie: movie)
                            .padding(.top, 16)
                        
                        // 3. Action Buttons
                        MovieActionButtons(
                            onPlayTapped: {
                                if let playableMovie = iptvPlayableMovie(movie: movie) {
                                    UserDataManager.shared.addToHistory(playableMovie)
                                    selectedPlayableItem = playableMovie
                                } else {
                                    // Fallback to playing trailer if no IPTV movie is found
                                    if let firstVideo = viewModel.videos.first {
                                        selectedVideo = firstVideo
                                    }
                                }
                            },
                            onTrailerTapped: {
                                if let firstVideo = viewModel.videos.first {
                                    selectedVideo = firstVideo
                                }
                            },
                            hasTrailer: !viewModel.videos.isEmpty
                        )
                        
                        // 4. Expandable Overview
                        MovieOverviewSection(movie: movie)
                        
                        // 5. Related Content Rail (Mocking with Shuffled data to show intent)
                        MovieRelatedContentRail(
                            title: "More Like This",
                            items: TrendingModel.previeTitles.shuffled(),
                            onSelect: { selectedItem in
                                // Navigation to next detail view is usually handled by wrapping in NavigationLink, 
                                // but for now we'll just print or implement if needed.
                                print("Selected: \(selectedItem.title ?? "")")
                            }
                        )
                        
                        // Optional: Videos and Trailers Rail
                        if !viewModel.videos.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Trailers & Extras")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    LazyHStack(spacing: 16) {
                                        ForEach(viewModel.videos) { video in
                                            VideoCardView(video: video)
                                                .onTapGesture {
                                                    selectedVideo = video
                                                }
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
            .ignoresSafeArea(edges: .top)
            .fullScreenCover(item: $selectedVideo) { video in
                ZStack(alignment: .topTrailing) {
                    Color.black.ignoresSafeArea()
                    
                    if let key = video.key {
                        YoutubePlayer(videoIds: [key], showControls: true)
                            .aspectRatio(1.77, contentMode: .fit)
                    }
                    
                    Button(action: { selectedVideo = nil }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white.opacity(0.7))
                            .padding()
                    }
                }
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
                            Text("No playable link found for this movie.")
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
            
            // Custom Back Button
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Circle().fill(Color.black.opacity(0.4)))
                    }
                    .padding(.leading, 20)
                    .padding(.top, 50)
                    Spacer()
                }
                Spacer()
            }
        }
    }
    
    private func iptvPlayableMovie(movie: MovieDetailModel) -> UnifiedMediaItem? {
        let movieTitle = (movie.title ?? title.title ?? title.name ?? "").lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if movieTitle.isEmpty { return nil }
        
        return IPTVDataManager.shared.movies.first { item in
            let itemTitle = item.title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            return itemTitle == movieTitle || movieTitle.contains(itemTitle) || itemTitle.contains(movieTitle)
        }
    }
}

struct MovieDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MovieDetailView(title: TrendingModel.previeTitles[0])
                .modelContainer(for: TrendingModel.self, inMemory: true)
        }
    }
}
