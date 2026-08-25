//
//  ImageCacheSession.swift
//
//  Created by Antigravity.
//

import Foundation

/// Configures a 50 MB disk + 10 MB memory URLCache for channel logos and poster images.
///
/// SwiftUI's AsyncImage uses URLSession.shared internally, which respects URLCache.shared.
/// By enlarging URLCache.shared on app start, all AsyncImage calls get persistent disk caching
/// without needing to pass a custom URLSession, which avoids API availability concerns.
///
/// Call `ImageCacheSession.configure()` once from the app's init or AppDelegate.
enum ImageCacheSession {
    static func configure() {
        let cache = URLCache(
            memoryCapacity: 10 * 1024 * 1024,   // 10 MB in-memory
            diskCapacity:   50 * 1024 * 1024,   // 50 MB on-disk
            diskPath: "iptv_image_cache"
        )
        URLCache.shared = cache
    }
}
