//
//  MovieCardView.swift
//  MoviesApp
//
//  Created by Antigravity on 13/05/26.
//

import SwiftUI

struct MovieCardView: View {
    let movie: TrendingModel
    var width: CGFloat? = 140
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: URL(string: movie.posterPath ?? "")) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .shimmer()
            }
            .netflixStyleGradient()
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
                    .font(.system(size: width == nil ? 11 : 13, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .padding(width == nil ? 6 : 8)
        }
        .frame(width: width)
        .aspectRatio(3/4, contentMode: .fit)
    }
}

#Preview {
    MovieCardView(movie: TrendingModel.previeTitles[0])
        .padding()
        .background(Color.black)
}
