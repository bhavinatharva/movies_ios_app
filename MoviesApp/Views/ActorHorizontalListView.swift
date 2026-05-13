//
//  ActorHorizontalListView.swift
//  MoviesApp
//
//  Created by Antigravity on 13/05/26.
//

import SwiftUI

struct ActorHorizontalListView: View {
    let header: String
    let actors: [ActorModel]
    let onSelect: (ActorModel) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(header)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(actors) { actor in
                        ActorCardView(actor: actor)
                            .onTapGesture {
                                onSelect(actor)
                            }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    ActorHorizontalListView(header: "Popular Actors", actors: ActorModel.previeTitles, onSelect: { _ in })
        .background(Color.black)
}
