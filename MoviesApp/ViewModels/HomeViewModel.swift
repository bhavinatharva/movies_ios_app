//
//  HomeViewModel.swift
//  MoviesApp
//

import Foundation
import SwiftUI

@Observable
class HomeViewModel {
    private(set) var homeStatus = ApiFetchStatus.notstarted
    private let iptvService = IPTVService.shared
    private let playlistManager = PlaylistManager.shared
    
    var featuredItem: UnifiedMediaItem?
    var liveChannels: [IPTVChannel] = []
    var categorizedChannels: [String: [IPTVChannel]] = [:]
    var continueWatching: [UnifiedMediaItem] = []
    
    func refreshContent() async {
        guard let defaultPlaylist = playlistManager.fetchDefaultPlaylist() else {
            await MainActor.run {
                self.homeStatus = .notstarted
            }
            return
        }
        
        await MainActor.run {
            self.continueWatching = UserDataManager.shared.recentlyWatched
        }
        
        // 1. Try loading from Local Cache first (Instant UI)
        let cached = playlistManager.getCachedChannels(forUrl: defaultPlaylist.url)
        if !cached.isEmpty {
            await MainActor.run {
                self.liveChannels = cached
                self.categorizedChannels = Dictionary(grouping: cached) { $0.category ?? "General" }
                if let firstChannel = cached.first {
                    self.featuredItem = firstChannel.toUnified
                }
                self.homeStatus = .success
            }
        } else {
            await MainActor.run {
                self.homeStatus = .loading
            }
        }
        
        // 2. Refresh from Network
        do {
            guard let m3uUrl = URL(string: defaultPlaylist.url) else { return }
            let fetchedChannels = try await iptvService.fetchM3U(url: m3uUrl)
            
            // 3. Update Local Cache
            playlistManager.cacheChannels(fetchedChannels, forUrl: defaultPlaylist.url)
            
            await MainActor.run {
                self.liveChannels = fetchedChannels
                self.categorizedChannels = Dictionary(grouping: fetchedChannels) { $0.category ?? "General" }
                if let firstChannel = fetchedChannels.first {
                    self.featuredItem = firstChannel.toUnified
                }
                self.homeStatus = .success
            }
        } catch {
            await MainActor.run {
                if self.liveChannels.isEmpty {
                    self.homeStatus = .error(underlyingError: error)
                }
            }
        }
    }
}
