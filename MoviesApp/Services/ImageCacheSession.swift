//
//  ImageCacheSession.swift
//
//  Created by Antigravity.
//

import Foundation

/// A shared URLSession configured with a persistent disk cache for channel logos and poster images.
/// Using this instead of URLSession.shared gives AsyncImage a proper 50 MB disk cache,
/// preventing repeated logo re-downloads on every scroll-off/scroll-back.
enum ImageCacheSession {
    static let shared: URLSession = {
        let cache = URLCache(
            memoryCapacity: 10 * 1024 * 1024,   // 10 MB in-memory
            diskCapacity:   50 * 1024 * 1024,   // 50 MB on-disk
            diskPath: "iptv_image_cache"
        )
        let config = URLSessionConfiguration.default
        config.urlCache = cache
        config.requestCachePolicy = .returnCacheDataElseLoad
        // Reasonable timeouts for logo fetches
        config.timeoutIntervalForRequest  = 10
        config.timeoutIntervalForResource = 30
        return URLSession(configuration: config)
    }()
}
