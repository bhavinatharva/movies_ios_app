//
//  RecentView.swift
//  MoviesApp
//

import SwiftUI

struct RecentView: View {
    @Bindable private var userDataManager = UserDataManager.shared
    
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
                                        if let url = item.streamUrl {
                                            GlobalPlayerManager.shared.play(
                                                url: url,
                                                title: item.title,
                                                artwork: item.posterPath,
                                                isLive: item.mediaType == .liveTV,
                                                streamId: item.id
                                            )
                                        }
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
        }
    }
}
