//
//  HomeViewModel.swift
//  MoviesApp
//

import Foundation
import SwiftUI

@Observable
class HomeViewModel {
    var dataManager = IPTVDataManager.shared
    
    var trendingMovies: [UnifiedMediaItem] = []
    var top10Movies: [UnifiedMediaItem] = []
    var recentlyAdded: [UnifiedMediaItem] = []
    var recommended: [UnifiedMediaItem] = []
    
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
    
    var sportsLiveNow: [UnifiedMediaItem] {
        dataManager.liveChannels.filter { ch in
            let cat = (ch.category ?? "").lowercased()
            let name = ch.name.lowercased()
            return cat.contains("sport") || cat.contains("espn") || cat.contains("bein") || cat.contains("supersport") || cat.contains("sky") || cat.contains("live") || name.contains("sport")
        }.map { $0.toUnified }
    }
    
    var favorites: [UnifiedMediaItem] {
        let favIds = UserDataManager.shared.favorites
        var items: [UnifiedMediaItem] = []
        for ch in dataManager.liveChannels {
            let unified = ch.toUnified
            if favIds.contains(unified.id) {
                items.append(unified)
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
        return items
    }
    
    func refreshContent() async {
        await dataManager.refreshContent()
        
        do {
            let api = ApiServices()
            let trending = try await api.fetchTrendings(for: "movie", by: "trending")
            let topRated = try await api.fetchTrendings(for: "movie", by: "top_rated")
            let upcoming = try await api.fetchTrendings(for: "movie", by: "upcoming")
            
            await MainActor.run {
                self.trendingMovies = trending.map { $0.toUnified }
                self.top10Movies = Array(topRated.prefix(10)).map { $0.toUnified }
                self.recommended = upcoming.map { $0.toUnified }
                
                if !self.dataManager.movies.isEmpty {
                    self.recentlyAdded = Array(self.dataManager.movies.prefix(15))
                } else {
                    self.recentlyAdded = trending.shuffled().map { $0.toUnified }
                }
            }
        } catch {
            print("Failed to fetch TMDB home metadata: \(error)")
        }
    }
}
