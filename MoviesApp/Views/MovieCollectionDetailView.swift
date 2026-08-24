//
//  MovieCollectionDetailView.swift
//  MoviesApp
//
//  Created by Antigravity on 21/05/26.
//

import SwiftUI

struct MovieCollectionDetailView: View {
    let collection: MovieCollection
    let onMovieSelect: (UnifiedMediaItem) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header Banner
                ZStack(alignment: .bottomLeading) {
                    if let posterUrlString = collection.posterPath, !posterUrlString.isEmpty, let url = URL(string: posterUrlString) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 350)
                                    .clipped()
                            case .failure, .empty:
                                fallbackHeader
                            @unknown default:
                                fallbackHeader
                            }
                        }
                    } else {
                        fallbackHeader
                    }
                    
                    // Premium theatrical gradient
                    LinearGradient(
                        stops: [
                            .init(color: .black.opacity(0.7), location: 0),
                            .init(color: .clear, location: 0.3),
                            .init(color: .clear, location: 0.6),
                            .init(color: Color.appBackground, location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 350)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        if let year = collection.yearRange {
                            Text(year)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.accentColor)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .glassBackground(cornerRadius: 8)
                        }
                        
                        Text(collection.title)
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 4, x: 0, y: 2)
                        
                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Image(systemName: "film")
                                Text("\(collection.movieCount) Movies")
                            }
                            
                            if !collection.genres.isEmpty {
                                Text("•")
                                Text(collection.genres.prefix(2).joined(separator: ", "))
                            }
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(20)
                }
                
                // Grid of movies
                let columns = [
                    GridItem(.adaptive(minimum: 110), spacing: 16)
                ]
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(collection.movies) { movie in
                        Button(action: {
                            onMovieSelect(movie)
                        }) {
                            GeometryReader { geo in
                                UnifiedMediaCardView(item: movie, width: geo.size.width)
                            }
                            .aspectRatio(3/4, contentMode: .fit)
                        }
                        .buttonStyle(PressScaleButtonStyle())
                    }
                }
                .padding(20)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .overlay(alignment: .topLeading) {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.black.opacity(0.4))
                    .clipShape(Circle())
            }
            .buttonStyle(PressScaleButtonStyle())
            .padding(.top, 50)
            .padding(.leading, 20)
        }
        .ignoresSafeArea(edges: .top)
    }
    
    private var fallbackHeader: some View {
        ZStack {
            LinearGradient(
                colors: [Color.accentColor.opacity(0.2), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 350)
            
            Image(systemName: "film.stack.fill")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.2))
        }
    }
}
