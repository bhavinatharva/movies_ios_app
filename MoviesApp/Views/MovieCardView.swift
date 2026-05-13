//
//  MovieCardView.swift
//  MoviesApp
//
//  Created by Antigravity on 13/05/26.
//

import SwiftUI

struct MovieCardView: View {
    let movie: TrendingModel
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: URL(string: movie.posterPath ?? "")) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 140, height: 210)
                    .netflixStyleGradient()
            } placeholder: {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 140, height: 210)
                    .shimmer()
            }
            .cardStyle()
            
            VStack(alignment: .leading, spacing: 2) {
                if movie.adult == true {
                    Text("18+")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                }
                
                Text(movie.title ?? movie.name ?? "Unknown")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .padding(8)
        }
        .frame(width: 140)
    }
}

#Preview {
    MovieCardView(movie: TrendingModel.previeTitles[0])
        .padding()
        .background(Color.black)
}
