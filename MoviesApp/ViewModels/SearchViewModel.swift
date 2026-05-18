//
//  SearchViewModel.swift
//  MoviesApp
//
//  Created by Bhavin Parghi on 11/11/25.
//

import Foundation

@Observable
class SearchViewModel {
    private(set) var searchingStatus = ApiFetchStatus.notstarted
    private(set) var errorMessage: String?
    
    private let apiService = ApiServices()
    var searchingMovies: [TrendingModel] = []
    var iptvResults: [UnifiedMediaItem] = []
    
    func getSearchMovies(for type: String, searchPhase: String) async {
        do {
            if searchPhase.isEmpty {
                searchingMovies = try await apiService.fetchTrendings(for: type, by: "trending")
            } else {
                searchingMovies = try await apiService.fetchTrendings(for: type, by: "search", searchBy: searchPhase)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // High-performance background search for massive IPTV local datasets
    func getSearchIPTV(searchPhase: String) async {
        let query = searchPhase.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty {
            await MainActor.run {
                self.iptvResults = []
            }
            return
        }
        
        let results = await Task.detached(priority: .userInitiated) {
            var tempResults: [UnifiedMediaItem] = []
            
            // 1. Search in local cached VOD Movies
            let moviesList = await IPTVDataManager.shared.movies
            for item in moviesList {
                if item.title.lowercased().contains(query) {
                    tempResults.append(item)
                }
            }
            
            // 2. Search in local cached Series
            let seriesList = await IPTVDataManager.shared.series
            for item in seriesList {
                if item.title.lowercased().contains(query) {
                    tempResults.append(item)
                }
            }
            
            // 3. Search in Live TV Channels
            let channelsList = await IPTVDataManager.shared.liveChannels
            for item in channelsList {
                if item.name.lowercased().contains(query) {
                    tempResults.append(item.toUnified)
                }
            }
            
            return tempResults
        }.value
        
        await MainActor.run {
            self.iptvResults = results
        }
    }
}
