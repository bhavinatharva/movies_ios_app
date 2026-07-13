//
//  HomeViewModel.swift
//  MoviesApp
//

import Foundation
import SwiftUI

@Observable
class HomeViewModel {
    var dataManager = IPTVDataManager.shared
    
    private var lastLoadedUrl: String? = nil
    
    var movieCollections: [MovieCollection] = []
    var top10Movies: [UnifiedMediaItem] = []
    var recentlyAdded: [UnifiedMediaItem] = []
    var recommended: [UnifiedMediaItem] = []
    var sportsLiveNow: [UnifiedMediaItem] = []
    var favorites: [UnifiedMediaItem] = []
    var uncategorized: [UnifiedMediaItem] = []
    
    init() {
        updateFavorites()
    }
    
    var homeStatus: ApiFetchStatus {
        dataManager.homeStatus
    }
    
    var liveChannels: [IPTVChannel] {
        dataManager.liveChannels
    }
    
    var categorizedChannels: [String: [IPTVChannel]] {
        dataManager.categorizedChannels
    }
    
    var featuredItem: UnifiedMediaItem? {
        if let movie = dataManager.movies.first {
            return movie
        }
        if let first = dataManager.liveChannels.first {
            return first.toUnified
        }
        return nil
    }
    
    var continueWatching: [UnifiedMediaItem] {
        UserDataManager.shared.recentlyWatched.filter { $0.mediaType != .tvSeries }
    }
    
    var seriesContinueWatching: [UnifiedMediaItem] {
        UserDataManager.shared.recentlyWatched.filter { $0.mediaType == .tvSeries }
    }
    
    func updateFavorites() {
        let favIds = UserDataManager.shared.favorites
        if favIds.isEmpty {
            self.favorites = []
            return
        }
        
        var items: [UnifiedMediaItem] = []
        for ch in dataManager.liveChannels {
            if favIds.contains(ch.toUnified.id) {
                items.append(ch.toUnified)
            }
        }
        for mv in dataManager.movies {
            if favIds.contains(mv.id) {
                items.append(mv)
            }
        }
        for sr in dataManager.series {
            if favIds.contains(sr.id) {
                items.append(sr)
            }
        }
        self.favorites = items
    }
    
    func refreshContent() async {
        await dataManager.refreshContent()
        
        let currentUrl = dataManager.currentLoadedPlaylistUrl
        if let current = currentUrl, current == lastLoadedUrl, !top10Movies.isEmpty || dataManager.movies.isEmpty {
            await MainActor.run {
                self.updateFavorites()
            }
            return
        }
        
        self.lastLoadedUrl = currentUrl
        
        // Priority 1: Load Favorites and Continue Watching (instant local cache)
        await MainActor.run {
            self.updateFavorites()
        }
        
        // Priority 2: Load Live TV and Live Sport listings
        try? await Task.sleep(for: .milliseconds(50))
        await MainActor.run {
            self.sportsLiveNow = self.dataManager.liveChannels.filter { ch in
                let cat = (ch.category ?? "").lowercased()
                let name = ch.name.lowercased()
                return cat.contains("sport") || cat.contains("espn") || cat.contains("bein") || cat.contains("supersport") || cat.contains("sky") || cat.contains("live") || name.contains("sport")
            }.prefix(15).map { $0.toUnified }
        }
        
        // Priority 3: Load top trending VOD items
        try? await Task.sleep(for: .milliseconds(50))
        await MainActor.run {
            let playlistMovies = self.dataManager.movies
            if !playlistMovies.isEmpty {
                self.top10Movies = Array(playlistMovies.sorted {
                    ($0.voteAverage ?? 0) > ($1.voteAverage ?? 0)
                }.prefix(10))
            } else {
                self.top10Movies = []
            }
        }
        
        // Priority 4: Load recommended and recently added rails progressively
        try? await Task.sleep(for: .milliseconds(50))
        await MainActor.run {
            let playlistMovies = self.dataManager.movies
            if !playlistMovies.isEmpty {
                self.recommended = UserDataManager.shared.generateRecommendations(from: playlistMovies)
                self.recentlyAdded = Array(playlistMovies.sorted {
                    let d1 = $0.addedDate ?? Date.distantPast
                    let d2 = $1.addedDate ?? Date.distantPast
                    if d1 == d2 {
                        // Fallback to releaseDate year comparison if addedDate is identical or missing
                        let y1 = Int($0.releaseDate ?? "0") ?? 0
                        let y2 = Int($1.releaseDate ?? "0") ?? 0
                        return y1 > y2
                    }
                    return d1 > d2
                }.prefix(15))
            } else {
                self.recommended = []
                self.recentlyAdded = []
            }
            self.uncategorized = self.dataManager.uncategorized
        }
        
        // Priority 5: Group movies into smart collections (Background thread)
        Task.detached(priority: .background) {
            let playlistMovies = await self.dataManager.movies
            let grouped = CollectionGroupingService.shared.groupMovies(playlistMovies)
            await MainActor.run {
                self.movieCollections = grouped
            }
        }
    }
}
