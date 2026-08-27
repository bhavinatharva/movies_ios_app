//
//  IPTVContentDetector.swift
//

import Foundation

struct IPTVContentDetector {
    
    static func detectStreamType(from url: URL) async -> IPTVStreamType {
        let ext = url.pathExtension.lowercased()
        
        if url.scheme?.lowercased() == "rtsp" { return .rtsp }
        if ext == "m3u8" || ext == "m3u" { return .hls }
        if ext == "mpd" { return .dash }
        if ext == "ts" { return .ts }
        if ext == "mp4" { return .mp4 }
        if ext == "mkv" { return .mkv }
        
        // If extension is not definitive, do a HEAD request to check Content-Type
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 5
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse,
               let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type")?.lowercased() {
                
                if contentType.contains("application/x-mpegurl") || contentType.contains("application/vnd.apple.mpegurl") {
                    return .hls
                } else if contentType.contains("application/dash+xml") {
                    return .dash
                } else if contentType.contains("video/mp2t") {
                    return .ts
                } else if contentType.contains("video/mp4") {
                    return .mp4
                } else if contentType.contains("video/x-matroska") {
                    return .mkv
                }
            }
        } catch {
            // Silently fail and fallback
        }
        
        return .unknown
    }
}
