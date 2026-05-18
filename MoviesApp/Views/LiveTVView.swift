//
//  LiveTVView.swift
//  MoviesApp
//

import SwiftUI

struct LiveTVView: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("has_default_playlist") private var hasDefaultPlaylist = false
    @AppStorage("active_playlist_url") private var activePlaylistUrl = ""
    @State private var viewModel = LiveTVViewModel()
    @State private var selectedChannel: IPTVChannel?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Dynamic Premium ambient background
                if colorScheme == .light {
                    Color.appBackground.ignoresSafeArea()
                } else {
                    LinearGradient(
                        stops: [
                            .init(color: Color(red: 0.05, green: 0.05, blue: 0.07), location: 0),
                            .init(color: Color(red: 0.01, green: 0.01, blue: 0.02), location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                }
                
                if !hasDefaultPlaylist {
                    emptyPlaylistView
                } else if viewModel.isLoading {
                    ProgressView("Loading Live TV...")
                } else if let error = viewModel.errorMessage {
                    ContentUnavailableView("Error", systemImage: "exclamationmark.triangle", description: Text(error))
                } else {
                    HStack(spacing: 0) {
                        // Categories Sidebar (Vertical Scroll)
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 4) {
                                ForEach(viewModel.categories, id: \.self) { category in
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0)) {
                                            viewModel.selectCategory(category)
                                        }
                                        let generator = UIImpactFeedbackGenerator(style: .light)
                                        generator.impactOccurred()
                                    }) {
                                        HStack {
                                            // Glowing active indicator neon bar
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(viewModel.selectedCategory == category ? Color.accentColor : Color.clear)
                                                .frame(width: 4, height: 18)
                                                .shadow(color: viewModel.selectedCategory == category ? Color.accentColor.opacity(0.8) : .clear, radius: 4)
                                            
                                            Text(category)
                                                .font(.system(size: 13, weight: viewModel.selectedCategory == category ? .bold : .medium, design: .rounded))
                                                .foregroundColor(viewModel.selectedCategory == category ? .primary : .secondary)
                                                .padding(.leading, 2)
                                            
                                            Spacer()
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(viewModel.selectedCategory == category ? Color.white.opacity(0.06) : Color.clear)
                                        )
                                        .padding(.horizontal, 6)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.top, 12)
                        }
                        .frame(width: 130)
                        .background(Color.white.opacity(0.02))
                        
                        // Channels List
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.filteredChannels) { channel in
                                    Button(action: {
                                        let generator = UIImpactFeedbackGenerator(style: .medium)
                                        generator.impactOccurred()
                                        UserDataManager.shared.addToHistory(channel.toUnified)
                                        selectedChannel = channel
                                    }) {
                                        HStack(spacing: 16) {
                                            // Glass-framed Logo Container
                                            ZStack {
                                                Color.appCardBackground
                                                
                                                if let logoUrl = channel.logoUrl {
                                                    AsyncImage(url: logoUrl) { image in
                                                        image.resizable()
                                                             .scaledToFit()
                                                             .padding(4)
                                                    } placeholder: {
                                                        Image(systemName: "tv")
                                                            .font(.body)
                                                            .foregroundColor(.secondary)
                                                    }
                                                } else {
                                                    Image(systemName: "tv")
                                                        .font(.body)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            .frame(width: 64, height: 44)
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                                            )
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(channel.name)
                                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                                    .foregroundColor(.primary)
                                                    .lineLimit(1)
                                                
                                                if let cat = channel.category {
                                                    Text(cat)
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                        .lineLimit(1)
                                                }
                                            }
                                            
                                            Spacer()
                                            
                                            // Glowing Mini Live Badge
                                            HStack(spacing: 4) {
                                                Circle()
                                                    .fill(Color.red)
                                                    .frame(width: 6, height: 6)
                                                Text("LIVE")
                                                    .font(.system(size: 9, weight: .black))
                                                    .foregroundColor(.red)
                                            }
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.red.opacity(0.1))
                                            .cornerRadius(6)
                                        }
                                        .padding(12)
                                        .glassBackground(cornerRadius: 16)
                                        .padding(.horizontal, 12)
                                    }
                                    .buttonStyle(PressScaleButtonStyle())
                                }
                            }
                            .padding(.top, 12)
                        }
                    }
                }
            }
            .navigationTitle(Constants.StringConstants.tabLiveTV)
            .navigationBarTitleDisplayMode(.inline)
            .task(id: activePlaylistUrl) {
                if hasDefaultPlaylist {
                    await viewModel.loadData()
                }
            }
            .fullScreenCover(item: $selectedChannel) { channel in
                StreamingPlayerView(url: channel.streamUrl, title: channel.name)
            }
        }
    }
    
    private var emptyPlaylistView: some View {
        ContentUnavailableView {
            Label("No Playlist Loaded", systemImage: "tv.slash")
        } description: {
            Text("Go to the Settings tab to add your IPTV M3U Playlist URL and start watching.")
        }
    }
}
