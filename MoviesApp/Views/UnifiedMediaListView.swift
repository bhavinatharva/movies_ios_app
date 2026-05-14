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
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 140, height: 210)
                    .shimmer()
            }
            .cardStyle()
            
            VStack(alignment: .leading, spacing: 2) {
                if item.releaseDate == "LIVE" {
                    Text("LIVE")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.red)
                        .cornerRadius(2)
                }
                
                Text(item.title)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .padding(8)
        }
        .frame(width: 140)
    }
}
