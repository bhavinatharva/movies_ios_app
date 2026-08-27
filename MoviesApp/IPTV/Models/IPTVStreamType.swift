//
//  IPTVStreamType.swift
//

import Foundation

enum IPTVStreamType: String, Codable {
    case hls = "hls"
    case dash = "dash"
    case ts = "ts"
    case mp4 = "mp4"
    case mkv = "mkv"
    case rtsp = "rtsp"
    case unknown = "unknown"
    
    var isNativelySupported: Bool {
        switch self {
        case .hls, .mp4:
            return true
        case .ts, .mkv, .dash, .rtsp, .unknown:
            return false
        }
    }
}
