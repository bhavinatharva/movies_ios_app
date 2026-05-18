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
    var trendingSeries: [UnifiedMediaItem] = []
    var popularSeries: [UnifiedMediaItem] = []
    var recommended: [UnifiedMediaItem] = []
    var topRated: [UnifiedMediaItem] = []
    var recentlyAdded: [UnifiedMediaItem] = []
    
    var isLoading = false
    var isLoadingSeries = false
    var errorMessage: String?
    var searchText = ""
    
    private let iptvService = IPTVService.shared
    private let authManager = AuthManager.shared
    
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
        // Fetch metadata collections from TMDB API
        do {
            let api = ApiServices()
            let trending = try await api.fetchTrendings(for: "tv", by: "trending")
            let popular = try await api.fetchTrendings(for: "tv", by: "popular")
            let top = try await api.fetchTrendings(for: "tv", by: "top_rated")
            let airing = try await api.fetchTrendings(for: "tv", by: "on_the_air")
            
            await MainActor.run {
                self.trendingSeries = trending.map { $0.toUnified }
                self.popularSeries = popular.map { $0.toUnified }
                self.topRated = top.map { $0.toUnified }
                self.recentlyAdded = airing.map { $0.toUnified }
                self.recommended = trending.shuffled().map { $0.toUnified }
                
                self.heroSeries = self.trendingSeries.first
            }
        } catch {
            print("Failed to fetch TMDB tv series collections: \(error)")
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
                self.isLoadingSeries = false
            }
        } catch {
            await MainActor.run {
                self.isLoadingSeries = false
            }
        }
    }
}
