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
        
        // 1. Get adult live channels
        let liveChs = IPTVDataManager.shared.liveChannels
            .filter { $0.isAdult }
            .map { $0.toUnified }
        
        // 2. Fetch/Filter Movies & Series
        var moviesList: [UnifiedMediaItem] = []
        var seriesList: [UnifiedMediaItem] = []
        
        if let creds = authManager.credentials {
            // Xtream Codes: Fetch adult VOD & series categories, and then load streams for those categories
            do {
                // Fetch VOD Categories
                let vodCats = try await iptvService.fetchVODCategories(creds: creds)
                let adultVodCats = vodCats.filter { isAdultString($0.name) }
                
                // Fetch Series Categories
                let seriesCats = try await iptvService.fetchSeriesCategories(creds: creds)
                let adultSeriesCats = seriesCats.filter { isAdultString($0.name) }
                
                // Load VOD streams for adult categories concurrently
                await withTaskGroup(of: [UnifiedMediaItem].self) { group in
                    for cat in adultVodCats {
                        group.addTask {
                            do {
                                let streams = try await self.iptvService.fetchVODStreams(creds: creds, categoryId: cat.id)
                                return streams.map { UnifiedMediaItem(from: $0, creds: creds) }
                            } catch {
                                return []
                            }
                        }
                    }
                    
                    for await items in group {
                        moviesList.append(contentsOf: items)
                    }
                }
                
                // Load series for adult categories concurrently
                await withTaskGroup(of: [UnifiedMediaItem].self) { group in
                    for cat in adultSeriesCats {
                        group.addTask {
                            do {
                                let series = try await self.iptvService.fetchSeries(creds: creds, categoryId: cat.id)
                                return series.map { UnifiedMediaItem(from: $0) }
                            } catch {
                                return []
                            }
                        }
                    }
                    
                    for await items in group {
                        seriesList.append(contentsOf: items)
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to fetch adult content from IPTV server: \(error.localizedDescription)"
                }
            }
        } else {
            // M3U Playlist: Everything is already in IPTVDataManager
            moviesList = IPTVDataManager.shared.movies.filter { $0.isAdult }
            seriesList = IPTVDataManager.shared.series.filter { $0.isAdult }
        }
        
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
