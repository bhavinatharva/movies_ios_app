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
    @State private var isShowingSettings = false
    @State private var isShowingSearch = false
    
    var body: some View {
        NavigationStack(path: $detailNavigationPath) {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Header with Search and Recent
                    HStack(spacing: 15) {
                        // Search Bar Placeholder
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
                        
                        // Recent Button
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
                    
                    switch homeViewModel.homeStatus {
                    case .notstarted, .loading:
                        Spacer()
                        ProgressView().tint(.white)
                        Spacer()
                    case .success:
                        ScrollView {
                            VStack(spacing: 24) {
                                // Dynamic Rails from Categories
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
                        
                    case .error(let error):
                        ContentUnavailableView(
                            "Connection Error",
                            systemImage: "wifi.exclamationmark",
                            description: Text(error.localizedDescription)
                        )
                        .foregroundColor(.white)
                    }
                }
            }
            .navigationTitle("IPTV Player")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { isShowingSettings = true }) {
                        Image(systemName: "gearshape")
                            .foregroundColor(.white)
                    }
                }
            }
            .sheet(isPresented: $isShowingSettings) {
                SettingsView()
                    .onDisappear {
                        Task { await homeViewModel.getTitles(url: iptvUrl) }
                    }
            }
            .sheet(isPresented: $isShowingSearch) {
                SearchView() // Assuming SearchView exists and can be refactored
            }
            .task {
                await homeViewModel.getTitles(url: iptvUrl)
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
}

#Preview {
    HomeView()
}
