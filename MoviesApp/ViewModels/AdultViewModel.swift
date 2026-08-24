//
//  AdultViewModel.swift
//  MoviesApp
//

import Foundation
import SwiftUI
import Combine

@Observable
class AdultViewModel {
    var isLoading = false
    var errorMessage: String? = nil
    
    // Loaded adult items
    var adultChannels: [UnifiedMediaItem] = []
    var adultMovies: [UnifiedMediaItem] = []
    var adultSeries: [UnifiedMediaItem] = []
    
    // Grouped by category for horizontal listing
    var groupedLive: [(category: String, items: [UnifiedMediaItem])] = []
    var groupedMovies: [(category: String, items: [UnifiedMediaItem])] = []
    var groupedSeries: [(category: String, items: [UnifiedMediaItem])] = []
    
    enum AdultTab: String, CaseIterable, Identifiable {
        case live = "Live Channels"
        case movies = "Movies"
        case series = "Series"
        
        var id: String { self.rawValue }
    }
    
    var selectedTab: AdultTab = .live
    var searchText = ""
    
    // Search filtering
    var filteredChannels: [UnifiedMediaItem] {
        if searchText.isEmpty { return adultChannels }
        return adultChannels.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
    
    var filteredMovies: [UnifiedMediaItem] {
        if searchText.isEmpty { return adultMovies }
        return adultMovies.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
    
    var filteredSeries: [UnifiedMediaItem] {
        if searchText.isEmpty { return adultSeries }
        return adultSeries.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
    
    private let iptvService = IPTVService.shared
    private let authManager = AuthManager.shared
    
    func loadAdultContent() async {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        let allLive = IPTVDataManager.shared.liveChannels
        let allMovies = IPTVDataManager.shared.movies
        let allSeries = IPTVDataManager.shared.series
        
        let (liveChs, tempGroupedLive, moviesList, tempGroupedMovies, seriesList, tempGroupedSeries) = await Task.detached(priority: .userInitiated) {
            // Live
            let filteredLive = allLive.filter { $0.isAdult }
            let mappedLive = filteredLive.map { $0.toUnified }
            var gLive: [String: [UnifiedMediaItem]] = [:]
            for channel in filteredLive {
                let catName = channel.category ?? "Live"
                gLive[catName, default: []].append(channel.toUnified)
            }
            
            // Movies
            let filteredMovies = allMovies.filter { $0.isAdult }
            var gMovies: [String: [UnifiedMediaItem]] = [:]
            for movie in filteredMovies {
                let catName = movie.genres?.first ?? "Movies"
                gMovies[catName, default: []].append(movie)
            }
            
            // Series
            let filteredSeries = allSeries.filter { $0.isAdult }
            var gSeries: [String: [UnifiedMediaItem]] = [:]
            for series in filteredSeries {
                let catName = series.genres?.first ?? "Series"
                gSeries[catName, default: []].append(series)
            }
            
            return (mappedLive, gLive, filteredMovies, gMovies, filteredSeries, gSeries)
        }.value
        
        // Also merge with any cached media in IPTVLocalDatabase if they match isAdult
        let localMovies = IPTVLocalDatabase.shared.fetchMediaItems(type: .movie).filter { $0.isAdult }
        let localSeries = IPTVLocalDatabase.shared.fetchMediaItems(type: .tvSeries).filter { $0.isAdult }
        
        // Combine and de-duplicate by ID
        var movieMap: [String: UnifiedMediaItem] = [:]
        for item in (moviesList + localMovies) {
            movieMap[item.id] = item
        }
        
        var seriesMap: [String: UnifiedMediaItem] = [:]
        for item in (seriesList + localSeries) {
            seriesMap[item.id] = item
        }
        
        await MainActor.run {
            self.adultChannels = liveChs
            self.adultMovies = Array(movieMap.values).sorted(by: { $0.title < $1.title })
            self.adultSeries = Array(seriesMap.values).sorted(by: { $0.title < $1.title })
            
            self.groupedLive = tempGroupedLive.map { ($0.key, $0.value) }.sorted(by: { $0.category < $1.category })
            self.groupedMovies = tempGroupedMovies.map { ($0.key, $0.value) }.sorted(by: { $0.category < $1.category })
            self.groupedSeries = tempGroupedSeries.map { ($0.key, $0.value) }.sorted(by: { $0.category < $1.category })
            
            // Set default selected tab dynamically
            if !self.adultChannels.isEmpty {
                self.selectedTab = .live
            } else if !self.adultMovies.isEmpty {
                self.selectedTab = .movies
            } else {
                self.selectedTab = .series
            }
            
            self.isLoading = false
        }
    }
}
