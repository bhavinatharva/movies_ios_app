//
//  UnifiedMediaListView.swift

//
//  Created by Antigravity on 14/05/26.
//

import SwiftUI

struct UnifiedMediaListView: View {
    let header: String
    let items: [UnifiedMediaItem]
    let onSelect: (UnifiedMediaItem) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(header)
                #if os(tvOS)
                .font(.system(size: 38, weight: .bold, design: .rounded))
                #else
                .font(.system(size: 20, weight: .bold, design: .rounded))
                #endif
                .foregroundColor(.primary)
                .padding(.horizontal, 16)

            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(items) { item in
                        Button(action: {
                            onSelect(item)
                        }) {
                            UnifiedMediaCardView(item: item)
                        }
                        #if os(tvOS)
                        .buttonStyle(.card)
                        #else
                        .buttonStyle(PressScaleButtonStyle())
                        #endif
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 8)
    }
}

struct UnifiedMediaCardView: View {
    let item: UnifiedMediaItem
    var width: CGFloat? = nil
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    private func fallbackCardBackground(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            LinearGradient(
                colors: [Color.white.opacity(0.08), Color.white.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 8) {
                Image(systemName: item.mediaType == .liveTV ? "tv" : (item.mediaType == .tvSeries ? "play.tv" : "film"))
                    .font(.system(size: 28))
                    .foregroundColor(.white.opacity(0.3))
                
                Text(item.title)
                    #if os(tvOS)
                    .font(.system(size: 24, weight: .bold))
                    #else
                    .font(.system(size: 10, weight: .bold))
                    #endif
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
        }
        .frame(width: w, height: h)
    }
    
    var body: some View {
        #if os(tvOS)
        let cardWidth = width ?? 320
        #else
        let cardWidth = width ?? (horizontalSizeClass == .regular ? 200 : 140)
        #endif
        let cardHeight = cardWidth * 3 / 2 // Modern 2:3 aspect ratio

        
        ZStack(alignment: .bottomLeading) {
            let encodedPosterUrl = item.posterPath?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? item.posterPath
            if let posterUrlString = encodedPosterUrl, !posterUrlString.isEmpty, let posterUrl = URL(string: posterUrlString) {
                AsyncImage(url: posterUrl) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: cardWidth, height: cardHeight)
                            .clipped()
                    case .failure, .empty:
                        fallbackCardBackground(w: cardWidth, h: cardHeight)
                    @unknown default:
                        fallbackCardBackground(w: cardWidth, h: cardHeight)
                    }
                }
                .netflixStyleGradient()
                .premiumCardStyle()
            } else {
                fallbackCardBackground(w: cardWidth, h: cardHeight)
                    .netflixStyleGradient()
                    .premiumCardStyle()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    if item.releaseDate == "LIVE" {
                        LiveIndicatorView()
                    }
                    
                    if let url = item.streamUrl, !url.pathExtension.isEmpty {
                        Text(url.pathExtension.uppercased())
                            #if os(tvOS)
                            .font(.system(size: 14, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            #else
                            .font(.system(size: 8, weight: .bold))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            #endif
                            .foregroundColor(.white)
                            .background(Color.white.opacity(0.3))
                            .clipShape(Capsule())
                    }
                }
                
                Text(item.title)
                    #if os(tvOS)
                    .font(.system(size: width == nil ? 24 : 28, weight: .bold, design: .rounded))
                    #else
                    .font(.system(size: width == nil ? 12 : 14, weight: .bold, design: .rounded))
                    #endif
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .shadow(color: .black.opacity(0.8), radius: 3, x: 0, y: 1)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(width == nil ? 6 : 10)
        }
        .frame(width: cardWidth, height: cardHeight)
        .pressScaleEffect()
    }
}

struct LiveIndicatorView: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.red)
                .frame(width: 6, height: 6)
                .opacity(isAnimating ? 0.3 : 1.0)
                .scaleEffect(isAnimating ? 1.35 : 1.0)
            
            Text("LIVE")
                .font(.system(size: 8, weight: .black))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.red.opacity(0.85))
        .cornerRadius(4)
        .shadow(color: .red.opacity(0.4), radius: 4, x: 0, y: 2)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}
