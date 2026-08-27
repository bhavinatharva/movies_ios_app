//
//  IPTVURLValidator.swift
//

import Foundation

struct IPTVURLValidator {
    
    struct ValidationResult {
        let isValid: Bool
        let type: IPTVSourceType
        let sanitizedUrl: String?
        let errorMessage: String?
        
        var credentials: XtreamCredentials? {
            guard type == .xtreamCodes, let sanitizedUrl = sanitizedUrl, let url = URL(string: sanitizedUrl) else { return nil }
            let queryParams = url.queryParameters
            let username = queryParams["username"] ?? ""
            let password = queryParams["password"] ?? ""
            let serverUrl = "\(url.scheme ?? "http")://\(url.host ?? "")\(url.port != nil ? ":\(url.port!)" : "")"
            return XtreamCredentials(serverUrl: serverUrl, username: username, password: password)
        }
    }
    
    static func detectIPTVSourceType(input: String) -> IPTVSourceType {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .unknown }
        
        let lowercased = trimmed.lowercased()
        
        if lowercased.hasPrefix("file://") {
            return .m3uPlaylist
        }
        
        var testUrlString = trimmed
        if !lowercased.hasPrefix("http://") && !lowercased.hasPrefix("https://") && !lowercased.hasPrefix("rtsp://") {
            testUrlString = "http://" + trimmed
        }
        
        guard let url = URL(string: testUrlString), url.host != nil else {
            return .unknown
        }
        
        if url.scheme?.lowercased() == "rtsp" {
            return .directFile
        }
        
        let queryParams = url.queryParameters
        if queryParams["username"] != nil && queryParams["password"] != nil {
            return .xtreamCodes
        }
        
        if url.path.contains("player_api.php") {
            return .xtreamCodes
        }
        
        let ext = url.pathExtension.lowercased()
        if ext == "mpd" || lowercased.contains(".mpd") {
            return .directDASH
        }
        
        if ext == "m3u" || ext == "m3u8" || url.path.contains("get.php") {
            return .m3uPlaylist
        }
        
        if lowercased.contains(".m3u8") {
            return .directHLS
        }
        
        if ["mp4", "mkv", "ts", "avi", "mov"].contains(ext) {
            return .directFile
        }
        
        return .unknown
    }
    
    static func validateIPTVSource(input: String) -> ValidationResult {
        var sanitized = input.trimmingCharacters(in: .whitespacesAndNewlines)
        sanitized = sanitized.replacingOccurrences(of: "\r", with: "")
        sanitized = sanitized.replacingOccurrences(of: "\n", with: "")
        
        if sanitized.isEmpty {
            return ValidationResult(isValid: false, type: .unknown, sanitizedUrl: nil, errorMessage: "Input URL cannot be empty.")
        }
        
        let lowercased = sanitized.lowercased()
        if lowercased.hasPrefix("file://") {
        } else if !lowercased.hasPrefix("http://") && !lowercased.hasPrefix("https://") && !lowercased.hasPrefix("rtsp://") {
            sanitized = "http://" + sanitized
        }
        
        guard let url = URL(string: sanitized) else {
            return ValidationResult(isValid: false, type: .unknown, sanitizedUrl: nil, errorMessage: "Invalid URL format.")
        }
        
        if url.scheme?.lowercased() != "file" && url.host == nil {
            return ValidationResult(isValid: false, type: .unknown, sanitizedUrl: nil, errorMessage: "Invalid URL format.")
        }
        
        guard let scheme = url.scheme?.lowercased(), ["http", "https", "file", "rtsp"].contains(scheme) else {
            return ValidationResult(isValid: false, type: .unknown, sanitizedUrl: nil, errorMessage: "Unsupported protocol. Please use http://, https://, rtsp:// or file://.")
        }
        
        let detectedType = detectIPTVSourceType(input: sanitized)
        
        switch detectedType {
        case .unknown:
            return ValidationResult(isValid: false, type: .unknown, sanitizedUrl: nil, errorMessage: "Invalid IPTV source. Please enter a valid M3U, Xtream API, HLS, or Video URL.")
        default:
            return ValidationResult(isValid: true, type: detectedType, sanitizedUrl: sanitized, errorMessage: nil)
        }
    }
}
