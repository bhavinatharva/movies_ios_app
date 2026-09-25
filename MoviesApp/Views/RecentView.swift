//
//  RecentView.swift

//

import SwiftUI

struct RecentView: View {
    @Bindable private var userDataManager = UserDataManager.shared
    
    private enum ActiveSheet: Identifiable {
        case settings
        case search
        
        var id: Int { hashValue }
    }
    @State private var activeSheet: ActiveSheet?
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    private var gridColumns: [GridItem] {
        #if os(tvOS)
        return [GridItem(.adaptive(minimum: 200, maximum: 260), spacing: 28)]
        #else
        if horizontalSizeClass == .regular {
            return [GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 20)]
        } else {
            return [GridItem(.adaptive(minimum: 110), spacing: 16)]
        }
        #endif
    }
    
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
                        LazyVGrid(columns: gridColumns, spacing: horizontalSizeClass == .regular ? 20 : 16) {
                            ForEach(userDataManager.recentlyWatched) { item in
                                #if os(tvOS)
                                Button {
                                    if let url = item.streamUrl {
                                        GlobalPlayerManager.shared.play(
                                            url: url,
                                            title: item.title,
                                            artwork: item.posterPath,
                                            isLive: item.mediaType == .liveTV,
                                            streamId: item.id
                                        )
                                    }
                                } label: {
                                    UnifiedMediaCardView(item: item, width: 210)
                                }
                                .buttonStyle(.card)
                                #else
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
                                #endif
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Recent")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        activeSheet = .search
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                    Button {
                        activeSheet = .settings
                    } label: {
                        Image(systemName: "gearshape.fill")
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
        .fullScreenCover(item: $activeSheet) { sheet in
            switch sheet {
            case .settings:
                SettingsView()
            case .search:
                SearchView()
            }
        }
    }
}
