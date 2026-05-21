//
//  UnifiedMediaDetailView.swift
//  MoviesApp
//

import SwiftUI

struct UnifiedMediaDetailView: View {
    let item: UnifiedMediaItem
    @State private var isPlaying = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Hero Backdrop
                    ZStack(alignment: .bottomLeading) {
                        let imageUrl = item.backdropPath ?? item.posterPath ?? ""
                        if let url = URL(string: imageUrl), !imageUrl.isEmpty {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 450)
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
                                case .failure(_), .empty:
                                    fallbackHero
                                @unknown default:
                                    fallbackHero
                                }
                            }
                        } else {
                            fallbackHero
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(item.title)
                                .font(.system(size: 32, weight: .black))
                                .foregroundColor(.white)
                                .shadow(radius: 4)
                            
                            HStack(spacing: 12) {
                                if item.isAdult {
                                    Text("18+")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .padding(4)
                                        .background(Color.red)
                                        .cornerRadius(2)
                                }
                                
                                if let releaseDate = item.releaseDate, !releaseDate.isEmpty {
                                    Text(releaseDate)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                if let runtime = item.runtime {
                                    Text("\(runtime) min")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                if let rating = item.voteAverage {
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
                    if let genres = item.genres, !genres.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(genres, id: \.self) { genre in
                                    Text(genre.uppercased())
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.appCardBackground)
                                        .cornerRadius(20)
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    // Action Buttons
                    HStack(spacing: 16) {
                        Button(action: {
                            UserDataManager.shared.addToHistory(item)
                            isPlaying = true
                        }) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Play \(item.mediaType == .tvSeries ? "Series" : "Movie")")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .buttonStyle(PressScaleButtonStyle())
                    }
                    .padding(.horizontal, 20)
                    
                    // Overview
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Overview")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(item.overview ?? "No description available.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Mock Trailer Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Trailer")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 20)
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.appCardBackground)
                                .frame(height: 200)
                            
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white.opacity(0.8))
                            
                            VStack {
                                Spacer()
                                HStack {
                                    Text("Official Trailer")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    Spacer()
                                }
                                .padding()
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 10)
                    
                    // Mock Cast & Crew Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Cast & Crew")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 20)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(1...5, id: \.self) { index in
                                    VStack {
                                        Circle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 70, height: 70)
                                            .overlay(
                                                Image(systemName: "person.fill")
                                                    .foregroundColor(.white.opacity(0.5))
                                                    .font(.title)
                                            )
                                        
                                        Text("Actor \(index)")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                        
                                        Text("Character")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                    .frame(width: 80)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 10)
                    
                    Spacer(minLength: 40)
                }
            }
            .ignoresSafeArea(edges: .top)
            
            // Custom Dismiss Button
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white.opacity(0.7))
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 50) // Adjust for safe area
                }
                Spacer()
            }
        }
        .fullScreenCover(isPresented: $isPlaying) {
            if let url = item.streamUrl {
                StreamingPlayerView(url: url, title: item.title, streamId: item.id)
            } else {
                ContentUnavailableView("Stream Unavailable", systemImage: "play.slash", description: Text("No playable link found for this item."))
            }
        }
    }
    
    private var fallbackHero: some View {
        ZStack {
            LinearGradient(
                colors: [Color.accentColor.opacity(0.2), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 450)
            
            Image(systemName: "film.fill")
                .font(.system(size: 80))
                .foregroundColor(.white.opacity(0.1))
        }
    }
}
