//
//  IPTVRequestManager.swift

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
        case .live: return 120
        case .vod, .series: return 120 // Heavy JSON payloads from large providers
        case .epg: return 120 // Massive XML/JSON files
        case .auth: return 30
        case .m3u: return 180 // Full text file (can be huge)
        }
    }
}

actor IPTVRequestManager {
    static let shared = IPTVRequestManager()
    
    // URLSession instances tailored for endpoint requirements
    private var sessions: [IPTVEndpointType: URLSession] = [:]
    
    // Deduplication of identical inflight requests
    private var activeTasks: [URL: Task<Data, Error>] = [:]
    

    private init() {
        // Initialize sessions with custom timeouts
        let types: [IPTVEndpointType] = [.live, .vod, .series, .epg, .auth, .m3u]
        for type in types {
            let config = URLSessionConfiguration.default
            config.requestCachePolicy = .reloadIgnoringLocalCacheData
            config.urlCache = nil
            config.timeoutIntervalForRequest = type.timeoutInterval
            config.timeoutIntervalForResource = type.timeoutInterval * 2
            
            // Add a standard User-Agent. Many IPTV providers block CFNetwork (iOS default) and drop the connection, causing a timeout.
            config.httpAdditionalHeaders = [
                "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
            ]
            
            sessions[type] = URLSession(configuration: config)
        }
    }
    
    /// Main entry point for performing a deduplicated, retry-safe API fetch
    func performFetch(url: URL, type: IPTVEndpointType) async throws -> Data {
        
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
            var request = URLRequest(url: url)
            request.timeoutInterval = type.timeoutInterval
            request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
            return try await executeWithExponentialBackoff(request: request, session: session)
        }
        
        activeTasks[url] = task
        
        do {
            let data = try await task.value
            activeTasks[url] = nil
            return data
        } catch {
            activeTasks[url] = nil
            throw error
        }
    }
    
    /// Executes a request with 1s, 2s, 4s exponential backoff
    private func executeWithExponentialBackoff(request: URLRequest, session: URLSession, maxRetries: Int = 3) async throws -> Data {
        var attempts = 0
        var currentDelay = 1.0
        
        while attempts < maxRetries {
            do {
                let (data, response) = try await session.data(for: request)
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
    
    func reset() {
        for task in activeTasks.values {
            task.cancel()
        }
        activeTasks.removeAll()
    }
}
