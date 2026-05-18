//
//  HomeViewModel.swift
//  MoviesApp
//

import Foundation
import SwiftUI

@Observable
class HomeViewModel {
    private(set) var homeStatus = ApiFetchStatus.notstarted
    private let iptvService = IPTVService.shared
    private let authManager = AuthManager.shared
    
    var featuredItem: UnifiedMediaItem?
    var liveCategories: [XtreamCategory] = []
    var moviesCarousel: [UnifiedMediaItem] = []
    var seriesCarousel: [UnifiedMediaItem] = []
    var continueWatching: [UnifiedMediaItem] = []
    
    func refreshContent() async {
        guard let creds = authManager.credentials else {
            await MainActor.run {
                self.homeStatus = .notstarted
            }
            return
        }
        
        await MainActor.run {
            self.homeStatus = .loading
            self.continueWatching = UserDataManager.shared.recentlyWatched
        }
        
        do {
            // Load Live Categories
            let fetchedLiveCats = try await iptvService.fetchLiveCategories(creds: creds)
            
            // Load some movies for the VOD carousel
            let fetchedVODCats = try await iptvService.fetchVODCategories(creds: creds)
            var fetchedMovies: [UnifiedMediaItem] = []
            if let firstVODCat = fetchedVODCats.first {
                let vods = try await iptvService.fetchVODStreams(creds: creds, categoryId: firstVODCat.id)
                fetchedMovies = Array(vods.prefix(10).map { UnifiedMediaItem(from: $0, creds: creds) })
            }
            
            // Load some series for the TV carousel
            let fetchedSeriesCats = try await iptvService.fetchSeriesCategories(creds: creds)
            var fetchedSeries: [UnifiedMediaItem] = []
            if let firstSeriesCat = fetchedSeriesCats.first {
                let series = try await iptvService.fetchSeries(creds: creds, categoryId: firstSeriesCat.id)
                fetchedSeries = Array(series.prefix(10).map { UnifiedMediaItem(from: $0) })
            }
            
            await MainActor.run {
                self.liveCategories = fetchedLiveCats
                self.moviesCarousel = fetchedMovies
                self.seriesCarousel = fetchedSeries
                
                // Select a featured item from movies
                if let firstMovie = fetchedMovies.first {
                    self.featuredItem = firstMovie
                } else if let firstSeries = fetchedSeries.first {
                    self.featuredItem = firstSeries
                }
                
                self.homeStatus = .success
            }
        } catch {
            await MainActor.run {
                self.homeStatus = .error(underlyingError: error)
            }
        }
    }
}
