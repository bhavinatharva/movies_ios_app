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
    
    var activeChannelForMiniPlayer: IPTVChannel?
    var selectedChannelForFullScreen: IPTVChannel?
    
    var isLoading = false
    var errorMessage: String?
    
    private let playlistManager = PlaylistManager.shared
    
    var favorites: [IPTVChannel] {
        let favIds = UserDataManager.shared.favorites
        return allChannels.filter { favIds.contains($0.toUnified.id) }
    }
    
    var recentlyWatched: [IPTVChannel] {
        let historyIds = UserDataManager.shared.recentlyWatched.filter { $0.mediaType == .liveTV }.map { $0.id }
        return allChannels.filter { historyIds.contains($0.toUnified.id) }
    }
    
    var trendingChannels: [IPTVChannel] {
        Array(allChannels.prefix(10))
    }
    
    func loadData() async {
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
            
            // Auto-play the first channel in the mini player if none selected yet
            if self.activeChannelForMiniPlayer == nil, let first = channels.first {
                self.activeChannelForMiniPlayer = first
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
