//
//  MovieHorizontalListView.swift
//  MoviesApp
//
//  Created by Antigravity on 13/05/26.
//

import SwiftUI

struct MovieHorizontalListView: View {
    let header: String
    let movies: [TrendingModel]
    let onSelect: (TrendingModel) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(header)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(movies) { movie in
                        MovieCardView(movie: movie)
                            .onTapGesture {
                                onSelect(movie)
                            }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 8)
    }
}
