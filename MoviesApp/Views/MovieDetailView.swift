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
    var titleName : String  {
        return (title.name ?? title.title) ?? ""
    }
    @Environment(\.modelContext) var modelContext
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            GeometryReader { geo in
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Hero Backdrop
                        ZStack(alignment: .bottomLeading) {
                            AsyncImage(url: URL(string: title.posterPath ?? "")) { image in
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
                                Color.gray.opacity(0.1)
                                    .frame(height: 450)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(titleName)
                                    .font(.system(size: 32, weight: .black))
                                    .foregroundColor(.white)
                                
                                HStack {
                                    if title.adult == true {
                                        Text("18+")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .padding(4)
                                            .background(Color.red)
                                            .cornerRadius(2)
                                    }
                                    
                                    Text(title.release_date ?? "")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(20)
                        }
                        
                        // Action Buttons
                        HStack(spacing: 16) {
                            Button(action: {}) {
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
                                let saveTitle = title
                                saveTitle.title = titleName
                                modelContext.insert(saveTitle)
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
                            Text("Overview")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text(title.overview ?? "No description available.")
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
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    MovieDetailView(title: TrendingModel.previeTitles[0])
}
