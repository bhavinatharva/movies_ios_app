//
//  IPTVDataManager.swift
//
//  Created by Antigravity on 18/05/26.
//

import Foundation
import SwiftUI
import Combine

enum IPTVTab: String, CaseIterable, Identifiable, Codable {
    case home
    case recent
    case liveTV
    case movies
    case series
    
    var id: String { self.rawValue }
    
    var title: String {
        switch self {
        case .home: return "Home"
        case .recent: return "Recent"
        case .liveTV: return "Live TV"
        case .movies: return "Movies"
        case .series: return "Series"
        }
    }
    
    var systemImage: String {
        switch self {
        case .home: return "house.fill"
        case .recent: return "clock.fill"
        case .liveTV: return "tv.fill"
        case .movies: return "film.fill"
        case .series: return "play.tv.fill"
        }
    }
}

@MainActor
@Observable
class IPTVDataManager {
    static let shared = IPTVDataManager()
    
    var homeStatus: ApiFetchStatus = .notstarted
    var availableTabs: [IPTVTab] = [.home, .recent]
    
    // Loaded Playlist State
    var currentLoadedPlaylistUrl: String? = nil
    
    var importProgress: Double? = nil
    
    // Classified data arrays
    var liveChannels: [IPTVChannel] = []
    var movies: [UnifiedMediaItem] = []
    var series: [UnifiedMediaItem] = []
    var uncategorized: [UnifiedMediaItem] = []
    
    // Categorized stores for fast retrieval
    var categorizedChannels: [String: [IPTVChannel]] = [:]
    var categorizedMovies: [String: [UnifiedMediaItem]] = [:]
    var categorizedSeries: [String: [UnifiedMediaItem]] = [:]
    
    // Categories metadata
    var vodCategories: [XtreamCategory] = []
    var seriesCategories: [XtreamCategory] = []
    
    // Curated content for Movies
    var heroMovie: UnifiedMediaItem?
    var trendingMovies: [UnifiedMediaItem] = []
    var newReleases: [UnifiedMediaItem] = []
    var recommendedMovies: [UnifiedMediaItem] = []
    var topRatedMovies: [UnifiedMediaItem] = []
    
    // Curated content for Series
    var heroSeries: UnifiedMediaItem?
    var trendingSeries: [UnifiedMediaItem] = []
    var newReleaseSeries: [UnifiedMediaItem] = []
    var recommendedSeries: [UnifiedMediaItem] = []
    var topRatedSeries: [UnifiedMediaItem] = []
    
    // Cache for M3U TV Series Episodes
    var m3uEpisodes: [String: [String: [XtreamEpisode]]] = [:]
    
    private let playlistManager = PlaylistManager.shared
    
    private init() {
        IPTVLocalDatabase.shared.wipeCacheIfNeeded()
        
        Task {
            if let defaultPlaylist = playlistManager.fetchDefaultPlaylist() {
                await loadFromCache(playlist: defaultPlaylist)
            }
        }
    }
    
    func cancelImport() {
        if let defaultPlaylist = playlistManager.fetchDefaultPlaylist() {
            IPTVSyncManager.shared.cancelSync(playlistId: defaultPlaylist.id)
        }
        self.importProgress = nil
    }
    
    func loadFromCache(playlist: Playlist) async {
        await MainActor.run {
            self.homeStatus = .loading
        }
        
        let live = IPTVLocalDatabase.shared.fetchChannels(playlistId: playlist.id)
        let movies = IPTVLocalDatabase.shared.fetchMediaItems(type: .movie, playlistId: playlist.id)
        let series = IPTVLocalDatabase.shared.fetchMediaItems(type: .tvSeries, playlistId: playlist.id)
        
        let vCats = IPTVLocalDatabase.shared.fetchCategories(type: "vod", playlistId: playlist.id)
        let sCats = IPTVLocalDatabase.shared.fetchCategories(type: "series", playlistId: playlist.id)
        
        let catLive = Dictionary(grouping: live) { $0.category ?? "General" }
        let catMovies = Dictionary(grouping: movies) { $0.genres?.first ?? "General" }
        let catSeries = Dictionary(grouping: series) { $0.genres?.first ?? "General" }
        
        let (trending, newR, topR, recs, hero, tSeries, nSeries, topSeries, rSeries, hSeries) = await Task.detached(priority: .userInitiated) {
            var itemsForTrending = movies
            let trendingList = IPTVDataManager.pickRandom(&itemsForTrending, limit: 15)
            let newReleasesList = Array(movies.prefix(15))
            var itemsForTop = movies
            let topRatedList = IPTVDataManager.pickRandom(&itemsForTop, limit: 15)
            let recommendedList = UserDataManager.shared.generateRecommendations(from: movies)
            
            var itemsForTrendingSeries = series
            let tSeriesList = IPTVDataManager.pickRandom(&itemsForTrendingSeries, limit: 15)
            let nSeriesList = Array(series.prefix(15))
            var itemsForTopSeries = series
            let topSeriesList = IPTVDataManager.pickRandom(&itemsForTopSeries, limit: 15)
            let rSeriesList = UserDataManager.shared.generateRecommendations(from: series)
            
            return (trendingList, newReleasesList, topRatedList, recommendedList, movies.first, tSeriesList, nSeriesList, topSeriesList, rSeriesList, series.first)
        }.value
        
        await MainActor.run {
            self.liveChannels = live
            self.categorizedChannels = catLive
            
            self.movies = movies
            self.categorizedMovies = catMovies
            self.vodCategories = vCats
            
            self.heroMovie = hero
            self.trendingMovies = trending
            self.newReleases = newR
            self.topRatedMovies = topR
            self.recommendedMovies = recs
            
            self.series = series
            self.categorizedSeries = catSeries
            self.seriesCategories = sCats
            
            self.heroSeries = hSeries
            self.trendingSeries = tSeries
            self.newReleaseSeries = nSeries
            self.topRatedSeries = topSeries
            self.recommendedSeries = rSeries
            
            var tabs: [IPTVTab] = [.home, .recent]
            if !live.isEmpty { tabs.append(.liveTV) }
            if !movies.isEmpty { tabs.append(.movies) }
            if !series.isEmpty { tabs.append(.series) }
            
            self.availableTabs = tabs
            self.homeStatus = .success
            self.currentLoadedPlaylistUrl = playlist.url
        }
    }
    
    private var syncObservationTask: Task<Void, Never>? = nil
    
    private func setupSyncObserver(playlistId: String) {
        syncObservationTask?.cancel()
        syncObservationTask = Task {
            for await _ in NotificationCenter.default.notifications(named: .NSCalendarDayChanged) {
                // Not really used, but we can poll or use withObservationTracking
                // Let's rely on the direct fetcher UI updates for now.
            }
        }
    }
    
    // MARK: - API Fallbacks for specific lazy calls
    
    // Refresh content has been replaced by background fetching and local DB cache.
    // Call loadFromCache() to pull from database.
    func refreshContent(clearFirst: Bool = false) async {
        guard let defaultPlaylist = playlistManager.fetchDefaultPlaylist() else { return }
        await loadFromCache(playlist: defaultPlaylist)
    }
    
    nonisolated static func pickRandom<T>(_ array: inout [T], limit: Int) -> [T] {
        var result: [T] = []
        let count = min(limit, array.count)
        for i in 0..<count {
            let randomIndex = Int.random(in: i..<array.count)
            array.swapAt(i, randomIndex)
            result.append(array[i])
        }
        return result
    }
}
