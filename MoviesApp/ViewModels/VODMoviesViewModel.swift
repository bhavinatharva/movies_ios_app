//
//  VODMoviesViewModel.swift
//  MoviesApp
//

import Foundation
import SwiftUI

@Observable
class VODMoviesViewModel {
    var categories: [XtreamCategory] = []
    var movies: [UnifiedMediaItem] = []
    var selectedCategory: XtreamCategory?
    
    var isLoading = false
    var isLoadingMovies = false
    var errorMessage: String?
    var searchText = ""
    
    private let iptvService = IPTVService.shared
    private let authManager = AuthManager.shared
    
    var filteredMovies: [UnifiedMediaItem] {
        if searchText.isEmpty {
            return movies
        } else {
            return movies.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    func loadCategories() async {
        guard let creds = authManager.credentials else { return }
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let cats = try await iptvService.fetchVODCategories(creds: creds)
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
            await loadMovies(for: category.id)
        }
    }
    
    private func loadMovies(for categoryId: String) async {
        guard let creds = authManager.credentials else { return }
        
        await MainActor.run {
            isLoadingMovies = true
        }
        
        do {
            let vods = try await iptvService.fetchVODStreams(creds: creds, categoryId: categoryId)
            let unifiedVods = vods.map { UnifiedMediaItem(from: $0, creds: creds) }
            await MainActor.run {
                self.movies = unifiedVods
                self.isLoadingMovies = false
            }
        } catch {
            await MainActor.run {
                self.isLoadingMovies = false
            }
        }
    }
}
