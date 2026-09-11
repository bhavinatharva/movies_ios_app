import SwiftUI

struct MovieMetadataChips: View {
    let movie: MovieDetailModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let rating = movie.voteAverage, rating > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 12))
                        Text(String(format: "%.1f", rating))
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(UIColor.secondarySystemFill))
                    .cornerRadius(20)
                }
                
                if let genres = movie.genres {
                    ForEach(genres) { genre in
                        Text(genre.name)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(UIColor.tertiarySystemFill))
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color(UIColor.separator).opacity(0.4), lineWidth: 1)
                            )
                    }
                }
            }
            .font(.caption)
            .foregroundColor(.primary)
            .padding(.horizontal, 24)
        }
    }
}
