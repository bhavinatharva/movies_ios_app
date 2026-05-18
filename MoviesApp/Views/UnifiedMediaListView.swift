//
//  UnifiedMediaListView.swift
//  MoviesApp
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
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(items) { item in
                        UnifiedMediaCardView(item: item)
                            .onTapGesture {
                                onSelect(item)
                            }
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
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: URL(string: item.posterPath ?? "")) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 140, height: 210)
                    .netflixStyleGradient()
            } placeholder: {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 140, height: 210)
                    .shimmer()
            }
            .cardStyle()
            
            VStack(alignment: .leading, spacing: 4) {
                if item.releaseDate == "LIVE" {
                    LiveIndicatorView()
                }
                
                Text(item.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .shadow(color: .black.opacity(0.8), radius: 3, x: 0, y: 1)
            }
            .padding(10)
        }
        .frame(width: 140)
        .pressScaleEffect() // Adds instant tactile scale micro-feedback!
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
