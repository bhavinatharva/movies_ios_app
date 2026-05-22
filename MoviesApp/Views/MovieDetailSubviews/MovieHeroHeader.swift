import SwiftUI

struct MovieHeroHeader: View {
    let movie: MovieDetailModel
    let geometry: GeometryProxy
    
    var body: some View {
        let minY = geometry.frame(in: .global).minY
        let isScrollingDown = minY > 0
        let offset = isScrollingDown ? -minY : 0
        let heightModifier = isScrollingDown ? minY : 0
        
        ZStack(alignment: .bottomLeading) {
            // Poster / Backdrop Image
            AsyncImage(url: URL(string: Constants.ImageConstants.posterPathStart + (movie.backdropPath ?? movie.posterPath ?? ""))) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .shimmer()
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: geometry.size.width, height: 500 + heightModifier)
            .clipped()
            .offset(y: offset)
            
            // Gradient Overlay for text readability
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.4),
                    .init(color: .appBackground.opacity(0.8), location: 0.8),
                    .init(color: .appBackground, location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 500 + heightModifier)
            .offset(y: offset)
            
            // Title and basic metadata overlay
            VStack(alignment: .leading, spacing: 12) {
                Text(movie.title ?? "")
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                
                HStack(spacing: 12) {
                    if movie.adult == true {
                        Text("18+")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .cornerRadius(4)
                    }
                    
                    if let releaseYear = movie.releaseDate?.prefix(4) {
                        Text(String(releaseYear))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    if let runtime = movie.runtime, runtime > 0 {
                        Text("\(runtime / 60)h \(runtime % 60)m")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Text("4K")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(4)
                        .foregroundColor(.white)
                }
                .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 2)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(height: 500)
    }
}
