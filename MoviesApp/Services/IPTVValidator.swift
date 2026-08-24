//
//  IPTVValidator.swift

//
//  Created by Antigravity on 18/05/26.
//

import Foundation

/// Reusable utility to properly parse, validate, and identify IPTV stream formats and playlists.
struct IPTVValidator {
    
    /// Supported standard IPTV stream and playlist formats
    enum IPTVSourceType: String, CaseIterable, Codable {
        case m3uPlaylist = "M3U Playlist"
        case xtreamCodes = "Xtream Codes API"
        case directHLS = "Direct HLS Stream"
        case directDASH = "Direct DASH Stream"
        case unknown = "Unknown/Invalid"
    }
    
    /// Result structure summarizing the parsing and validation check
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
    
    /// Detects the target IPTV source type based on standard suffix, structure, and query parameter patterns
    /// - Parameter input: The raw URL or input string
    /// - Returns: Detected `IPTVSourceType`
    static func detectIPTVSourceType(input: String) -> IPTVSourceType {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .unknown }
        
        let lowercased = trimmed.lowercased()
        
        if lowercased.hasPrefix("file://") {
            return .m3uPlaylist
        }
        
        // 1. Ensure scheme is normalized
        var testUrlString = trimmed
        if !lowercased.hasPrefix("http://") && !lowercased.hasPrefix("https://") {
            testUrlString = "http://" + trimmed
        }
        
        guard let url = URL(string: testUrlString), url.host != nil else {
            return .unknown
        }
        
        // 2. Auto-detect: DASH streams (.mpd)
        if url.pathExtension.lowercased() == "mpd" || lowercased.contains(".mpd") {
            return .directDASH
        }
        
        // 2. Auto-detect: Xtream Codes API
        let queryParams = url.queryParameters
        if queryParams["username"] != nil && queryParams["password"] != nil {
            return .xtreamCodes
        }
        
        if url.path.contains("player_api.php") {
            return .xtreamCodes
        }
        
        // 3. Auto-detect: DASH streams (.mpd)
        if url.pathExtension.lowercased() == "mpd" || lowercased.contains(".mpd") {
            return .directDASH
        }
        
        // 4. Auto-detect: M3U / M3U8 Playlist
        if url.pathExtension.lowercased() == "m3u" || url.pathExtension.lowercased() == "m3u8" {
            return .m3uPlaylist
        }
        
        if url.path.contains("get.php") {
            return .m3uPlaylist
        }
        
        // 5. Fallback check: Treat other .m3u8 patterns without M3U descriptors as direct stream URLs
        if lowercased.contains(".m3u8") {
            return .directHLS
        }
        
        return .unknown
    }
    
    /// Runs a comprehensive sanitization and validation routine on user inputted URLs
    /// - Parameter input: The raw text entered by the user
    /// - Returns: A `ValidationResult` containing details on validity and detected format type
    static func validateIPTVSource(input: String) -> ValidationResult {
        var sanitized = input.trimmingCharacters(in: .whitespacesAndNewlines)
        sanitized = sanitized.replacingOccurrences(of: "\r", with: "")
        sanitized = sanitized.replacingOccurrences(of: "\n", with: "")
        
        if sanitized.isEmpty {
            return ValidationResult(
                isValid: false,
                type: .unknown,
                sanitizedUrl: nil,
                errorMessage: "Input URL cannot be empty."
            )
        }
        
        // Support protocol-less inputs (e.g. vipiptv161.com:8080/get.php...) by prepending http://
        let lowercased = sanitized.lowercased()
        if lowercased.hasPrefix("file://") {
            // It's a local file URL
        } else if !lowercased.hasPrefix("http://") && !lowercased.hasPrefix("https://") {
            sanitized = "http://" + sanitized
        }
        
        guard let url = URL(string: sanitized) else {
            return ValidationResult(
                isValid: false,
                type: .unknown,
                sanitizedUrl: nil,
                errorMessage: "Invalid URL format."
            )
        }
        
        if url.scheme?.lowercased() != "file" && url.host == nil {
            return ValidationResult(
                isValid: false,
                type: .unknown,
                sanitizedUrl: nil,
                errorMessage: "Invalid URL format."
            )
        }
        
        // Supported protocol check: Reject unsupported protocols (non-http/https)
        guard let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" || scheme == "file" else {
            return ValidationResult(
                isValid: false,
                type: .unknown,
                sanitizedUrl: nil,
                errorMessage: "Unsupported protocol. Please use http://, https:// or file://."
            )
        }
        
        let detectedType = detectIPTVSourceType(input: sanitized)
        
        switch detectedType {
        case .unknown:
            return ValidationResult(
                isValid: false,
                type: .unknown,
                sanitizedUrl: nil,
                errorMessage: "Invalid IPTV source. Please enter a valid M3U, Xtream API, or HLS URL."
            )
        default:
            return ValidationResult(
                isValid: true,
                type: detectedType,
                sanitizedUrl: sanitized,
                errorMessage: nil
            )
        }
    }
}

// Helper extension to parse query parameters from the URL
extension URL {
    var queryParameters: [String: String] {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: true),
              let queryItems = components.queryItems else {
            return [:]
        }
        return queryItems.reduce(into: [:]) { result, item in
            result[item.name.lowercased()] = item.value
        }
    }
}
