//
//  MovieHeroHeaderView.swift
//  MoviesApp
//
//  Created by Antigravity on 13/05/26.
//

import SwiftUI

struct MovieHeroHeaderView: View {
    let movie: TrendingModel
    let onPlay: () -> Void
    let onAddToList: () -> Void
    
    var body: some View {
        ZStack(alignment: .bottom) {
            AsyncImage(url: URL(string: movie.posterPath ?? "")) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 550)
                    .clipped()
                    .overlay {
                        LinearGradient(
                            stops: [
                                Gradient.Stop(color: .clear, location: 0.5),
                                Gradient.Stop(color: Color.appBackground, location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 550)
                    .shimmer()
            }
            
            VStack(spacing: 16) {
                Text(movie.title ?? movie.name ?? "")
                    .font(.system(size: 36, weight: .black))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .shadow(radius: 10)
                
                HStack(spacing: 20) {
                    Button(action: onPlay) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text(Constants.StringConstants.btnPlay)
                                .fontWeight(.bold)
                        }
                        .padding(.horizontal, 30)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(4)
                    }
                    
                    Button(action: onAddToList) {
                        HStack {
                            Image(systemName: "plus")
                            Text("My List")
                                .fontWeight(.bold)
                        }
                        .padding(.horizontal, 30)
                        .padding(.vertical, 10)
                        .background(Color.gray.opacity(0.4))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                    }
                }
            }
            .padding(.bottom, 50)
        }
    }
}
