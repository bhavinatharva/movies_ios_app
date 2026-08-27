//
//  IPTVDataFetcher.swift
//
//  Created by Antigravity on 27/08/26.
//

import Foundation

class IPTVDataFetcher {
    
    private let iptvService = XtreamProvider.shared
    
    func fetchAndSave(playlist: Playlist, progressHandler: @escaping (Double) -> Void) async throws {
        let validation = IPTVURLValidator.validateIPTVSource(input: playlist.url)
        
        guard validation.isValid,
              let sanitizedStr = validation.sanitizedUrl,
              let url = URL(string: sanitizedStr) else {
            throw NSError(domain: "IPTVDataFetcher", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Playlist URL"])
        }
        
        switch validation.type {
        case .xtreamCodes:
            try await processXtreamCodes(url: url, playlist: playlist, progressHandler: progressHandler)
        case .m3uPlaylist, .directHLS, .directDASH, .directFile:
            try await processAsM3U(url: url, playlist: playlist, progressHandler: progressHandler)
        case .unknown:
            throw NSError(domain: "IPTVDataFetcher", code: -2, userInfo: [NSLocalizedDescriptionKey: "Unknown source type"])
        }
    }
    
    // MARK: - Xtream Codes
    
    private func processXtreamCodes(url: URL, playlist: Playlist, progressHandler: @escaping (Double) -> Void) async throws {
        let queryParams = url.queryParameters
        let username = queryParams["username"] ?? ""
        let password = queryParams["password"] ?? ""
        let serverUrl = "\(url.scheme ?? "http")://\(url.host ?? "")\(url.port != nil ? ":\(url.port!)" : "")"
        let creds = XtreamCredentials(serverUrl: serverUrl, username: username, password: password)
        
        progressHandler(0.05)
        
        // 1. Fetch Categories
        async let liveCatsTask = try? fetchWithRetry { try await self.iptvService.fetchLiveCategories(creds: creds) }
        async let vodCatsTask = try? fetchWithRetry { try await self.iptvService.fetchVODCategories(creds: creds) }
        async let seriesCatsTask = try? fetchWithRetry { try await self.iptvService.fetchSeriesCategories(creds: creds) }
        
        let (liveCats, vodCats, seriesCats) = await (liveCatsTask, vodCatsTask, seriesCatsTask)
        
        if Task.isCancelled { throw CancellationError() }
        progressHandler(0.15)
        
        // Save Categories
        if let liveCats = liveCats, !liveCats.isEmpty {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                IPTVLocalDatabase.shared.saveCategories(liveCats, type: "live", playlistId: playlist.id) { continuation.resume() }
            }
        }
        if let vodCats = vodCats, !vodCats.isEmpty {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                IPTVLocalDatabase.shared.saveCategories(vodCats, type: "vod", playlistId: playlist.id) { continuation.resume() }
            }
        }
        if let seriesCats = seriesCats, !seriesCats.isEmpty {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                IPTVLocalDatabase.shared.saveCategories(seriesCats, type: "series", playlistId: playlist.id) { continuation.resume() }
            }
        }
        
        progressHandler(0.20)
        
        // 2. Fetch Streams Concurrently
        async let channelsTask = try? fetchWithRetry { try await self.iptvService.fetchXtreamChannels(creds: creds) }
        async let vodTask = try? fetchWithRetry { try await self.iptvService.fetchVODStreams(creds: creds) }
        async let seriesTask = try? fetchWithRetry { try await self.iptvService.fetchSeries(creds: creds) }
        
        let (channels, vods, series) = await (channelsTask, vodTask, seriesTask)
        
        if Task.isCancelled { throw CancellationError() }
        progressHandler(0.60)
        
        // 3. Process and Save Streams
        if let channels = channels, !channels.isEmpty {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                IPTVLocalDatabase.shared.saveChannels(channels, playlistId: playlist.id, replace: true) { continuation.resume() }
            }
        }
        
        progressHandler(0.70)
        
        if let vods = vods, !vods.isEmpty {
            let unifiedVODs = vods.map { UnifiedMediaItem(from: $0, creds: creds) }
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                IPTVLocalDatabase.shared.saveMediaItems(unifiedVODs, playlistId: playlist.id, replaceType: .movie) { continuation.resume() }
            }
        }
        
        progressHandler(0.85)
        
        if let series = series, !series.isEmpty {
            let unifiedSeries = series.map { UnifiedMediaItem(from: $0) }
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                IPTVLocalDatabase.shared.saveMediaItems(unifiedSeries, playlistId: playlist.id, replaceType: .tvSeries) { continuation.resume() }
            }
        }
        
        progressHandler(1.0)
        
        // Let UI know new data is ready for this playlist
        await MainActor.run {
            if IPTVDataManager.shared.currentLoadedPlaylistUrl == playlist.url {
                Task {
                    await IPTVDataManager.shared.loadFromCache(playlist: playlist)
                }
            }
        }
    }
    
    // MARK: - M3U Playlist
    
    private func processAsM3U(url: URL, playlist: Playlist, progressHandler: @escaping (Double) -> Void) async throws {
        let batchSize = 500
        
        var batchBuffer: [IPTVChannel] = []
        batchBuffer.reserveCapacity(batchSize)
        
        var totalChannelsSaved = 0
        
        let stream = try await fetchWithRetry {
            try await M3UParser.parseStream(from: url) { progress in
                // Stream parsing is roughly the first 50% of the work.
                progressHandler((progress ?? 0.0) * 0.5)
            }
        }
        
        // 1. Initial wipe for this playlist since we batch insert incrementally
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            IPTVLocalDatabase.shared.saveChannels([], playlistId: playlist.id, replace: true) {
                IPTVLocalDatabase.shared.saveMediaItems([], playlistId: playlist.id, replaceType: .movie) {
                    IPTVLocalDatabase.shared.saveMediaItems([], playlistId: playlist.id, replaceType: .tvSeries) {
                        continuation.resume()
                    }
                }
            }
        }
        
        for try await channel in stream {
            if Task.isCancelled { throw CancellationError() }
            batchBuffer.append(channel)
            if batchBuffer.count >= batchSize {
                let batch = batchBuffer
                batchBuffer.removeAll(keepingCapacity: true)
                try await saveM3UBatch(batch: batch, playlist: playlist)
                totalChannelsSaved += batch.count
                progressHandler(0.5 + min(0.4, (Double(totalChannelsSaved) / 50000.0) * 0.4))
            }
        }
        
        if !batchBuffer.isEmpty {
            try await saveM3UBatch(batch: batchBuffer, playlist: playlist)
        }
        
        progressHandler(1.0)
        
        // Notify UI
        await MainActor.run {
            if IPTVDataManager.shared.currentLoadedPlaylistUrl == playlist.url {
                Task {
                    await IPTVDataManager.shared.loadFromCache(playlist: playlist)
                }
            }
        }
    }
    
    private func saveM3UBatch(batch: [IPTVChannel], playlist: Playlist) async throws {
        var live: [IPTVChannel] = []
        var movies: [UnifiedMediaItem] = []
        var series: [UnifiedMediaItem] = []
        
        for ch in batch {
            switch ch.mediaType {
            case .liveTV:        live.append(ch)
            case .movie:         movies.append(ch.toUnified)
            case .tvSeries:      
                // Simple series parsing logic
                series.append(UnifiedMediaItem(
                    id: ch.streamUrl.absoluteString,
                    title: ch.name,
                    overview: "Parsed from IPTV M3U Playlist",
                    posterPath: ch.logoUrl?.absoluteString,
                    backdropPath: nil,
                    mediaType: .tvSeries,
                    source: .iptv,
                    releaseDate: nil,
                    voteAverage: nil,
                    runtime: nil,
                    genres: ch.category != nil ? [ch.category!] : ["TV Series"],
                    streamUrl: ch.streamUrl,
                    epgId: ch.epgId
                ))
            case .uncategorized: movies.append(ch.toUnified)
            }
        }
        
        let batchLive = live
        let batchMovies = movies
        let batchSeries = series
        
        if !batchLive.isEmpty {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                // append, do not replace for batches
                IPTVLocalDatabase.shared.saveChannels(batchLive, playlistId: playlist.id, replace: false) { continuation.resume() }
            }
        }
        
        if !batchMovies.isEmpty {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                IPTVLocalDatabase.shared.saveMediaItems(batchMovies, playlistId: playlist.id, replaceType: nil) { continuation.resume() }
            }
        }
        
        if !batchSeries.isEmpty {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                IPTVLocalDatabase.shared.saveMediaItems(batchSeries, playlistId: playlist.id, replaceType: nil) { continuation.resume() }
            }
        }
    }
    
    // MARK: - Utilities
    
    private func fetchWithRetry<T>(retries: Int = 3, delaySeconds: Double = 1.0, operation: @escaping () async throws -> T) async throws -> T {
        var attempts = 0
        while true {
            do {
                return try await operation()
            } catch {
                if let urlError = error as? URLError, (400...499).contains(urlError.code.rawValue) {
                    throw error
                }
                
                attempts += 1
                if attempts >= retries {
                    throw error
                }
                try? await Task.sleep(for: .milliseconds(Int(delaySeconds * 1000)))
            }
        }
    }
}
