//
//  ContentView.swift

//
//  Created by Bhavin Parghi on 10/11/25.
//

import SwiftUI

struct ContentView: View {
    @State private var userDataManager = UserDataManager.shared
    
    @EnvironmentObject var globalPlayerManager: GlobalPlayerManager
    
    var body: some View {
        ZStack {
            MainTabView()
                .preferredColorScheme(.dark)
                .onAppear {
                    if let config = ApiConfig.shared {
                        print("ApiConfig.shared.baseUrl", config.baseUrl ?? "Not available")
                    }
                }
            
            if let title = globalPlayerManager.currentTitle, let url = globalPlayerManager.currentUrl {
                StreamingPlayerView(
                    url: url,
                    title: title,
                    streamId: globalPlayerManager.streamId,
                    subtitle: globalPlayerManager.subtitle,
                    isLive: globalPlayerManager.isLive,
                    logoUrl: globalPlayerManager.currentArtwork,
                    nextEpisodeTitle: globalPlayerManager.nextEpisodeTitle,
                    onPlayNext: globalPlayerManager.onPlayNext
                )
                .transition(.opacity)
                .zIndex(100)
            }
        }
    }
}

#Preview {
    ContentView()
}
