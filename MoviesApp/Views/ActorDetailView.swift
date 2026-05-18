//
//  ActorDetailView.swift
//  MoviesApp
//
//  Created by Antigravity on 13/05/26.
//

import SwiftUI

struct ActorDetailView: View {
    let actor: ActorModel
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            GeometryReader { geo in
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Hero Profile Image
                        ZStack(alignment: .bottomLeading) {
                            AsyncImage(url: URL(string: actor.profilePath ?? "")) { image in
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
                                Text(actor.name ?? "Unknown Actor")
                                    .font(.system(size: 32, weight: .black))
                                    .foregroundColor(.white)
                                
                                HStack {
                                    Text(actor.knownForDepartment ?? "Acting")
                                        .font(.headline)
                                        .foregroundColor(.accentColor)
                                    
                                    if actor.adult == true {
                                        Text("18+")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .padding(4)
                                            .background(Color.red)
                                            .cornerRadius(2)
                                    }
                                }
                            }
                            .padding(20)
                        }
                        
                        // Known For Section
                        if let movies = actor.knownFor, !movies.isEmpty {
                            VStack(alignment: .leading, spacing: 15) {
                                Text("Known For")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 20)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 15) {
                                        ForEach(movies) { movie in
                                            NavigationLink(destination: MovieDetailView(title: movie)) {
                                                MovieCardView(movie: movie)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                        }
                        
                        // Additional Info
                        VStack(alignment: .leading, spacing: 12) {
                            Text("About")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("Popularity: \(String(format: "%.1f", 0.0))") // Replace with real popularity if added to model
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    }
                }
                .ignoresSafeArea(edges: .top)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ActorDetailView(actor: ActorModel.previeTitles[0])
}
