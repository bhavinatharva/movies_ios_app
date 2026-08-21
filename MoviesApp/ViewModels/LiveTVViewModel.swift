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
    private var filterTask: Task<Void, Never>?
    
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
            
            // Build groups instantly from already categorized data
            let sortedGrouped = IPTVDataManager.shared.categorizedChannels.map { ($0.key, $0.value) }.sorted(by: { $0.0 < $1.0 })
            self.groupedChannels = sortedGrouped
            
            self.filterChannels()
            
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
        filterTask?.cancel()
        
        let category = selectedCategory
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let channels = allChannels
        
        filterTask = Task.detached(priority: .userInitiated) {
            var result = channels
            if category != "All" {
                // Instantly fetch from dictionary if query is empty
                if query.isEmpty {
                    result = IPTVDataManager.shared.categorizedChannels[category] ?? []
                } else {
                    result = result.filter { $0.category == category }
                }
            }
            
            if Task.isCancelled { return }
            
            if !query.isEmpty {
                result = result.filter { $0.name.localizedCaseInsensitiveContains(query) }
            }
            
            if Task.isCancelled { return }
            
            let finalResult = result
            await MainActor.run {
                self.filteredChannels = finalResult
            }
        }
    }
}
