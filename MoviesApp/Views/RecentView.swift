//
//  RecentView.swift
//  MoviesApp
//

import SwiftUI

struct RecentView: View {
    @Bindable private var userDataManager = UserDataManager.shared
    @State private var selectedItem: UnifiedMediaItem?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                if userDataManager.recentlyWatched.isEmpty {
                    ContentUnavailableView(
                        "No Recent Channels",
                        systemImage: "clock.badge.exclamationmark",
                        description: Text("Channels you watch will appear here so you can quickly jump back in.")
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 16)], spacing: 16) {
                            ForEach(userDataManager.recentlyWatched) { item in
                                UnifiedMediaCardView(item: item)
                                    .onTapGesture {
                                        selectedItem = item
                                    }
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Recent")
            .toolbar {
                if !userDataManager.recentlyWatched.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Clear", role: .destructive) {
                            withAnimation {
                                userDataManager.clearHistory()
                            }
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .fullScreenCover(item: $selectedItem) { item in
                StreamingPlayerView(
                    url: item.streamUrl ?? URL(string: "http://localhost")!,
                    title: item.title,
                    streamId: item.id,
                    isLive: item.mediaType == .liveTV,
                    logoUrl: item.posterPath
                )
            }
        }
    }
}
