//
//  SeriesViewModel.swift
//  MoviesApp
//

import Foundation
import SwiftUI

@Observable
class SeriesViewModel {
    var categories: [XtreamCategory] = []
    var series: [UnifiedMediaItem] = []
    var selectedCategory: XtreamCategory?
    
    var heroSeries: UnifiedMediaItem?
    var recommended: [UnifiedMediaItem] = []
    var topRated: [UnifiedMediaItem] = []
    var recentlyAdded: [UnifiedMediaItem] = []
    
    var seriesByGenre: [String: [UnifiedMediaItem]] = [:]
    var loadingGenres: Set<String> = []
    
    var isLoading = false
    var isLoadingSeries = false
    var errorMessage: String?
    var searchText = ""
    
    private let iptvService = IPTVService.shared
    private let authManager = AuthManager.shared
    private var lastLoadedUrl: String? = nil
    
    var continueWatching: [UnifiedMediaItem] {
        UserDataManager.shared.recentlyWatched.filter { $0.mediaType == .tvSeries }
    }
    
    var filteredSeries: [UnifiedMediaItem] {
        if searchText.isEmpty {
            return series
        } else {
            return series.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    func loadCategories() async {
        let currentUrl = IPTVDataManager.shared.currentLoadedPlaylistUrl
        if let current = currentUrl, current == lastLoadedUrl, !categories.isEmpty {
            return
        }
        
        self.lastLoadedUrl = currentUrl
        
        // Populated entirely from the added playlist Series (0 TMDB API calls!)
        let playlistSeries = IPTVDataManager.shared.series
        
        if !playlistSeries.isEmpty {
            let (topR, recentA, recs, hero) = await Task.detached(priority: .userInitiated) {
                let topRatedList = Array(playlistSeries.sorted {
                    ($0.voteAverage ?? 0) > ($1.voteAverage ?? 0)
                }.prefix(15))
                
                let recentlyAddedList = Array(playlistSeries.sorted {
                    let d1 = $0.addedDate ?? Date.distantPast
                    let d2 = $1.addedDate ?? Date.distantPast
                    if d1 == d2 {
                        let y1 = Int($0.releaseDate ?? "0") ?? 0
                        let y2 = Int($1.releaseDate ?? "0") ?? 0
                        return y1 > y2
                    }
                    return d1 > d2
                }.prefix(15))
                
                let recommendedList = UserDataManager.shared.generateRecommendations(from: playlistSeries)
                
                return (topRatedList, recentlyAddedList, recommendedList, playlistSeries.first)
            }.value
            
            await MainActor.run {
                self.topRated = topR
                self.recentlyAdded = recentA
                self.recommended = recs
                self.heroSeries = hero
            }
        } else {
            await MainActor.run {
                self.topRated = []
                self.recentlyAdded = []
                self.recommended = []
                self.heroSeries = nil
            }
        }
        
        guard let creds = authManager.credentials else {
            // M3U TV Series Fallback
            await MainActor.run {
                self.isLoading = true
                self.errorMessage = nil
            }
            
            let dataManager = IPTVDataManager.shared
            // Categorize by genre
            var catsMap: [String: [UnifiedMediaItem]] = [:]
            for s in dataManager.series {
                let genre = s.genres?.first ?? "General"
                if catsMap[genre] == nil {
                    catsMap[genre] = []
                }
                catsMap[genre]?.append(s)
            }
            
            let cats = catsMap.keys.sorted().map { name in
                XtreamCategory(id: name, name: name)
            }
            
            await MainActor.run {
                self.categories = cats
                for cat in cats {
                    self.seriesByGenre[cat.id] = catsMap[cat.id] ?? []
                }
                if let firstCat = cats.first {
                    self.selectedCategory = firstCat
                    self.series = catsMap[firstCat.id] ?? []
                    if self.heroSeries == nil {
                        self.heroSeries = self.series.first
                    }
                }
                self.isLoading = false
            }
            return
        }
        
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            let cats = try await iptvService.fetchSeriesCategories(creds: creds)
            await MainActor.run {
                self.categories = cats
                if let firstCat = cats.first {
                    self.selectCategory(firstCat)
                }
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func selectCategory(_ category: XtreamCategory) {
        selectedCategory = category
        
        guard authManager.credentials != nil else {
            // Support local M3U TV Series
            let dataManager = IPTVDataManager.shared
            self.series = dataManager.series.filter { ($0.genres?.first ?? "General") == category.id }
            return
        }
        
        Task {
            await loadSeries(for: category.id)
        }
    }
    
    private func loadSeries(for categoryId: String) async {
        guard let creds = authManager.credentials else { return }
        
        await MainActor.run {
            self.isLoadingSeries = true
        }
        
        do {
            let fetchedSeries = try await iptvService.fetchSeries(creds: creds, categoryId: categoryId)
            let unifiedSeries = fetchedSeries.map { UnifiedMediaItem(from: $0) }
            await MainActor.run {
                self.series = unifiedSeries
                self.seriesByGenre[categoryId] = unifiedSeries
                self.isLoadingSeries = false
            }
        } catch {
            await MainActor.run {
                self.isLoadingSeries = false
            }
        }
    }
    
    func loadSeriesIfNeeded(for categoryId: String) async {
        // If local M3U playlist, it is already cached
        guard authManager.credentials != nil else {
            let dataManager = IPTVDataManager.shared
            let localSeries = dataManager.series.filter { ($0.genres?.first ?? "General") == categoryId }
            await MainActor.run {
                self.seriesByGenre[categoryId] = localSeries
            }
            return
        }
        
        // If already loaded or currently loading, skip
        if seriesByGenre[categoryId] != nil || loadingGenres.contains(categoryId) {
            return
        }
        
        await MainActor.run {
            _ = self.loadingGenres.insert(categoryId)
        }
        
        guard let creds = authManager.credentials else { return }
        
        do {
            let fetchedSeries = try await iptvService.fetchSeries(creds: creds, categoryId: categoryId)
            let unifiedSeries = fetchedSeries.map { UnifiedMediaItem(from: $0) }
            _ = await MainActor.run {
                self.seriesByGenre[categoryId] = unifiedSeries
                self.loadingGenres.remove(categoryId)
            }
        } catch {
            _ = await MainActor.run {
                self.loadingGenres.remove(categoryId)
            }
        }
    }
}
