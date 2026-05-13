//
//  ActorHeroHeaderView.swift
//  MoviesApp
//
//  Created by Antigravity on 13/05/26.
//

import SwiftUI

struct ActorHeroHeaderView: View {
    let actor: ActorModel?
    
    var body: some View {
        ZStack(alignment: .bottom) {
            if let profilePath = actor?.profilePath, let url = URL(string: profilePath) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 450)
                        .clipped()
                        .overlay {
                            LinearGradient(
                                stops: [
                                    Gradient.Stop(color: .clear, location: 0.5),
                                    Gradient.Stop(color: .black, location: 1.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }
                } placeholder: {
                    Color.black.opacity(0.8)
                        .frame(height: 450)
                }
            } else {
                Color.black.opacity(0.8)
                    .frame(height: 450)
            }
            
            VStack(spacing: 12) {
                Text(actor?.name ?? "Featured Actor")
                    .font(.system(size: 42, weight: .black))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 16) {
                    Text(actor?.knownForDepartment?.uppercased() ?? "ACTING")
                        .font(.caption)
                        .fontWeight(.bold)
                        .tracking(2)
                        .foregroundColor(.white)
                    
                    Circle()
                        .frame(width: 4, height: 4)
                        .foregroundColor(.gray)
                    
                    Text("TRENDING NOW")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.accentColor)
                }
                
                HStack(spacing: 20) {
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Details")
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(4)
                    }
                    
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "plus")
                            Text("My List")
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                    }
                }
            }
            .padding(.bottom, 40)
        }
    }
}

#Preview {
    ActorHeroHeaderView(actor: ActorModel.previeTitles[0])
}
