import SwiftUI

struct MovieQuickInfoRow: View {
    let movie: MovieDetailModel
    let iptvMovie: UnifiedMediaItem?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let releaseYear = movie.releaseDate?.prefix(4) {
                    infoChip(text: String(releaseYear))
                }
                
                if let runtime = movie.runtime, runtime > 0 {
                    infoChip(text: "\(runtime / 60)h \(runtime % 60)m")
                }
                
                if let rating = movie.voteAverage, rating > 0 {
                    infoChip(text: String(format: "%.1f", rating), icon: "star.fill", iconColor: .yellow)
                }
                
                if let country = iptvMovie?.country, !country.isEmpty {
                    infoChip(text: country)
                }
                
                infoChip(text: "4K HDR", isBadge: true)
                infoChip(text: "5.1", isBadge: true)
                
                if let genres = movie.genres {
                    ForEach(genres) { genre in
                        infoChip(text: genre.name)
                    }
                } else if let genres = iptvMovie?.genres {
                    ForEach(genres, id: \.self) { genre in
                        infoChip(text: genre)
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    @ViewBuilder
    private func infoChip(text: String, icon: String? = nil, iconColor: Color? = nil, isBadge: Bool = false) -> some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(iconColor ?? .white)
                    .font(.system(size: 10))
            }
            Text(text)
                .fontWeight(isBadge ? .heavy : .medium)
                .foregroundColor(.white)
        }
        .font(.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(isBadge ? 0.2 : 0.1))
        .cornerRadius(6)
    }
}
