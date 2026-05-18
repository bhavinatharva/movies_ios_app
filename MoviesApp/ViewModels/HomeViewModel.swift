//
//  HomeViewModel.swift
//  MoviesApp
//
//  Created by Bhavin Parghi on 11/11/25.
//

import Foundation

@Observable
class HomeViewModel {
    private(set) var homeStatus = ApiFetchStatus.notstarted
    private let iptvService = IPTVService.shared
    private let playlistManager = PlaylistManager.shared
    
    var liveChannels: [IPTVChannel] = []
    var categorizedChannels: [String: [IPTVChannel]] = [:]
    
    func refreshContent() async {
        guard let defaultPlaylist = playlistManager.fetchDefaultPlaylist() else {
            homeStatus = .notstarted
            return
        }
        
        // 1. Try loading from Local Cache first (Instant UI)
        let cached = playlistManager.getCachedChannels(forUrl: defaultPlaylist.url)
        if !cached.isEmpty {
            self.liveChannels = cached
            self.categorizedChannels = Dictionary(grouping: cached) { $0.category ?? "General" }
            self.homeStatus = .success
        } else {
            self.homeStatus = .loading
        }
        
        // 2. Refresh from Network (Sync)
        do {
            guard let m3uUrl = URL(string: defaultPlaylist.url) else { return }
            let fetchedChannels = try await iptvService.fetchM3U(url: m3uUrl)
            
            // 3. Update Local Cache
            playlistManager.cacheChannels(fetchedChannels, forUrl: defaultPlaylist.url)
            
            // 4. Update UI
            self.liveChannels = fetchedChannels
            self.categorizedChannels = Dictionary(grouping: fetchedChannels) { $0.category ?? "General" }
            self.homeStatus = .success
        } catch {
            if self.liveChannels.isEmpty {
                homeStatus = .error(underlyingError: error)
            }
        }
    }
}
