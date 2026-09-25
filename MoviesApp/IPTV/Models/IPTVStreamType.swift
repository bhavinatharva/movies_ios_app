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
    case avi = "avi"
    case webm = "webm"
    case flv = "flv"
    case wmv = "wmv"
    case mov = "mov"
    case rtsp = "rtsp"
    case unknown = "unknown"
    
    var isNativelySupported: Bool {
        switch self {
        case .hls, .mp4, .mov:
            return true
        case .ts, .mkv, .avi, .webm, .flv, .wmv, .dash, .rtsp, .unknown:
            return false
        }
    }
}
