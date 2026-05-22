import SwiftUI

struct MovieHeroHeader: View {
    let movie: MovieDetailModel
    let iptvMovie: UnifiedMediaItem?
    let geometry: GeometryProxy
    let onPlayTapped: () -> Void
    let onTrailerTapped: () -> Void
    let hasTrailer: Bool
    
    var body: some View {
        let minY = geometry.frame(in: .global).minY
        let isScrollingDown = minY > 0
        let offset = isScrollingDown ? -minY : 0
        let heightModifier = isScrollingDown ? minY : 0
        
        ZStack(alignment: .bottomLeading) {
            // Backdrop Image
            AsyncImage(url: URL(string: Constants.ImageConstants.posterPathStart + (movie.backdropPath ?? movie.posterPath ?? ""))) { phase in
                switch phase {
                case .empty:
                    Rectangle().fill(Color.gray.opacity(0.1)).shimmer()
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure:
                    Rectangle().fill(Color.gray.opacity(0.1))
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: geometry.size.width, height: 500 + heightModifier)
            .clipped()
            .offset(y: offset)
            
            // Gradient Overlay
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.1),
                    .init(color: .appBackground.opacity(0.6), location: 0.6),
                    .init(color: .appBackground, location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 500 + heightModifier)
            .offset(y: offset)
            
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .bottom, spacing: 16) {
                    // Floating Poster
                    AsyncImage(url: URL(string: Constants.ImageConstants.posterPathStart + (movie.posterPath ?? ""))) { phase in
                        switch phase {
                        case .empty:
                            RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.2)).shimmer()
                        case .success(let image):
                            image.resizable().scaledToFill()
                        case .failure:
                            RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.2))
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(width: 110, height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(movie.title ?? "")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 2)
                            .lineLimit(3)
                            .minimumScaleFactor(0.8)
                        
                        if let tagline = movie.tagline, !tagline.isEmpty {
                            Text(tagline)
                                .font(.subheadline)
                                .italic()
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(2)
                        }
                    }
                }
                
                // Action Buttons inside Hero
                HStack(spacing: 12) {
                    Button(action: onPlayTapped) {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                            Text("Play")
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(12)
                    }
                    .buttonStyle(PressScaleButtonStyle())
                    
                    if hasTrailer {
                        Button(action: onTrailerTapped) {
                            HStack(spacing: 8) {
                                Image(systemName: "film.fill")
                                Text("Trailer")
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.white.opacity(0.15))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .buttonStyle(PressScaleButtonStyle())
                    }
                    
                    Button(action: {}) {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .semibold))
                            .frame(width: 48, height: 48)
                            .background(Color.white.opacity(0.15))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .buttonStyle(PressScaleButtonStyle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(height: 500)
    }
}
