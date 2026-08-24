//
//  MovieCollectionListView.swift

//
//  Created by Antigravity on 21/05/26.
//

import SwiftUI

struct MovieCollectionListView: View {
    let header: String
    let collections: [MovieCollection]
    let onSelect: (MovieCollection) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(header)
                .font(.title3)
                .fontWeight(.black)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 20) {
                    ForEach(collections) { collection in
                        Button(action: {
                            onSelect(collection)
                        }) {
                            MovieCollectionCardView(collection: collection)
                        }
                        .buttonStyle(PressScaleButtonStyle())
                    }
                }
                // Larger cards for collections
                .frame(height: 220)
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 8)
    }
}

struct MovieCollectionCardView: View {
    let collection: MovieCollection
    var width: CGFloat = 160
    
    private var cardHeight: CGFloat { width * 4 / 3 }
    
    private var fallbackCardBackground: some View {
        ZStack {
            LinearGradient(
                colors: [Color.accentColor.opacity(0.3), Color.black.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 8) {
                Image(systemName: "rectangle.stack.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .frame(width: width, height: cardHeight)
    }
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let posterUrlString = collection.posterPath, !posterUrlString.isEmpty, let posterUrl = URL(string: posterUrlString) {
                AsyncImage(url: posterUrl) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: width, height: cardHeight)
                            .clipped()
                    case .failure, .empty:
                        fallbackCardBackground
                    @unknown default:
                        fallbackCardBackground
                    }
                }
                .overlay {
                    // Stronger gradient for collection titles which tend to be multi-line
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.3),
                            .init(color: .black.opacity(0.9), location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .cardStyle()
            } else {
                fallbackCardBackground
                    .cardStyle()
            }
            
            // Badge for movie count
            VStack {
                HStack {
                    Spacer()
                    Text("\(collection.movieCount) Movies")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor)
                        .cornerRadius(8)
                        .padding(8)
                        .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 2)
                }
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                if let year = collection.yearRange {
                    Text(year)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Text(collection.title)
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .shadow(color: .black, radius: 4, x: 0, y: 2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
        }
        .frame(width: width, height: cardHeight)
        .pressScaleEffect()
        // Overlay a slight border for premium feel
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }
}
