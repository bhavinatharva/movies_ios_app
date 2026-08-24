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
                        let columns = [
                            GridItem(.adaptive(minimum: 110), spacing: 16)
                        ]
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(userDataManager.recentlyWatched) { item in
                                GeometryReader { geo in
                                    UnifiedMediaCardView(item: item, width: geo.size.width)
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
                                .aspectRatio(3/4, contentMode: .fit)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Recent")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SearchView()) {
                        Image(systemName: "magnifyingglass")
                    }
                    
                    if !userDataManager.recentlyWatched.isEmpty {
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
