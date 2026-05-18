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
    
    var heroMovie: UnifiedMediaItem?
    var trendingMovies: [UnifiedMediaItem] = []
    var newReleases: [UnifiedMediaItem] = []
    var recommended: [UnifiedMediaItem] = []
    var topRated: [UnifiedMediaItem] = []
    
    var isLoading = false
    var isLoadingMovies = false
    var errorMessage: String?
    var searchText = ""
    
    private let iptvService = IPTVService.shared
    private let authManager = AuthManager.shared
    
    var continueWatching: [UnifiedMediaItem] {
        UserDataManager.shared.recentlyWatched.filter { $0.mediaType == .movie }
    }
    
    var filteredMovies: [UnifiedMediaItem] {
        if searchText.isEmpty {
            return movies
        } else {
            return movies.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    func loadCategories() async {
        // Fetch metadata collections from TMDB API
        do {
            let api = ApiServices()
            let trending = try await api.fetchTrendings(for: "movie", by: "trending")
            let upcoming = try await api.fetchTrendings(for: "movie", by: "upcoming")
            let top = try await api.fetchTrendings(for: "movie", by: "top_rated")
            
            await MainActor.run {
                self.trendingMovies = trending.map { $0.toUnified }
                self.newReleases = upcoming.map { $0.toUnified }
                self.topRated = top.map { $0.toUnified }
                self.recommended = trending.shuffled().map { $0.toUnified }
                
                self.heroMovie = self.trendingMovies.first
            }
        } catch {
            print("Failed to fetch TMDB movie tab collections: \(error)")
        }
        
        guard let creds = authManager.credentials else {
            // Support local M3U Movies
            await MainActor.run {
                self.isLoading = true
                self.errorMessage = nil
            }
            
            let dataManager = IPTVDataManager.shared
            let cats = dataManager.categorizedMovies.keys.sorted().map { name in
                XtreamCategory(id: name, name: name)
            }
            
            await MainActor.run {
                self.categories = cats
                if let firstCat = cats.first {
                    self.selectedCategory = firstCat
                    self.movies = dataManager.categorizedMovies[firstCat.id] ?? []
                    if self.heroMovie == nil {
                        self.heroMovie = self.movies.first
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
        
        guard authManager.credentials != nil else {
            // Support local M3U Movies
            self.movies = IPTVDataManager.shared.categorizedMovies[category.id] ?? []
            return
        }
        
        Task {
            await loadMovies(for: category.id)
        }
    }
    
    private func loadMovies(for categoryId: String) async {
        guard let creds = authManager.credentials else { return }
        
        await MainActor.run {
            self.isLoadingMovies = true
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
