//
//  IPTVSourceType.swift
//

import Foundation

enum IPTVSourceType: String, CaseIterable, Codable {
    case m3uPlaylist = "M3U Playlist"
    case xtreamCodes = "Xtream Codes API"
    case directHLS = "Direct HLS Stream"
    case directDASH = "Direct DASH Stream"
    case directFile = "Direct Video File"
    case unknown = "Unknown/Invalid"
}
