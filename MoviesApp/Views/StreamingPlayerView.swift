//
//  StreamingPlayerView.swift
//  MoviesApp
//
//  Created by Antigravity on 14/05/26.
//

import SwiftUI
import AVKit

struct StreamingPlayerView: View {
    let url: URL
    let title: String
    @Environment(\.dismiss) var dismiss
    
    @State private var player = AVPlayer()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VideoPlayer(player: player)
                .onAppear {
                    player = AVPlayer(url: url)
                    player.play()
                }
                .onDisappear {
                    player.pause()
                }
            
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding()
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}
