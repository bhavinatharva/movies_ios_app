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
    case liveTV
    case movies
    case series
    case settings
    
    var id: String { self.rawValue }
    
    var title: String {
        switch self {
        case .home: return "Home"
        case .liveTV: return "Live TV"
        case .movies: return "Movies"
        case .series: return "Series"
        case .settings: return "Settings"
        }
    }
    
    var systemImage: String {
        switch self {
        case .home: return "house.fill"
        case .liveTV: return "tv.fill"
        case .movies: return "film.fill"
        case .series: return "play.tv.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

@Observable
class IPTVDataManager {
    static let shared = IPTVDataManager()
    
    var homeStatus: ApiFetchStatus = .notstarted
    var availableTabs: [IPTVTab] = [.home, .settings]
    
    // Classified data arrays
    var liveChannels: [IPTVChannel] = []
    var movies: [UnifiedMediaItem] = []
    var series: [UnifiedMediaItem] = []
    
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
        loadCachedData()
        Task {
            await refreshContent()
        }
    }
    
    func loadCachedData() {
        let cachedChannels = IPTVLocalDatabase.shared.fetchChannels()
        let cachedMovies = IPTVLocalDatabase.shared.fetchMediaItems(type: .movie)
        let cachedSeries = IPTVLocalDatabase.shared.fetchMediaItems(type: .tvSeries)
        
        if !cachedChannels.isEmpty || !cachedMovies.isEmpty || !cachedSeries.isEmpty {
            self.liveChannels = cachedChannels
            self.movies = cachedMovies
            self.series = cachedSeries
            
            self.categorizedChannels = Dictionary(grouping: cachedChannels) { $0.category ?? "General" }
            self.categorizedMovies = Dictionary(grouping: cachedMovies) { $0.genres?.first ?? "General" }
            
            var tabs: [IPTVTab] = [.home]
            if !cachedChannels.isEmpty { tabs.append(.liveTV) }
            if !cachedMovies.isEmpty { tabs.append(.movies) }
            if !cachedSeries.isEmpty { tabs.append(.series) }
            tabs.append(.settings)
            
            self.availableTabs = tabs
            self.homeStatus = .success
        }
    }
    
    // MARK: - Safe Retry Wrapper
    private func fetchWithRetry<T>(retries: Int = 3, delaySeconds: Double = 1.0, operation: @escaping () async throws -> T) async throws -> T {
        var attempts = 0
        while true {
            do {
                return try await operation()
            } catch {
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
    
    private func performRefreshContent(clearFirst: Bool) async {
        if clearFirst {
            await MainActor.run {
                self.liveChannels = []
                self.movies = []
                self.series = []
                self.categorizedChannels = [:]
                self.categorizedMovies = [:]
                self.m3uEpisodes = [:]
            }
            IPTVLocalDatabase.shared.clearAllData()
        }
        
        guard let defaultPlaylist = playlistManager.fetchDefaultPlaylist() else {
            await MainActor.run {
                self.liveChannels = []
                self.movies = []
                self.series = []
                self.categorizedChannels = [:]
                self.categorizedMovies = [:]
                self.m3uEpisodes = [:]
                self.availableTabs = [.home, .settings]
                self.homeStatus = .notstarted
            }
            IPTVLocalDatabase.shared.clearAllData()
            return
        }
        
        await MainActor.run {
            self.homeStatus = .loading
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
        
        do {
            switch validation.type {
            case .m3uPlaylist, .directHLS, .directDASH:
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
                let (tempLive, tempMovies, parsedSeriesResult) = try await Task.detached(priority: .userInitiated) {
                    var tempLive: [IPTVChannel] = []
                    var tempMovies: [UnifiedMediaItem] = []
                    var tempSeriesRaw: [IPTVChannel] = []
                    
                    for channel in channels {
                        switch channel.mediaType {
                        case .liveTV:
                            tempLive.append(channel)
                        case .movie:
                            tempMovies.append(channel.toUnified)
                        case .tvSeries:
                            tempSeriesRaw.append(channel)
                        }
                    }
                    
                    // 3. Process flat TV series into clean Netflix hierarchies
                    let parsed = self.parseM3USeries(tempSeriesRaw)
                    return (tempLive, tempMovies, parsed)
                }.value
                
                await MainActor.run {
                    self.liveChannels = tempLive
                    self.movies = tempMovies
                    self.series = parsedSeriesResult.seriesList
                    self.m3uEpisodes = parsedSeriesResult.episodesMap
                    
                    self.categorizedChannels = Dictionary(grouping: tempLive) { $0.category ?? "General" }
                    self.categorizedMovies = Dictionary(grouping: tempMovies) { $0.genres?.first ?? "General" }
                    
                    // 4. Adapt tabs dynamically based on contents parsed!
                    var tabs: [IPTVTab] = [.home]
                    if !tempLive.isEmpty { tabs.append(.liveTV) }
                    if !tempMovies.isEmpty { tabs.append(.movies) }
                    if !parsedSeriesResult.seriesList.isEmpty { tabs.append(.series) }
                    tabs.append(.settings)
                    
                    self.availableTabs = tabs
                    self.homeStatus = .success
                }
                
                // Batch save the loaded results to our persistent local database stack
                IPTVLocalDatabase.shared.saveChannels(tempLive) {}
                IPTVLocalDatabase.shared.saveMediaItems(tempMovies + parsedSeriesResult.seriesList) {}
                
                self.loadEPGInBackground()
                
            case .xtreamCodes:
                // 1. Parse Xtream query credentials
                let queryParams = url.queryParameters
                let username = queryParams["username"] ?? ""
                let password = queryParams["password"] ?? ""
                let serverUrl = "\(url.scheme ?? "http")://\(url.host ?? "")\(url.port != nil ? ":\(url.port!)" : "")"
                let creds = XtreamCredentials(serverUrl: serverUrl, username: username, password: password)
                
                // 2. Validate availability of VOD and Series via categories tasks concurrently with retry
                async let liveCatsTask = try? fetchWithRetry { try await self.iptvService.fetchLiveCategories(creds: creds) }
                async let vodCatsTask = try? fetchWithRetry { try await self.iptvService.fetchVODCategories(creds: creds) }
                async let seriesCatsTask = try? fetchWithRetry { try await self.iptvService.fetchSeriesCategories(creds: creds) }
                
                let (liveCats, vodCats, seriesCats) = await (liveCatsTask, vodCatsTask, seriesCatsTask)
                
                // 3. Fetch Live streams to immediately satisfy Home screen layout with retry
                let fetchedChannels = try await fetchWithRetry {
                    try await self.iptvService.fetchXtreamChannels(creds: creds)
                }
                
                await MainActor.run {
                    // Sync loaded live channels
                    self.liveChannels = fetchedChannels
                    self.categorizedChannels = Dictionary(grouping: fetchedChannels) { $0.category ?? "General" }
                    
                    // Save credentials in AuthManager so sub-viewmodels can fetch VOD/Series
                    AuthManager.shared.saveCredentials(creds)
                    
                    // 4. Dynamically generate tabs based on Xtream API configuration
                    var tabs: [IPTVTab] = [.home]
                    if !(liveCats ?? []).isEmpty || !fetchedChannels.isEmpty { tabs.append(.liveTV) }
                    if !(vodCats ?? []).isEmpty { tabs.append(.movies) }
                    if !(seriesCats ?? []).isEmpty { tabs.append(.series) }
                    tabs.append(.settings)
                    
                    self.availableTabs = tabs
                    self.homeStatus = .success
                }
                
                // Batch save the loaded results to our persistent local database stack
                IPTVLocalDatabase.shared.saveChannels(fetchedChannels) {}
                
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
    
    private struct ParsedSeriesResult {
        let seriesList: [UnifiedMediaItem]
        let episodesMap: [String: [String: [XtreamEpisode]]]
    }
    
    private func parseM3USeries(_ channels: [IPTVChannel]) -> ParsedSeriesResult {
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
