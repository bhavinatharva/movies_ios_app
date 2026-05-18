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
    
    var isLoading = false
    var isLoadingSeries = false
    var errorMessage: String?
    var searchText = ""
    
    private let iptvService = IPTVService.shared
    private let authManager = AuthManager.shared
    
    var filteredSeries: [UnifiedMediaItem] {
        if searchText.isEmpty {
            return series
        } else {
            return series.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    func loadCategories() async {
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
