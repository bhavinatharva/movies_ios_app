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
        guard let creds = authManager.credentials else { return }
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
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
        Task {
            await loadSeries(for: category.id)
        }
    }
    
    private func loadSeries(for categoryId: String) async {
        guard let creds = authManager.credentials else { return }
        
        await MainActor.run {
            isLoadingSeries = true
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
