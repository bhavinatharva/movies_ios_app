//
//  ActorCardView.swift
//  MoviesApp
//
//  Created by Antigravity on 13/05/26.
//

import SwiftUI

struct ActorCardView: View {
    let actor: ActorModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomLeading) {
                AsyncImage(url: URL(string: actor.profilePath ?? "")) { image in
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
                    Text(actor.name ?? "Unknown")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(actor.knownForDepartment ?? "")
                        .font(.system(size: 8))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                .padding(8)
            }
        }
        .frame(width: 140)
    }
}

#Preview {
    ActorCardView(actor: ActorModel.previeTitles[0])
        .padding()
        .background(Color.black)
}
