//
//  MoviesAppApp.swift

//
//  Created by Bhavin Parghi on 10/11/25.
//

import SwiftUI
import SwiftData

@main
struct MoviesAppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        // Configure a 50 MB disk image cache for channel logos and poster images.
        // AsyncImage uses URLSession.shared which respects URLCache.shared.
        ImageCacheSession.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(GlobalPlayerManager.shared)
        }
        .modelContainer(for :TrendingModel.self)
    }
}
