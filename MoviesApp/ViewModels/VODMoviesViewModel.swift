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
    
    var moviesByGenre: [String: [UnifiedMediaItem]] = [:]
    var loadingGenres: Set<String> = []
    
    var isLoading = false
    var isLoadingMovies = false
    var errorMessage: String?
    var searchText = ""
    
    private let iptvService = IPTVService.shared
    private let authManager = AuthManager.shared
    private var lastLoadedUrl: String? = nil
    
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
        let currentUrl = IPTVDataManager.shared.currentLoadedPlaylistUrl
        if let current = currentUrl, current == lastLoadedUrl, !categories.isEmpty {
            return
        }
        
        self.lastLoadedUrl = currentUrl
        
        // Populated entirely from the added playlist VOD movies (0 TMDB API calls!)
        let playlistMovies = IPTVDataManager.shared.movies
        
        await MainActor.run {
            if !playlistMovies.isEmpty {
                self.trendingMovies = Array(playlistMovies.shuffled().prefix(15))
                self.newReleases = Array(playlistMovies.prefix(15))
                self.topRated = Array(playlistMovies.shuffled().prefix(15))
                self.recommended = Array(playlistMovies.shuffled().prefix(15))
                self.heroMovie = playlistMovies.first
            } else {
                self.trendingMovies = []
                self.newReleases = []
                self.topRated = []
                self.recommended = []
                self.heroMovie = nil
            }
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
                for cat in cats {
                    self.moviesByGenre[cat.id] = dataManager.categorizedMovies[cat.id] ?? []
                }
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
                self.moviesByGenre[categoryId] = unifiedVods
                self.isLoadingMovies = false
            }
        } catch {
            await MainActor.run {
                self.isLoadingMovies = false
            }
        }
    }
    
    func loadMoviesIfNeeded(for categoryId: String) async {
        // If local M3U playlist, it is already cached
        guard authManager.credentials != nil else {
            await MainActor.run {
                self.moviesByGenre[categoryId] = IPTVDataManager.shared.categorizedMovies[categoryId] ?? []
            }
            return
        }
        
        // If already loaded or currently loading, skip
        if moviesByGenre[categoryId] != nil || loadingGenres.contains(categoryId) {
            return
        }
        
        await MainActor.run {
            _ = self.loadingGenres.insert(categoryId)
        }
        
        guard let creds = authManager.credentials else { return }
        
        do {
            let vods = try await iptvService.fetchVODStreams(creds: creds, categoryId: categoryId)
            let unifiedVods = vods.map { UnifiedMediaItem(from: $0, creds: creds) }
            await MainActor.run {
                self.moviesByGenre[categoryId] = unifiedVods
                self.loadingGenres.remove(categoryId)
            }
        } catch {
            await MainActor.run {
                self.loadingGenres.remove(categoryId)
            }
        }
    }
}
