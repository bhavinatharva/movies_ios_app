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
        
        // Copy arrays locally to avoid threading issues with dataManager
        let liveChannels = dataManager.liveChannels
        let movies = dataManager.movies
        let series = dataManager.series
        
        Task.detached(priority: .userInitiated) {
            var items: [UnifiedMediaItem] = []
            for ch in liveChannels {
                if favIds.contains(ch.toUnified.id) {
                    items.append(ch.toUnified)
                }
            }
            for mv in movies {
                if favIds.contains(mv.id) {
                    items.append(mv)
                }
            }
            for sr in series {
                if favIds.contains(sr.id) {
                    items.append(sr)
                }
            }
            await MainActor.run {
                self.favorites = items
            }
        }
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
        
        let channels = self.dataManager.liveChannels
        let movies = self.dataManager.movies
        let uncategorizedMovies = self.dataManager.uncategorized
        
        let (sports, top10, recs, recentA) = await Task.detached(priority: .userInitiated) {
            let sportsChannels = channels.filter { ch in
                let cat = (ch.category ?? "").lowercased()
                let name = ch.name.lowercased()
                return cat.contains("sport") || cat.contains("espn") || cat.contains("bein") || cat.contains("supersport") || cat.contains("sky") || cat.contains("live") || name.contains("sport")
            }.prefix(15).map { $0.toUnified }
            
            let top10List = Array(movies.sorted {
                ($0.voteAverage ?? 0) > ($1.voteAverage ?? 0)
            }.prefix(10))
            
            let recList = UserDataManager.shared.generateRecommendations(from: movies)
            
            let recentList = Array(movies.sorted {
                let d1 = $0.addedDate ?? Date.distantPast
                let d2 = $1.addedDate ?? Date.distantPast
                if d1 == d2 {
                    let y1 = Int($0.releaseDate ?? "0") ?? 0
                    let y2 = Int($1.releaseDate ?? "0") ?? 0
                    return y1 > y2
                }
                return d1 > d2
            }.prefix(15))
            
            return (sportsChannels, top10List, recList, recentList)
        }.value
        
        await MainActor.run {
            self.sportsLiveNow = sports
            self.top10Movies = top10
            self.recommended = recs
            self.recentlyAdded = recentA
            self.uncategorized = uncategorizedMovies
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
