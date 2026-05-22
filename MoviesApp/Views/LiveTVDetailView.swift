//
//  LiveTVDetailView.swift
//  MoviesApp
//

import SwiftUI
import AVKit

struct LiveTVDetailView: View {
    let channel: IPTVChannel
    @Environment(\.dismiss) var dismiss
    @State private var showPlayer = false
    
    // In a real app we would use EPGService to fetch the schedule.
    private var epg: MockEPGInfo {
        getMockEPG(for: channel.name)
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    
                    // Cinematic Header Backdrop
                    ZStack(alignment: .bottomLeading) {
                        // Blurred Background Logo
                        if let logoUrl = channel.logoUrl {
                            AsyncImage(url: logoUrl) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .blur(radius: 40)
                                    .opacity(0.4)
                            } placeholder: {
                                Color.white.opacity(0.05)
                            }
                            .frame(height: 500)
                            .clipped()
                        } else {
                            LinearGradient(colors: [Color.accentColor.opacity(0.3), .black], startPoint: .top, endPoint: .bottom)
                                .frame(height: 500)
                        }
                        
                        // Premium Gradient Overlay
                        LinearGradient(
                            stops: [
                                .init(color: .black.opacity(0.8), location: 0),
                                .init(color: .clear, location: 0.3),
                                .init(color: .clear, location: 0.6),
                                .init(color: .appBackground, location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 500)
                        
                        // Metadata Content
                        VStack(alignment: .leading, spacing: 16) {
                            
                            HStack(alignment: .bottom, spacing: 16) {
                                // Floating Logo
                                ZStack {
                                    Color.white.opacity(0.1)
                                    if let logoUrl = channel.logoUrl {
                                        AsyncImage(url: logoUrl) { image in
                                            image.resizable().scaledToFit().padding(10)
                                        } placeholder: {
                                            ProgressView()
                                        }
                                    } else {
                                        Image(systemName: "tv").font(.title).foregroundColor(.white.opacity(0.5))
                                    }
                                }
                                .frame(width: 80, height: 80)
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.5), radius: 10, y: 5)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    // LIVE badge
                                    HStack(spacing: 6) {
                                        Circle().fill(Color.red).frame(width: 8, height: 8)
                                        Text("LIVE NOW")
                                            .font(.system(size: 12, weight: .black, design: .rounded))
                                            .foregroundColor(.red)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.red.opacity(0.2))
                                    .clipShape(Capsule())
                                    
                                    Text(channel.name)
                                        .font(.system(size: 32, weight: .black, design: .rounded))
                                        .foregroundColor(.white)
                                        .shadow(color: .black.opacity(0.8), radius: 4, y: 2)
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.5)
                                }
                            }
                            
                            // EPG Info
                            VStack(alignment: .leading, spacing: 8) {
                                Text(epg.currentShow)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text("Up Next: \(epg.nextShow)")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.6))
                                
                                // Progress Bar
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule().fill(Color.white.opacity(0.2))
                                        Capsule().fill(Color.red).frame(width: geo.size.width * epg.progress)
                                    }
                                }
                                .frame(height: 6)
                                .padding(.top, 4)
                            }
                            
                            // Actions
                            HStack(spacing: 16) {
                                Button(action: {
                                    showPlayer = true
                                }) {
                                    HStack {
                                        Image(systemName: "play.fill")
                                        Text("Watch Live")
                                    }
                                    .font(.headline)
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.white)
                                    .cornerRadius(12)
                                }
                                .buttonStyle(PressScaleButtonStyle())
                                .fullScreenCover(isPresented: $showPlayer) {
                                    StreamingPlayerView(url: channel.streamUrl, title: channel.name)
                                }
                                
                                Button(action: {
                                    UserDataManager.shared.toggleFavorite(id: channel.toUnified.id)
                                }) {
                                    Image(systemName: UserDataManager.shared.isFavorite(id: channel.toUnified.id) ? "star.fill" : "plus")
                                        .font(.title3)
                                        .foregroundColor(.white)
                                        .frame(width: 50, height: 50)
                                        .background(Color.white.opacity(0.15))
                                        .cornerRadius(12)
                                }
                                .buttonStyle(PressScaleButtonStyle())
                            }
                            .padding(.top, 8)
                            
                        }
                        .padding(24)
                    }
                    
                    // Further content (Upcoming Schedule, Similar Channels) could go here
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Coming Up Next")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.horizontal, 24)
                        
                        VStack(spacing: 12) {
                            scheduleRow(time: "10:00 PM", show: epg.nextShow)
                            scheduleRow(time: "11:30 PM", show: "Late Night Special")
                            scheduleRow(time: "1:00 AM", show: "Midnight Replay")
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 60)
                }
            }
            .background(Color.appBackground.ignoresSafeArea())
        }
        .navigationBarBackButtonHidden(true)
        .overlay(alignment: .topLeading) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.black.opacity(0.4))
                    .clipShape(Circle())
            }
            .buttonStyle(PressScaleButtonStyle())
            .padding(.top, 50)
            .padding(.leading, 20)
        }
        .ignoresSafeArea(edges: .top)
        .onAppear {
            UserDataManager.shared.addToHistory(channel.toUnified)
        }
    }
    
    private func scheduleRow(time: String, show: String) -> some View {
        HStack(spacing: 16) {
            Text(time)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.accentColor)
                .frame(width: 80, alignment: .leading)
            
            Text(show)
                .font(.body)
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}
