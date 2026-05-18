//
//  MovieDetailView.swift
//  MoviesApp
//
//  Created by Bhavin Parghi on 12/11/25.
//

import SwiftUI
import SwiftData

struct MovieDetailView: View {
    
    let title : TrendingModel
    @State private var viewModel = MovieDetailViewModel()
    @Environment(\.modelContext) var modelContext
    @State private var selectedVideo: VideoModel? = nil
    
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
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if let id = title.id {
                await viewModel.getMovieDetail(id: id)
            }
        }
    }
    
    @ViewBuilder
    private func detailContent(movie: MovieDetailModel) -> some View {
        GeometryReader { geo in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Hero Backdrop
                    ZStack(alignment: .bottomLeading) {
                        AsyncImage(url: URL(string: Constants.ImageConstants.posterPathStart + (movie.backdropPath ?? movie.posterPath ?? ""))) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: geo.size.width, height: 450)
                                .clipped()
                                .overlay {
                                    LinearGradient(
                                        stops: [
                                            Gradient.Stop(color: .clear, location: 0.6),
                                            Gradient.Stop(color: Color.appBackground, location: 1.0)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                }
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 0)
                                .fill(Color.gray.opacity(0.1))
                                .frame(height: 450)
                                .shimmer()
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(movie.title ?? "")
                                .font(.system(size: 32, weight: .black))
                                .foregroundColor(.white)
                            
                            HStack(spacing: 12) {
                                if movie.adult == true {
                                    Text("18+")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .padding(4)
                                        .background(Color.red)
                                        .cornerRadius(2)
                                }
                                
                                Text(movie.releaseDate ?? "")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                if let runtime = movie.runtime {
                                    Text("\(runtime) min")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                if let rating = movie.voteAverage {
                                    HStack(spacing: 4) {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                        Text(String(format: "%.1f", rating))
                                            .foregroundColor(.white)
                                    }
                                    .font(.caption)
                                }
                            }
                        }
                        .padding(20)
                    }
                    .frame(height: 450)
                    
                    // Genres
                    if let genres = movie.genres {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(genres) { genre in
                                    Text(genre.name)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.appCardBackground)
                                        .cornerRadius(20)
                                        .foregroundColor(.primary)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    // Action Buttons
                    HStack(spacing: 16) {
                        Button(action: {
                            if let firstVideo = viewModel.videos.first {
                                selectedVideo = firstVideo
                            }
                        }) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Play")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(4)
                        }
                        
                        Button(action: {
                            modelContext.insert(title)
                            try? modelContext.save()
                        }) {
                            HStack {
                                Image(systemName: "arrow.down.to.line")
                                Text("Download")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.gray.opacity(0.3))
                            .foregroundColor(.white)
                            .cornerRadius(4)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Video List Section
                    if !viewModel.videos.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Videos & Trailers")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 20)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(viewModel.videos) { video in
                                        VideoCardView(video: video)
                                            .onTapGesture {
                                                selectedVideo = video
                                            }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.top, 10)
                    }
                    
                    // Overview
                    VStack(alignment: .leading, spacing: 12) {
                        if let tagline = movie.tagline, !tagline.isEmpty {
                            Text(tagline)
                                .font(.headline)
                                .italic()
                                .foregroundColor(.accentColor)
                        }
                        
                        Text("Overview")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(movie.overview ?? "No description available.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, 20)
                    
                    // More Like This (Mock data for UI)
                    MovieHorizontalListView(
                        header: "More Like This",
                        movies: TrendingModel.previeTitles.shuffled(),
                        onSelect: { _ in }
                    )
                    .padding(.top, 20)
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
}
