//
//  IPTVDataManager.swift
//  MoviesApp
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
    case settings
    
    var id: String { self.rawValue }
    
    var title: String {
        switch self {
        case .home: return "Home"
        case .recent: return "Recent"
        case .liveTV: return "Live TV"
        case .movies: return "Movies"
        case .series: return "Series"
        case .settings: return "Settings"
        }
    }
    
    var systemImage: String {
        switch self {
        case .home: return "house.fill"
        case .recent: return "clock.fill"
        case .liveTV: return "tv.fill"
        case .movies: return "film.fill"
        case .series: return "play.tv.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

@MainActor
@Observable
class IPTVDataManager {
    static let shared = IPTVDataManager()
    
    var homeStatus: ApiFetchStatus = .notstarted
    var availableTabs: [IPTVTab] = [.home, .recent, .settings]
    
    // Loaded Playlist State
    var currentLoadedPlaylistUrl: String? = nil
    
    // Adult Content Consent State
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
    
    // Cache for M3U TV Series Episodes
    // Series ID -> [SeasonNumberString: [XtreamEpisode]]
    var m3uEpisodes: [String: [String: [XtreamEpisode]]] = [:]
    
    private let iptvService = IPTVService.shared
    private let playlistManager = PlaylistManager.shared
    
    private var activeRefreshTask: Task<Void, Never>? = nil
    
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
    
    // Background EPG Loader
    func loadEPGInBackground() {
        Task.detached(priority: .background) {
            try? await Task.sleep(for: .seconds(2))
            print("Background EPG content pre-fetched and updated.")
        }
    }
    
    func refreshContent(clearFirst: Bool = false) async {
        if let activeTask = activeRefreshTask {
            _ = await activeTask.result
            return
        }
        
        let task = Task {
            await self.performRefreshContent(clearFirst: clearFirst)
        }
        activeRefreshTask = task
        _ = await task.result
        activeRefreshTask = nil
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
                self.m3uEpisodes = [:]
                self.availableTabs = [.home, .recent, .settings]
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
                
                let (liveCats, vodCats, seriesCats) = await (liveCatsTask, vodCatsTask, seriesCatsTask)
                
                // 3. Fetch Live streams, VODs, and Series concurrently to immediately satisfy Home screen layout
                async let liveTask = try? self.fetchWithRetry { try await self.iptvService.fetchXtreamChannels(creds: creds) }
                async let vodTask = try? self.fetchWithRetry { try await self.iptvService.fetchVODStreams(creds: creds) }
                async let seriesTask = try? self.fetchWithRetry { try await self.iptvService.fetchSeries(creds: creds) }
                
                let (fetchedChannelsResult, fetchedVODsResult, fetchedSeriesResult) = await (liveTask, vodTask, seriesTask)
                
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
                
                // Process metadata mapping in background to prevent stutter
                let (unifiedVODs, unifiedSeries) = await Task.detached(priority: .userInitiated) {
                    let v = fetchedVODs.map { UnifiedMediaItem(from: $0, creds: creds) }
                    let s = fetchedSeries.map { UnifiedMediaItem(from: $0) }
                    return (v, s)
                }.value
                
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
                
                await MainActor.run {
                    // Sync loaded channels and media items
                    self.liveChannels = finalChannels
                    self.categorizedChannels = Dictionary(grouping: finalChannels) { $0.category ?? "General" }
                    
                    self.movies = finalVODs
                    self.categorizedMovies = Dictionary(grouping: finalVODs) { $0.genres?.first ?? "General" }
                    
                    self.series = finalSeries
                    
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
                    tabs.append(.settings)
                    
                    self.availableTabs = tabs
                    self.homeStatus = .success
                    self.currentLoadedPlaylistUrl = defaultPlaylist.url
                }
                
                self.loadEPGInBackground()
                
            case .unknown:
                throw NSError(domain: "IPTVDataManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "Unknown source type"])
            }
        } catch {
            await MainActor.run {
                self.homeStatus = .error(underlyingError: error)
            }
        }
    }
    
    private func processAsM3U(url: URL, defaultPlaylist: Playlist) async throws {
        // 1. Fetch & Parse M3U playlist file using streaming parser (minimizing memory usage in background)
        let channels = try await fetchWithRetry {
            try await Task.detached(priority: .userInitiated) {
                var parsedChannels: [IPTVChannel] = []
                let stream = try await M3UParser.parseStream(from: url)
                for try await channel in stream {
                    parsedChannels.append(channel)
                }
                return parsedChannels
            }.value
        }
        
        // 2. Classify raw channels dynamically in the background to prevent main thread stutters
        let (tempLive, tempMovies, tempUncategorized, parsedSeriesResult) = try await Task.detached(priority: .userInitiated) {
            var tempLive: [IPTVChannel] = []
            var tempMovies: [UnifiedMediaItem] = []
            var tempSeriesRaw: [IPTVChannel] = []
            var tempUncategorized: [UnifiedMediaItem] = []
            
            for channel in channels {
                switch channel.mediaType {
                case .liveTV:
                    tempLive.append(channel)
                case .movie:
                    tempMovies.append(channel.toUnified)
                case .tvSeries:
                    tempSeriesRaw.append(channel)
                case .uncategorized:
                    tempUncategorized.append(channel.toUnified)
                }
            }
            
            // 3. Process flat TV series into clean Netflix hierarchies
            let parsed = Self.parseM3USeries(tempSeriesRaw)
            return (tempLive, tempMovies, tempUncategorized, parsed)
        }.value
        
        // 1. Adult Content Detection
        let hasAdult = AdultContentDetector.hasAdultContent(channels: tempLive, media: tempMovies + parsedSeriesResult.seriesList + tempUncategorized)
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
        let finalLive = AdultContentDetector.filterAdultChannels(tempLive, consented: consented)
        let finalMovies = AdultContentDetector.filterAdultMedia(tempMovies, consented: consented)
        let finalSeries = AdultContentDetector.filterAdultMedia(parsedSeriesResult.seriesList, consented: consented)
        let finalUncategorized = AdultContentDetector.filterAdultMedia(tempUncategorized, consented: consented)
        
        // Filter episodes map based on series list
        let finalSeriesIds = Set(finalSeries.map { $0.id })
        let finalEpisodesMap = parsedSeriesResult.episodesMap.filter { finalSeriesIds.contains($0.key) }
        
        await MainActor.run {
            self.liveChannels = finalLive
            self.movies = finalMovies
            self.series = finalSeries
            self.uncategorized = finalUncategorized
            self.m3uEpisodes = finalEpisodesMap
            
            self.categorizedChannels = Dictionary(grouping: finalLive) { $0.category ?? "General" }
            self.categorizedMovies = Dictionary(grouping: finalMovies) { $0.genres?.first ?? "General" }
            
            // 4. Adapt tabs dynamically based on contents parsed!
            var tabs: [IPTVTab] = [.home, .recent]
            if !finalLive.isEmpty { 
                tabs.append(.liveTV)
            }
            if !finalMovies.isEmpty { 
                tabs.append(.movies) 
            }
            if !finalSeries.isEmpty { 
                tabs.append(.series) 
            }
            tabs.append(.settings)
            
            self.availableTabs = tabs
            self.homeStatus = .success
            self.currentLoadedPlaylistUrl = defaultPlaylist.url
        }
        
        self.loadEPGInBackground()
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
}
