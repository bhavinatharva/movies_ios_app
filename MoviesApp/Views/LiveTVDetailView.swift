//
//  LiveTVDetailView.swift
//  MoviesApp
//

import SwiftUI
import AVKit

struct LiveTVDetailView: View {
    let channel: IPTVChannel
    
    // In a real app we would use EPGService to fetch the schedule.
    private var epg: MockEPGInfo {
        getMockEPG(for: channel.name)
    }
    
    @State private var isFullScreen = false
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top: Inline Player
                ZStack(alignment: .bottomTrailing) {
                    StreamingPlayerView(url: channel.streamUrl, title: channel.name, isLive: true, logoUrl: channel.logoUrl?.absoluteString)
                        .frame(height: UIScreen.main.bounds.width * 9/16)
                        .id(channel.id) // Ensure player resets when channel changes
                    
                    // A button to force full screen if the player's internal UI is hidden
                    Button(action: { isFullScreen = true }) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .padding(8)
                }
                
                // Bottom: Metadata and EPG
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // Header
                        HStack(alignment: .top, spacing: 16) {
                            ZStack {
                                Color.white.opacity(0.05)
                                if let logoUrl = channel.logoUrl {
                                    AsyncImage(url: logoUrl) { image in
                                        image.resizable().scaledToFit().padding(8)
                                    } placeholder: {
                                        ProgressView()
                                    }
                                } else {
                                    Image(systemName: "tv").font(.title).foregroundColor(.white.opacity(0.5))
                                }
                            }
                            .frame(width: 80, height: 80)
                            .cornerRadius(12)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Circle().fill(Color.red).frame(width: 8, height: 8)
                                    Text("LIVE NOW")
                                        .font(.system(size: 11, weight: .black, design: .rounded))
                                        .foregroundColor(.red)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.red.opacity(0.2))
                                .clipShape(Capsule())
                                
                                Text(channel.name)
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                UserDataManager.shared.toggleFavorite(id: channel.toUnified.id)
                            }) {
                                Image(systemName: UserDataManager.shared.isFavorite(id: channel.toUnified.id) ? "star.fill" : "star")
                                    .font(.title2)
                                    .foregroundColor(UserDataManager.shared.isFavorite(id: channel.toUnified.id) ? .yellow : .white)
                                    .frame(width: 44, height: 44)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(PressScaleButtonStyle())
                        }
                        
                        // Current Show Info
                        VStack(alignment: .leading, spacing: 8) {
                            Text(epg.currentShow)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Up Next: \(epg.nextShow)")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.6))
                            
                            // Progress Bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Color.white.opacity(0.1))
                                    Capsule().fill(Color.red).frame(width: geo.size.width * epg.progress)
                                }
                            }
                            .frame(height: 4)
                            .padding(.top, 4)
                        }
                        
                        Divider().background(Color.white.opacity(0.1))
                        
                        // Upcoming Schedule
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Upcoming Schedule")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            VStack(spacing: 12) {
                                scheduleRow(time: "10:00 PM", show: epg.nextShow)
                                scheduleRow(time: "11:30 PM", show: "Late Night Special")
                                scheduleRow(time: "1:00 AM", show: "Midnight Replay")
                            }
                        }
                    }
                    .padding(24)
                }
            }
        }
        .fullScreenCover(isPresented: $isFullScreen) {
            StreamingPlayerView(url: channel.streamUrl, title: channel.name, isLive: true, logoUrl: channel.logoUrl?.absoluteString)
        }
        .onAppear {
            UserDataManager.shared.addToHistory(channel.toUnified)
        }
    }
    
    private func scheduleRow(time: String, show: String) -> some View {
        HStack(spacing: 16) {
            Text(time)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.accentColor)
                .frame(width: 80, alignment: .leading)
            
            Text(show)
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding(16)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
    }
}
