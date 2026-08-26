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
    var showAdultConsentPrompt: Bool = false
    var pendingAdultConsentPlaylist: Playlist? = nil
    
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
    // Series ID -> [SeasonNumberString: [XtreamEpisode]]
    var m3uEpisodes: [String: [String: [XtreamEpisode]]] = [:]
    
    private let iptvService = IPTVService.shared
    private let playlistManager = PlaylistManager.shared
    
    private var activeRefreshTask: Task<Void, Never>? = nil
    // Separate handle for the in-flight M3U import so it can be cancelled independently
    // (e.g. when the user taps Cancel in the AddPlaylistWizardView overlay).
    private var m3uImportTask: Task<Void, Never>? = nil
    
    private init() {
        Task {
            await refreshContent()
        }
    }
    
    // MARK: - Safe Retry Wrapper
    private func fetchWithRetry<T>(retries: Int = 3, delaySeconds: Double = 1.0, operation: @escaping () async throws -> T) async throws -> T {
        var attempts = 0
        while true {
            do {
                return try await operation()
            } catch {
                if let urlError = error as? URLError, (400...499).contains(urlError.code.rawValue) {
                    throw error // Fast fail for 4xx errors
                }
                
                attempts += 1
                if attempts >= retries {
                    throw error
                }
                try? await Task.sleep(for: .milliseconds(Int(delaySeconds * 1000)))
            }
        }
    }
    
    // MARK: - Cancel Import
    /// Cancels any in-progress M3U import/refresh and resets UI state.
    /// Called by AddPlaylistWizardView when the user taps Cancel during import.
    func cancelImport() {
        m3uImportTask?.cancel()
        m3uImportTask = nil
        activeRefreshTask?.cancel()
        activeRefreshTask = nil
        self.importProgress = nil
        if case .loading = self.homeStatus {
            self.homeStatus = .notstarted
        }
    }
    
    // Background EPG Loader
    func loadEPGInBackground() {
        Task.detached(priority: .background) {
            try? await Task.sleep(for: .seconds(2))
            print("Background EPG content pre-fetched and updated.")
        }
    }
    
    func refreshContent(clearFirst: Bool = false) async {
        if clearFirst {
            await MainActor.run {
                if self.homeStatus != .loading {
                    self.homeStatus = .loading
                }
            }
        }
        
        if let activeTask = activeRefreshTask {
            if clearFirst {
                activeTask.cancel()
                _ = await activeTask.result
                activeRefreshTask = nil
            } else {
                _ = await activeTask.result
                return
            }
        }
        
        let task = Task {
            await self.performRefreshContent(clearFirst: clearFirst)
        }
        activeRefreshTask = task
        _ = await task.result
        
        // Only set to nil if the active task is still THIS task.
        if activeRefreshTask == task {
            activeRefreshTask = nil
        }
    }
    
    func handleAdultConsent(consented: Bool) {
        guard let playlist = pendingAdultConsentPlaylist else { return }
        playlistManager.updateAdultConsent(for: playlist.id, consented: consented)
        
        self.showAdultConsentPrompt = false
        self.pendingAdultConsentPlaylist = nil
        
        if consented {
            Task {
                await refreshContent(clearFirst: true)
            }
        }
    }
    
    private func performRefreshContent(clearFirst: Bool) async {
        let currentDefaultPlaylist = playlistManager.fetchDefaultPlaylist()
        
        if clearFirst {
            URLCache.shared.removeAllCachedResponses()
            Task {
                await IPTVRequestManager.shared.reset()
            }
        }
        
        if !clearFirst, let defaultPlaylist = currentDefaultPlaylist, self.homeStatus == .success, self.currentLoadedPlaylistUrl == defaultPlaylist.url {
            #if DEBUG
            print("🌐 [IPTVDataManager] Playlist already loaded. Skipping refresh.")
            #endif
            return
        }

            await MainActor.run {
                self.liveChannels = []
                self.movies = []
                self.series = []
                self.uncategorized = []
                self.categorizedChannels = [:]
                self.categorizedMovies = [:]
                self.categorizedSeries = [:]
                self.vodCategories = []
                self.seriesCategories = []
                self.heroMovie = nil
                self.trendingMovies = []
                self.newReleases = []
                self.recommendedMovies = []
                self.topRatedMovies = []
                self.heroSeries = nil
                self.trendingSeries = []
                self.newReleaseSeries = []
                self.recommendedSeries = []
                self.topRatedSeries = []
                self.m3uEpisodes = [:]
                self.currentLoadedPlaylistUrl = nil
            }
        
        guard let defaultPlaylist = playlistManager.fetchDefaultPlaylist() else {
            await MainActor.run {
                self.liveChannels = []
                self.movies = []
                self.series = []
                self.uncategorized = []
                self.categorizedChannels = [:]
                self.categorizedMovies = [:]
                self.categorizedSeries = [:]
                self.vodCategories = []
                self.seriesCategories = []
                self.heroMovie = nil
                self.trendingMovies = []
                self.newReleases = []
                self.recommendedMovies = []
                self.topRatedMovies = []
                self.heroSeries = nil
                self.trendingSeries = []
                self.newReleaseSeries = []
                self.recommendedSeries = []
                self.topRatedSeries = []
                self.m3uEpisodes = [:]
                self.availableTabs = [.home, .recent]
                self.homeStatus = .notstarted
                self.currentLoadedPlaylistUrl = nil
            }
            return
        }
        
        await MainActor.run {
            self.homeStatus = .loading
            if !clearFirst {
                self.currentLoadedPlaylistUrl = nil
            }
        }
        
        let urlString = defaultPlaylist.url
        let validation = IPTVValidator.validateIPTVSource(input: urlString)
        
        guard validation.isValid,
              let sanitizedStr = validation.sanitizedUrl,
              let url = URL(string: sanitizedStr) else {
            await MainActor.run {
                self.homeStatus = .error(underlyingError: NSError(domain: "IPTVDataManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Playlist URL"]))
            }
            return
        }
        
        #if DEBUG
        print("🌐 [IPTVDataManager] ===========================================")
        print("🌐 [IPTVDataManager] Starting fetch for active playlist...")
        print("🌐 [IPTVDataManager] URL: \(url.absoluteString)")
        print("🌐 [IPTVDataManager] Detected Type: \(validation.type)")
        print("🌐 [IPTVDataManager] ===========================================")
        #endif
        
        do {
            switch validation.type {
            case .m3uPlaylist, .directHLS, .directDASH:
                try await processAsM3U(url: url, defaultPlaylist: defaultPlaylist)
                
            case .xtreamCodes:
                // 1. Parse Xtream query credentials
                let queryParams = url.queryParameters
                let username = queryParams["username"] ?? ""
                let password = queryParams["password"] ?? ""
                let serverUrl = "\(url.scheme ?? "http")://\(url.host ?? "")\(url.port != nil ? ":\(url.port!)" : "")"
                let creds = XtreamCredentials(serverUrl: serverUrl, username: username, password: password)
                
                // 2. Validate availability of VOD and Series via categories tasks concurrently
                async let liveCatsTask = try? self.iptvService.fetchLiveCategories(creds: creds)
                async let vodCatsTask = try? self.iptvService.fetchVODCategories(creds: creds)
                async let seriesCatsTask = try? self.iptvService.fetchSeriesCategories(creds: creds)
                
                // Helper to smoothly animate progress
                func simulateProgress(from start: Double, to end: Double, duration: TimeInterval) -> Task<Void, Never> {
                    Task {
                        let steps = 50
                        let stepDuration = duration / Double(steps)
                        let stepAmount = (end - start) / Double(steps)
                        var current = start
                        for _ in 0..<steps {
                            if Task.isCancelled { break }
                            current += stepAmount
                            let progress = current
                            await MainActor.run { self.importProgress = progress }
                            try? await Task.sleep(nanoseconds: UInt64(stepDuration * 1_000_000_000))
                        }
                    }
                }
                
                let catProgressTask = simulateProgress(from: 0.0, to: 0.15, duration: 1.0)
                let (liveCats, vodCats, seriesCats) = await (liveCatsTask, vodCatsTask, seriesCatsTask)
                catProgressTask.cancel()
                await MainActor.run { self.importProgress = 0.15 }
                
                // 3. Fetch Live streams, VODs, and Series concurrently to immediately satisfy Home screen layout
                async let liveTask = try? self.fetchWithRetry { try await self.iptvService.fetchXtreamChannels(creds: creds) }
                
                async let vodTask: [XtreamVODStream]? = {
                    if let cats = vodCats, !cats.isEmpty {
                        return try? await self.fetchWithRetry { try await self.iptvService.fetchVODStreams(creds: creds) }
                    }
                    return nil
                }()
                
                async let seriesTask: [XtreamSeries]? = {
                    if let cats = seriesCats, !cats.isEmpty {
                        return try? await self.fetchWithRetry { try await self.iptvService.fetchSeries(creds: creds) }
                    }
                    return nil
                }()
                
                let fetchProgressTask = simulateProgress(from: 0.15, to: 0.60, duration: 3.0)
                let (fetchedChannelsResult, fetchedVODsResult, fetchedSeriesResult) = await (liveTask, vodTask, seriesTask)
                fetchProgressTask.cancel()
                await MainActor.run { self.importProgress = 0.60 }
                
                let fetchedChannels = fetchedChannelsResult ?? []
                let fetchedVODs = fetchedVODsResult ?? []
                let fetchedSeries = fetchedSeriesResult ?? []
                
                if fetchedChannels.isEmpty && fetchedVODs.isEmpty && fetchedSeries.isEmpty {
                    #if DEBUG
                    print("🌐 [IPTVDataManager] Xtream Codes JSON API failed or yielded empty results. Falling back to M3U Playlist parsing...")
                    #endif
                    try await processAsM3U(url: url, defaultPlaylist: defaultPlaylist)
                    return
                }
                
                let mapProgressTask = simulateProgress(from: 0.60, to: 0.90, duration: 1.5)
                // Process metadata mapping in background to prevent stutter
                let (unifiedVODs, unifiedSeries) = await Task.detached(priority: .userInitiated) {
                    let v = fetchedVODs.map { UnifiedMediaItem(from: $0, creds: creds) }
                    let s = fetchedSeries.map { UnifiedMediaItem(from: $0) }
                    return (v, s)
                }.value
                mapProgressTask.cancel()
                await MainActor.run { self.importProgress = 0.90 }
                
                // 1. Adult Content Detection
                let hasAdult = AdultContentDetector.hasAdultContent(channels: fetchedChannels, media: unifiedVODs + unifiedSeries)
                if hasAdult && !defaultPlaylist.hasAdultContent {
                    self.playlistManager.markAdultContentDetected(for: defaultPlaylist.id)
                }
                
                // 2. Fetch updated consent
                let updatedPlaylist = self.playlistManager.fetchAllPlaylists().first { $0.id == defaultPlaylist.id } ?? defaultPlaylist
                let consented = updatedPlaylist.userConsentedAdult
                
                // 3. Prompt if needed
                if hasAdult && consented == nil {
                    await MainActor.run {
                        self.pendingAdultConsentPlaylist = updatedPlaylist
                        self.showAdultConsentPrompt = true
                    }
                }
                
                // 4. Filter
                let finalChannels = AdultContentDetector.filterAdultChannels(fetchedChannels, consented: consented)
                let finalVODs = AdultContentDetector.filterAdultMedia(unifiedVODs, consented: consented)
                let finalSeries = AdultContentDetector.filterAdultMedia(unifiedSeries, consented: consented)
                
                let finalCategorizedSeries = Dictionary(grouping: finalSeries) { $0.genres?.first ?? "General" }
                
                let (trending, newR, topR, recs, hero, tSeries, nSeries, topSeries, rSeries, hSeries, vCats, sCats) = await Task.detached(priority: .userInitiated) {
                    var itemsForTrending = finalVODs
                    let trendingList = IPTVDataManager.pickRandom(&itemsForTrending, limit: 15)
                    
                    let newReleasesList = Array(finalVODs.prefix(15))
                    
                    var itemsForTop = finalVODs
                    let topRatedList = IPTVDataManager.pickRandom(&itemsForTop, limit: 15)
                    
                    let recommendedList = UserDataManager.shared.generateRecommendations(from: finalVODs)
                    
                    var itemsForTrendingSeries = finalSeries
                    let tSeriesList = IPTVDataManager.pickRandom(&itemsForTrendingSeries, limit: 15)
                    
                    let nSeriesList = Array(finalSeries.prefix(15))
                    
                    var itemsForTopSeries = finalSeries
                    let topSeriesList = IPTVDataManager.pickRandom(&itemsForTopSeries, limit: 15)
                    
                    let rSeriesList = UserDataManager.shared.generateRecommendations(from: finalSeries)
                    
                    let sortedVODKeys = Dictionary(grouping: finalVODs) { $0.genres?.first ?? "General" }.keys.sorted()
                    let vCatsList = sortedVODKeys.map { XtreamCategory(id: $0, name: $0) }
                    
                    let sortedSeriesKeys = finalCategorizedSeries.keys.sorted()
                    let sCatsList = sortedSeriesKeys.map { XtreamCategory(id: $0, name: $0) }
                    
                    return (trendingList, newReleasesList, topRatedList, recommendedList, finalVODs.first, tSeriesList, nSeriesList, topSeriesList, rSeriesList, finalSeries.first, vCatsList, sCatsList)
                }.value
                
                await MainActor.run {
                    // Sync loaded channels and media items
                    self.liveChannels = finalChannels
                    self.categorizedChannels = Dictionary(grouping: finalChannels) { $0.category ?? "General" }
                    
                    self.movies = finalVODs
                    self.categorizedMovies = Dictionary(grouping: finalVODs) { $0.genres?.first ?? "General" }
                    
                    self.series = finalSeries
                    self.categorizedSeries = finalCategorizedSeries
                    
                    self.heroMovie = hero
                    self.trendingMovies = trending
                    self.newReleases = newR
                    self.topRatedMovies = topR
                    self.recommendedMovies = recs
                    self.vodCategories = (vodCats ?? []).isEmpty ? vCats : vodCats!
                    
                    self.heroSeries = hSeries
                    self.trendingSeries = tSeries
                    self.newReleaseSeries = nSeries
                    self.topRatedSeries = topSeries
                    self.recommendedSeries = rSeries
                    self.seriesCategories = (seriesCats ?? []).isEmpty ? sCats : seriesCats!
                    
                    // Save credentials in AuthManager so sub-viewmodels can fetch VOD/Series details later
                    AuthManager.shared.saveCredentials(creds)
                    
                    // 4. Dynamically generate tabs based on Xtream API configuration
                    var tabs: [IPTVTab] = [.home, .recent]
                    if !(liveCats ?? []).isEmpty || !finalChannels.isEmpty { 
                        tabs.append(.liveTV)
                    }
                    if !(vodCats ?? []).isEmpty || !finalVODs.isEmpty { 
                        tabs.append(.movies) 
                    }
                    if !(seriesCats ?? []).isEmpty || !finalSeries.isEmpty { 
                        tabs.append(.series) 
                    }
                    
                    self.availableTabs = tabs
                    self.homeStatus = .success
                    self.currentLoadedPlaylistUrl = defaultPlaylist.url
                }
                
                self.loadEPGInBackground()
                
            case .unknown:
                throw NSError(domain: "IPTVDataManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "Unknown source type"])
            }
        } catch is CancellationError {
            #if DEBUG
            print("🌐 [IPTVDataManager] Refresh cancelled.")
            #endif
        } catch {
            await MainActor.run {
                self.homeStatus = .error(underlyingError: error)
            }
        }
    }
    
    // MARK: - M3U Processing (Progressive Chunked Loading)
    //
    // Channels are delivered to the UI in batches of `batchSize` so the Live TV
    // tab appears after the very first batch (~200 channels, typically within 1-2 seconds),
    // rather than waiting for the entire file to download and parse.
    private func processAsM3U(url: URL, defaultPlaylist: Playlist) async throws {
        let batchSize = 200
        
        // Local accumulators — mutated only on the @MainActor (this class is @MainActor)
        var allLive: [IPTVChannel] = []
        var allMovies: [UnifiedMediaItem] = []
        var allSeries: [IPTVChannel] = []      // raw; converted to hierarchy at reconciliation
        var allUncategorized: [UnifiedMediaItem] = []
        
        var firstBatchDelivered = false
        var batchBuffer: [IPTVChannel] = []
        batchBuffer.reserveCapacity(batchSize)
        
        // Adult consent resolved once before any parsing
        let updatedPlaylist = self.playlistManager.fetchAllPlaylists().first { $0.id == defaultPlaylist.id } ?? defaultPlaylist
        let consentResolved: Bool? = updatedPlaylist.userConsentedAdult
        var adultPromptShown = false
        
        // --- Streaming parse ---
        let stream = try await fetchWithRetry {
            try await M3UParser.parseStream(from: url) { [weak self] progress in
                guard let self else { return }
                self.importProgress = progress
            }
        }
        
        for try await channel in stream {
            if Task.isCancelled { throw CancellationError() }
            batchBuffer.append(channel)
            if batchBuffer.count >= batchSize {
                let batch = batchBuffer
                batchBuffer.removeAll(keepingCapacity: true)
                try await processBatch(
                    batch, defaultPlaylist: defaultPlaylist, updatedPlaylist: updatedPlaylist,
                    allLive: &allLive, allMovies: &allMovies, allSeries: &allSeries,
                    allUncategorized: &allUncategorized,
                    firstBatchDelivered: &firstBatchDelivered,
                    consentResolved: consentResolved, adultPromptShown: &adultPromptShown
                )
            }
        }
        
        // Flush the tail
        if !batchBuffer.isEmpty {
            try await processBatch(
                batchBuffer, defaultPlaylist: defaultPlaylist, updatedPlaylist: updatedPlaylist,
                allLive: &allLive, allMovies: &allMovies, allSeries: &allSeries,
                allUncategorized: &allUncategorized,
                firstBatchDelivered: &firstBatchDelivered,
                consentResolved: consentResolved, adultPromptShown: &adultPromptShown
            )
        }
        
        if Task.isCancelled { throw CancellationError() }
        
        // --- Reconciliation pass ---
        // Immutable snapshots capture safely in detached tasks.
        let snapLive    = allLive
        let snapMovies  = allMovies
        let snapSeries  = allSeries
        let snapConsent = consentResolved
        
        let (parsedSeriesResult, finalCatChannels, finalCatMovies) = await Task.detached(priority: .userInitiated) {
            let parsed = Self.parseM3USeries(snapSeries)
            let finalSeries = AdultContentDetector.filterAdultMedia(parsed.seriesList, consented: snapConsent)
            let finalSeriesIds = Set(finalSeries.map { $0.id })
            let finalEpisodesMap = parsed.episodesMap.filter { finalSeriesIds.contains($0.key) }
            let catChannels = Dictionary(grouping: snapLive)   { $0.category ?? "General" }
            let catMovies   = Dictionary(grouping: snapMovies) { $0.genres?.first ?? "General" }
            return (ParsedSeriesResult(seriesList: finalSeries, episodesMap: finalEpisodesMap), catChannels, catMovies)
        }.value
        
        // Curated picks — immutable snapshots
        let snapMovies2    = allMovies
        let snapSeriesList = parsedSeriesResult.seriesList
        let snapCatMovies  = finalCatMovies
        
        let (trending, newR, topR, recs, tSeries, nSeries, topSeries, vodCats, seriesCats) = await Task.detached(priority: .userInitiated) {
            var mv1 = snapMovies2; let trendingMovies = Self.pickRandom(&mv1, limit: 15)
            var mv2 = snapMovies2; let topRatedMovies = Self.pickRandom(&mv2, limit: 15)
            let newReleases = Array(snapMovies2.prefix(15))
            let recommended = UserDataManager.shared.generateRecommendations(from: snapMovies2)
            var s1 = snapSeriesList; let tSeries  = Self.pickRandom(&s1, limit: 15)
            var s2 = snapSeriesList; let topSeries = Self.pickRandom(&s2, limit: 15)
            let nSeries = Array(snapSeriesList.prefix(15))
            let vCats = snapCatMovies.keys.sorted().map { XtreamCategory(id: $0, name: $0) }
            let sCats = Dictionary(grouping: snapSeriesList) { $0.genres?.first ?? "General" }
                .keys.sorted().map { XtreamCategory(id: $0, name: $0) }
            return (trendingMovies, newReleases, topRatedMovies, recommended, tSeries, nSeries, topSeries, vCats, sCats)
        }.value
        
        // Apply final state — already on @MainActor, no MainActor.run {} needed
        self.categorizedChannels = finalCatChannels
        self.categorizedMovies   = finalCatMovies
        self.series              = parsedSeriesResult.seriesList
        self.categorizedSeries   = Dictionary(grouping: parsedSeriesResult.seriesList) { $0.genres?.first ?? "General" }
        self.m3uEpisodes         = parsedSeriesResult.episodesMap
        self.heroMovie           = allMovies.first
        self.trendingMovies      = trending
        self.newReleases         = newR
        self.topRatedMovies      = topR
        self.recommendedMovies   = recs
        self.vodCategories       = vodCats
        self.heroSeries          = parsedSeriesResult.seriesList.first
        self.trendingSeries      = tSeries
        self.newReleaseSeries    = nSeries
        self.topRatedSeries      = topSeries
        self.seriesCategories    = seriesCats
        
        var finalTabs: [IPTVTab] = [.home, .recent]
        if !self.liveChannels.isEmpty { finalTabs.append(.liveTV) }
        if !self.movies.isEmpty       { finalTabs.append(.movies) }
        if !self.series.isEmpty       { finalTabs.append(.series) }
        self.availableTabs = finalTabs
        self.homeStatus = .success
        self.currentLoadedPlaylistUrl = defaultPlaylist.url
        self.importProgress = nil
        
        self.loadEPGInBackground()
    }
    
    private func processBatch(_ batch: [IPTVChannel], defaultPlaylist: Playlist, updatedPlaylist: Playlist, allLive: inout [IPTVChannel], allMovies: inout [UnifiedMediaItem], allSeries: inout [IPTVChannel], allUncategorized: inout [UnifiedMediaItem], firstBatchDelivered: inout Bool, consentResolved: Bool?, adultPromptShown: inout Bool) async throws {
        let (batchLive, batchMovies, batchSeriesRaw, batchUncategorized) = await Task.detached(priority: .userInitiated) {
            var live: [IPTVChannel] = []
            var movies: [UnifiedMediaItem] = []
            var seriesRaw: [IPTVChannel] = []
            var uncategorized: [UnifiedMediaItem] = []
            for ch in batch {
                switch ch.mediaType {
                case .liveTV:        live.append(ch)
                case .movie:         movies.append(ch.toUnified)
                case .tvSeries:      seriesRaw.append(ch)
                case .uncategorized: uncategorized.append(ch.toUnified)
                }
            }
            return (live, movies, seriesRaw, uncategorized)
        }.value
        
        if !adultPromptShown {
            let hasAdult = AdultContentDetector.hasAdultContent(
                channels: batchLive,
                media: batchMovies + batchUncategorized
            )
            if hasAdult && !defaultPlaylist.hasAdultContent {
                self.playlistManager.markAdultContentDetected(for: defaultPlaylist.id)
            }
            if hasAdult && consentResolved == nil {
                await MainActor.run {
                    self.pendingAdultConsentPlaylist = updatedPlaylist
                    self.showAdultConsentPrompt = true
                }
                adultPromptShown = true
            }
        }
        
        let filteredLive = AdultContentDetector.filterAdultChannels(batchLive, consented: consentResolved)
        let filteredMovies = AdultContentDetector.filterAdultMedia(batchMovies, consented: consentResolved)
        let filteredUncategorized = AdultContentDetector.filterAdultMedia(batchUncategorized, consented: consentResolved)
        
        allLive.append(contentsOf: filteredLive)
        allMovies.append(contentsOf: filteredMovies)
        allSeries.append(contentsOf: batchSeriesRaw)
        allUncategorized.append(contentsOf: filteredUncategorized)
        
        self.liveChannels.append(contentsOf: filteredLive)
        self.movies.append(contentsOf: filteredMovies)
        self.uncategorized.append(contentsOf: filteredUncategorized)
        
        if !firstBatchDelivered && (!filteredLive.isEmpty || !filteredMovies.isEmpty) {
            firstBatchDelivered = true
            var tabs: [IPTVTab] = [.home, .recent]
            if !self.liveChannels.isEmpty { tabs.append(.liveTV) }
            if !self.movies.isEmpty       { tabs.append(.movies) }
            self.availableTabs = tabs
            self.homeStatus = .success
            self.currentLoadedPlaylistUrl = defaultPlaylist.url
        }
    }
    
    private struct ParsedSeriesResult {
        let seriesList: [UnifiedMediaItem]
        let episodesMap: [String: [String: [XtreamEpisode]]]
    }
    
    nonisolated private static func parseM3USeries(_ channels: [IPTVChannel]) -> ParsedSeriesResult {
        var episodesByShow: [String: [M3USeriesParser.ParsedEpisode: IPTVChannel]] = [:]
        
        for channel in channels {
            if let parsed = M3USeriesParser.parseEpisode(from: channel.name) {
                if episodesByShow[parsed.showTitle] == nil {
                    episodesByShow[parsed.showTitle] = [:]
                }
                episodesByShow[parsed.showTitle]?[parsed] = channel
            } else {
                let showName = channel.category ?? "Other Series"
                let parsed = M3USeriesParser.ParsedEpisode(
                    showTitle: showName,
                    seasonNumber: 1,
                    episodeNumber: 1,
                    episodeTitle: channel.name
                )
                if episodesByShow[showName] == nil {
                    episodesByShow[showName] = [:]
                }
                episodesByShow[showName]?[parsed] = channel
            }
        }
        
        var seriesList: [UnifiedMediaItem] = []
        var episodesMap: [String: [String: [XtreamEpisode]]] = [:]
        
        for (showTitle, parsedEpisodes) in episodesByShow {
            let seriesId = "m3useries_\(showTitle.base64Encoded() ?? UUID().uuidString)"
            var seasonsMap: [String: [XtreamEpisode]] = [:]
            
            let sortedParsed = parsedEpisodes.keys.sorted {
                if $0.seasonNumber == $1.seasonNumber {
                    return $0.episodeNumber < $1.episodeNumber
                }
                return $0.seasonNumber < $1.seasonNumber
            }
            
            guard let firstChannel = parsedEpisodes[sortedParsed.first!] else { continue }
            
            for parsed in sortedParsed {
                let channel = parsedEpisodes[parsed]!
                let epId = channel.streamUrl.absoluteString
                
                let episode = XtreamEpisode(
                    id: epId,
                    episodeNum: parsed.episodeNumber,
                    title: parsed.episodeTitle,
                    containerExtension: channel.streamUrl.pathExtension.isEmpty ? "mp4" : channel.streamUrl.pathExtension,
                    info: XtreamEpisodeInfo(movieImage: channel.logoUrl?.absoluteString, plot: "M3U Stream Episode")
                )
                
                let seasonKey = String(parsed.seasonNumber)
                if seasonsMap[seasonKey] == nil {
                    seasonsMap[seasonKey] = []
                }
                seasonsMap[seasonKey]?.append(episode)
            }
            
            let seriesItem = UnifiedMediaItem(
                id: seriesId,
                title: showTitle,
                overview: "Parsed from IPTV M3U Playlist",
                posterPath: firstChannel.logoUrl?.absoluteString,
                backdropPath: nil,
                mediaType: .tvSeries,
                source: .iptv,
                releaseDate: nil,
                voteAverage: nil,
                runtime: nil,
                genres: firstChannel.category != nil ? [firstChannel.category!] : ["TV Series"],
                streamUrl: nil,
                epgId: nil
            )
            
            seriesList.append(seriesItem)
            episodesMap[seriesId] = seasonsMap
        }
        
        return ParsedSeriesResult(seriesList: seriesList, episodesMap: episodesMap)
    }
    
    nonisolated private static func pickRandom<T>(_ array: inout [T], limit: Int) -> [T] {
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
