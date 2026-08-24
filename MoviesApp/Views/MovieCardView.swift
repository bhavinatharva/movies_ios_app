//
//  MovieCardView.swift

//
//  Created by Antigravity on 13/05/26.
//

import SwiftUI

struct MovieCardView: View {
    let movie: TrendingModel
    var width: CGFloat? = 140
    @AppStorage("show_adult_content") private var showAdultContent = false
    
    private var isAdult: Bool {
        if movie.adult == true { return true }
        let titleLower = (movie.title ?? movie.name ?? "").lowercased()
        if titleLower.contains("18+") || titleLower.contains("xxx") || titleLower.contains("adult") {
            return true
        }
        return false
    }
    
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
            .blur(radius: (isAdult && !showAdultContent) ? 22 : 0)
            .netflixStyleGradient()
            .premiumCardStyle()
            
            if isAdult && !showAdultContent {
                Color.black.opacity(0.4)
                    .premiumCardStyle()
                
                VStack(spacing: 6) {
                    Image(systemName: "eye.slash.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.85))
                    Text("18+")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.red)
                        .cornerRadius(6)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                if movie.adult == true && showAdultContent {
                    Text("18+")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                }
                
                Text(movie.title ?? movie.name ?? "Unknown")
                    .font(.system(size: width == nil ? 11 : 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
                    .lineLimit(1)
            }
            .padding(width == nil ? 8 : 10)
            .opacity((isAdult && !showAdultContent) ? 0.3 : 1.0)
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
