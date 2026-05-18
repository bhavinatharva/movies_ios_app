//
//  LiveTVView.swift
//  MoviesApp
//

import SwiftUI

struct LiveTVView: View {
    @AppStorage("has_default_playlist") private var hasDefaultPlaylist = false
    @State private var viewModel = LiveTVViewModel()
    @State private var selectedChannel: IPTVChannel?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if !hasDefaultPlaylist {
                    emptyPlaylistView
                } else if viewModel.isLoading {
                    ProgressView("Loading Live TV...")
                        .tint(.white)
                        .foregroundColor(.white)
                } else if let error = viewModel.errorMessage {
                    ContentUnavailableView("Error", systemImage: "exclamationmark.triangle", description: Text(error))
                        .foregroundColor(.white)
                } else {
                    HStack(spacing: 0) {
                        // Categories Sidebar (Vertical Scroll)
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 0) {
                                ForEach(viewModel.categories, id: \.self) { category in
                                    Button(action: {
                                        viewModel.selectCategory(category)
                                    }) {
                                        Text(category)
                                            .font(.subheadline)
                                            .fontWeight(viewModel.selectedCategory == category ? .bold : .regular)
                                            .foregroundColor(viewModel.selectedCategory == category ? .white : .gray)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding()
                                            .background(viewModel.selectedCategory == category ? Color.gray.opacity(0.3) : Color.clear)
                                    }
                                }
                            }
                        }
                        .frame(width: 120)
                        .background(Color.gray.opacity(0.1))
                        
                        // Channels List
                        ScrollView {
                            LazyVStack(spacing: 15) {
                                ForEach(viewModel.filteredChannels) { channel in
                                    Button(action: {
                                        UserDataManager.shared.addToHistory(channel.toUnified)
                                        selectedChannel = channel
                                    }) {
                                        HStack(spacing: 15) {
                                            if let logoUrl = channel.logoUrl {
                                                AsyncImage(url: logoUrl) { image in
                                                    image.resizable()
                                                         .scaledToFit()
                                                } placeholder: {
                                                    Image(systemName: "tv")
                                                        .foregroundColor(.gray)
                                                }
                                                .frame(width: 60, height: 40)
                                                .cornerRadius(4)
                                            } else {
                                                Image(systemName: "tv")
                                                    .frame(width: 60, height: 40)
                                                    .background(Color.gray.opacity(0.3))
                                                    .cornerRadius(4)
                                                    .foregroundColor(.white)
                                            }
                                            
                                            Text(channel.name)
                                                .font(.headline)
                                                .foregroundColor(.white)
                                                .multilineTextAlignment(.leading)
                                            
                                            Spacer()
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                            .padding(.top)
                        }
                    }
                }
            }
            .navigationTitle(Constants.StringConstants.tabLiveTV)
            .navigationBarTitleDisplayMode(.inline)
            .task {
                if hasDefaultPlaylist && viewModel.categories.isEmpty {
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
        .foregroundColor(.white)
    }
}
