//
//  HomeView.swift
//  MoviesApp
//
//  Created by Bhavin Parghi on 10/11/25.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @State private var homeViewModel = HomeViewModel()
    @State private var detailNavigationPath = NavigationPath()
    @AppStorage("iptv_url") private var iptvUrl = "https://iptv-org.github.io/iptv/index.m3u"

    @State private var isShowingSearch = false
    
    var body: some View {
        NavigationStack(path: $detailNavigationPath) {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Header
                    headerView
                    
                    switch homeViewModel.homeStatus {
                    case .notstarted:
                        noPlaylistView
                    case .loading:
                        if homeViewModel.liveChannels.isEmpty {
                            Spacer()
                            ProgressView().tint(.white)
                            Spacer()
                        } else {
                            contentView
                        }
                    case .success:
                        contentView
                    case .error(let error):
                        errorView(error)
                    }
                }
            }
            .navigationTitle("IPTV Player")
            .navigationBarTitleDisplayMode(.inline)

            .sheet(isPresented: $isShowingSearch) {
                SearchView()
            }
            .task {
                await homeViewModel.refreshContent()
            }
            .navigationDestination(for: UnifiedMediaItem.self) { item in
                if item.source == .iptv, let url = item.streamUrl {
                    StreamingPlayerView(url: url, title: item.title)
                } else {
                    MovieDetailView(title: TrendingModel.previeTitles[0]) // Placeholder fallback
                }
            }
            .navigationDestination(for: String.self) { value in
                if value == "recent" {
                    RecentMoviesView()
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    private var headerView: some View {
        HStack(spacing: 15) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                Text("Search Channels...")
                    .foregroundColor(.gray)
                Spacer()
            }
            .padding(10)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)
            .onTapGesture {
                isShowingSearch = true
            }
            
            Button(action: {
                detailNavigationPath.append("recent")
            }) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
            }
        }
        .padding()
    }
    
    private var contentView: some View {
        ScrollView {
            VStack(spacing: 24) {
                ForEach(homeViewModel.categorizedChannels.keys.sorted(), id: \.self) { category in
                    if let channels = homeViewModel.categorizedChannels[category] {
                        UnifiedMediaListView(
                            header: category,
                            items: channels.map { $0.toUnified },
                            onSelect: { item in
                                detailNavigationPath.append(item)
                            }
                        )
                    }
                }
            }
            .padding(.top, 10)
        }
    }
    
    private var noPlaylistView: some View {
        ContentUnavailableView(
            "No Playlist",
            systemImage: "tv.slash",
            description: Text("Please add an IPTV playlist in settings to start watching.")
        )
        .foregroundColor(.white)
    }
    
    private func errorView(_ error: Error) -> some View {
        ContentUnavailableView(
            "Connection Error",
            systemImage: "wifi.exclamationmark",
            description: Text(error.localizedDescription)
        )
        .foregroundColor(.white)
    }
}

#Preview {
    HomeView()
}
