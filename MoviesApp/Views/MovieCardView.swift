//
//  MovieCardView.swift

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
            .premiumCardStyle()
            
            VStack(alignment: .leading, spacing: 2) {
                Text(movie.title ?? movie.name ?? "Unknown")
                    .font(.system(size: width == nil ? 11 : 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
                    .lineLimit(1)
            }
            .padding(width == nil ? 8 : 10)
        }
        .frame(width: width)
        .aspectRatio(2/3, contentMode: .fit)
        .buttonStyle(PressScaleButtonStyle())
    }
}

#Preview {
    MovieCardView(movie: TrendingModel.previeTitles[0])
        .padding()
        .background(Color.black)
}
