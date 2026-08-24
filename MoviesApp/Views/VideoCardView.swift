//
//  VideoCardView.swift

//
//  Created by Antigravity on 14/05/26.
//

import SwiftUI

struct VideoCardView: View {
    let video: VideoModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                if let key = video.key {
                    AsyncImage(url: URL(string: "https://img.youtube.com/vi/\(key)/mqdefault.jpg")) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 200, height: 112)
                            .clipped()
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.1))
                            .frame(width: 200, height: 112)
                            .shimmer()
                    }
                }
                
                Image(systemName: "play.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(.black.opacity(0.5))
                    .clipShape(Circle())
            }
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2), lineWidth: 1))
            
            Text(video.name ?? "Video")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .lineLimit(2)
                .frame(width: 200, alignment: .leading)
            
            Text(video.type ?? "Featurette")
                .font(.system(size: 10))
                .foregroundColor(.accentColor)
        }
    }
}
