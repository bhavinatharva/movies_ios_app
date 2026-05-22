//
//  LiveTVViewModel.swift
//  MoviesApp
//

import Foundation
import SwiftUI

@Observable
class LiveTVViewModel {
    var allChannels: [IPTVChannel] = []
    var filteredChannels: [IPTVChannel] = []
    var categories: [String] = []
    var selectedCategory: String = "All"
    var searchQuery: String = ""
    
    // Support for horizontal rails
    var groupedChannels: [(category: String, channels: [IPTVChannel])] = []
    var heroChannel: IPTVChannel?
    
    var activeChannelForMiniPlayer: IPTVChannel?
    var selectedChannelForFullScreen: IPTVChannel?
    
    var isLoading = false
    var errorMessage: String?
    
    private let playlistManager = PlaylistManager.shared
    private var lastLoadedUrl: String? = nil
    
    var favorites: [IPTVChannel] = []
    var recentlyWatched: [IPTVChannel] = []
    
    var trendingChannels: [IPTVChannel] {
        Array(allChannels.prefix(10))
    }
    
    func updateUserData() {
        let favIds = UserDataManager.shared.favorites
        self.favorites = allChannels.filter { favIds.contains($0.toUnified.id) }
        
        let historyIds = UserDataManager.shared.recentlyWatched.filter { $0.mediaType == .liveTV }.map { $0.id }
        self.recentlyWatched = allChannels.filter { historyIds.contains($0.toUnified.id) }
    }
    
    func loadData() async {
        let currentUrl = IPTVDataManager.shared.currentLoadedPlaylistUrl
        if let current = currentUrl, current == lastLoadedUrl, !allChannels.isEmpty || IPTVDataManager.shared.liveChannels.isEmpty {
            await MainActor.run {
                self.updateUserData()
            }
            return
        }
        
        self.lastLoadedUrl = currentUrl
        
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        // Wait a tiny bit if IPTVDataManager is still loading
        if case .loading = IPTVDataManager.shared.homeStatus {
            try? await Task.sleep(for: .milliseconds(300))
        }
        
        let channels = IPTVDataManager.shared.liveChannels
        
        await MainActor.run {
            self.allChannels = channels
            let uniqueCategories = Array(Set(channels.compactMap { $0.category })).sorted()
            self.categories = ["All"] + uniqueCategories
            self.filterChannels()
            
            // Build groups on a background thread for performance
            Task.detached(priority: .userInitiated) {
                var tempGrouped: [String: [IPTVChannel]] = [:]
                for channel in channels {
                    let cat = channel.category ?? "General"
                    tempGrouped[cat, default: []].append(channel)
                }
                
                let sortedGrouped = tempGrouped.map { ($0.key, $0.value) }.sorted(by: { $0.0 < $1.0 })
                
                await MainActor.run {
                    self.groupedChannels = sortedGrouped
                }
            }
            
            // Pre-compute user data
            self.updateUserData()
            
            // Auto-play the first channel in the mini player if none selected yet
            if self.activeChannelForMiniPlayer == nil, let first = channels.first {
                self.activeChannelForMiniPlayer = first
            }
            if self.heroChannel == nil {
                self.heroChannel = self.trendingChannels.first ?? channels.first
            }
            self.isLoading = false
        }
    }
    
    func selectCategory(_ category: String) {
        selectedCategory = category
        filterChannels()
    }
    
    func filterChannels() {
        var result = allChannels
        if selectedCategory != "All" {
            result = result.filter { $0.category == selectedCategory }
        }
        if !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchQuery) }
        }
        filteredChannels = result
    }
}
