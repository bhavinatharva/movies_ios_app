//
//  IPTVRequestManager.swift
//  MoviesApp
//
//  Created by Antigravity on 19/05/26.
//

import Foundation

enum IPTVEndpointType {
    case live
    case vod
    case series
    case epg
    case auth
    case m3u
    
    var timeoutInterval: TimeInterval {
        switch self {
        case .live: return 120 // Live streams can take time to generate
        case .vod, .series: return 90 // Heavy JSON payloads
        case .epg: return 180 // Massive XML/JSON files
        case .auth: return 30 // Quick auth checks
        case .m3u: return 120 // Full text file
        }
    }
}

actor IPTVRequestManager {
    static let shared = IPTVRequestManager()
    
    // URLSession instances tailored for endpoint requirements
    private var sessions: [IPTVEndpointType: URLSession] = [:]
    
    // Deduplication of identical inflight requests
    private var activeTasks: [URL: Task<Data, Error>] = [:]
    
    // 10-minute cache window to prevent repeated hits
    private var cacheTimestamps: [URL: Date] = [:]
    private var memoryCache: [URL: Data] = [:]
    private let cacheDuration: TimeInterval = 600
    
    private init() {
        // Initialize sessions with custom timeouts
        let types: [IPTVEndpointType] = [.live, .vod, .series, .epg, .auth, .m3u]
        for type in types {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = type.timeoutInterval
            config.timeoutIntervalForResource = type.timeoutInterval * 2
            sessions[type] = URLSession(configuration: config)
        }
    }
    
    /// Main entry point for performing a deduplicated, retry-safe API fetch
    func performFetch(url: URL, type: IPTVEndpointType, useCache: Bool = true) async throws -> Data {
        // 1. Check local cache window to prevent repeated hits
        if useCache, let lastFetch = cacheTimestamps[url], Date().timeIntervalSince(lastFetch) < cacheDuration, let cachedData = memoryCache[url] {
            #if DEBUG
            print("🛑 [IPTVRequestManager] Throttling active - Returning memory cached data for: \(url.absoluteString)")
            #endif
            return cachedData
        }
        
        // 2. Prevent duplicate parallel calls to the exact same URL
        if let existingTask = activeTasks[url] {
            #if DEBUG
            print("🔄 [IPTVRequestManager] Joining existing inflight task for: \(url.absoluteString)")
            #endif
            return try await existingTask.value
        }
        
        // 3. Create a new network task with retry logic
        let task = Task<Data, Error> {
            let session = sessions[type] ?? .shared
            return try await executeWithExponentialBackoff(url: url, session: session)
        }
        
        activeTasks[url] = task
        
        do {
            let data = try await task.value
            activeTasks[url] = nil
            if useCache { 
                cacheTimestamps[url] = Date()
                memoryCache[url] = data
            }
            return data
        } catch {
            activeTasks[url] = nil
            throw error
        }
    }
    
    /// Executes a request with 1s, 2s, 4s exponential backoff
    private func executeWithExponentialBackoff(url: URL, session: URLSession, maxRetries: Int = 3) async throws -> Data {
        var attempts = 0
        var currentDelay = 1.0
        
        while attempts < maxRetries {
            do {
                let (data, response) = try await session.data(from: url)
                if let httpResponse = response as? HTTPURLResponse {
                    if (400...499).contains(httpResponse.statusCode) {
                        // Do not retry client errors like 404 Not Found or 401 Unauthorized
                        throw URLError(URLError.Code(rawValue: httpResponse.statusCode))
                    } else if !(200...299).contains(httpResponse.statusCode) {
                        throw URLError(URLError.Code(rawValue: httpResponse.statusCode))
                    }
                }
                return data
            } catch {
                if let urlError = error as? URLError, (400...499).contains(urlError.code.rawValue) {
                    // Fast fail for 4xx errors
                    throw error
                }
                
                attempts += 1
                if attempts >= maxRetries {
                    throw error
                }
                
                #if DEBUG
                print("⚠️ [IPTVRequestManager] Fetch failed (Attempt \(attempts)). Retrying in \(currentDelay)s... Error: \(error.localizedDescription)")
                #endif
                
                try? await Task.sleep(nanoseconds: UInt64(currentDelay * 1_000_000_000))
                currentDelay *= 2.0 // Exponential backoff
            }
        }
        throw URLError(.badServerResponse)
    }
    
    /// Exposed function specifically for M3U streaming parsing (which needs AsyncThrowingStream, not Data)
    func getStreamingSession(for type: IPTVEndpointType) -> URLSession {
        return sessions[type] ?? .shared
    }
    
    /// Clears all inflight tasks and cache
    func reset() {
        for task in activeTasks.values {
            task.cancel()
        }
        activeTasks.removeAll()
        cacheTimestamps.removeAll()
        memoryCache.removeAll()
    }
}
