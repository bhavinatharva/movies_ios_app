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
    @State private var isPlaying = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            switch viewModel.status {
            case .notstarted, .loading:
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
            case .success:
                if let movie = viewModel.movieDetail {
                    detailContent(movie: movie)
                }
            case .error(let error):
                ContentUnavailableView("Connection Error", systemImage: "wifi.exclamationmark", description: Text(error.localizedDescription))
                    .foregroundColor(.white)
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
                    // Hero Backdrop or Player
                    ZStack(alignment: .topTrailing) {
                        if isPlaying, !viewModel.videoIds.isEmpty {
                            YoutubePlayer(videoIds: viewModel.videoIds, showControls: true)
                                .frame(width: geo.size.width, height: geo.size.width / 1.77)
                                .overlay(alignment: .topTrailing) {
                                    Button(action: { isPlaying = false }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.title)
                                            .foregroundColor(.white.opacity(0.7))
                                            .padding()
                                    }
                                }
                        } else {
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
                                                    Gradient.Stop(color: .black, location: 1.0)
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
                        }
                    }
                    .frame(height: isPlaying ? geo.size.width / 1.77 : 450)
                    .animation(.spring(), value: isPlaying)
                    
                    // Genres
                    if let genres = movie.genres {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(genres) { genre in
                                    Text(genre.name)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.gray.opacity(0.3))
                                        .cornerRadius(20)
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    // Action Buttons
                    HStack(spacing: 16) {
                        Button(action: {
                            if !viewModel.videoIds.isEmpty {
                                isPlaying.toggle()
                            }
                        }) {
                            HStack {
                                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                Text(isPlaying ? "Pause" : "Play")
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
                            .foregroundColor(.white)
                        
                        Text(movie.overview ?? "No description available.")
                            .font(.body)
                            .foregroundColor(.gray)
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
            }
            .ignoresSafeArea(edges: .top)
        }
    }
}

#Preview {
    MovieDetailView(title: TrendingModel.previeTitles[0])
}
