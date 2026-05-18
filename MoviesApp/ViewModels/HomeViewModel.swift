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
        
        await MainActor.run {
            let playlistMovies = self.dataManager.movies
            
            if !playlistMovies.isEmpty {
                // Populate categories cleanly using local slices to give a gorgeous variation
                self.trendingMovies = Array(playlistMovies.shuffled().prefix(15))
                self.top10Movies = Array(playlistMovies.prefix(10))
                self.recommended = Array(playlistMovies.shuffled().prefix(15))
                self.recentlyAdded = Array(playlistMovies.prefix(15))
            } else {
                self.trendingMovies = []
                self.top10Movies = []
                self.recommended = []
                self.recentlyAdded = []
            }
        }
    }
}
