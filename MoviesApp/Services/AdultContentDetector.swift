//
//  AdultContentDetector.swift

//
//  Created by Antigravity on 21/05/26.
//

import Foundation

struct AdultContentDetector {
    private static let adultKeywords = [
        "adult", "adults", "xxx", "porn", "18+", "18 plus", "onlyfans", "playboy",
        "brazzers", "vixen", "naughty", "erotic", "nsfw"
    ]
    
    static func isAdult(category: String?, name: String?) -> Bool {
        let catLower = (category ?? "").lowercased()
        let nameLower = (name ?? "").lowercased()
        
        for keyword in adultKeywords {
            if catLower.contains(keyword) || nameLower.contains(keyword) {
                // To avoid false positives on words like "adulting", we can do a strict check for boundaries if needed.
                // However, "xxx", "18+", "porn" are usually distinct enough in IPTV playlists.
                // Let's ensure boundary check for "adult" to avoid matching "adultery" or "young adult" (maybe ok to match).
                if keyword == "adult" {
                    if catLower == "adult" || catLower.hasPrefix("adult ") || catLower.hasSuffix(" adult") || catLower.contains(" adult ") {
                        return true
                    }
                } else {
                    return true
                }
            }
        }
        
        return false
    }
    
    static func filterAdultChannels(_ channels: [IPTVChannel], consented: Bool?) -> [IPTVChannel] {
        guard consented != true else { return channels } // If consented == true, return all
        
        return channels.filter { !isAdult(category: $0.category, name: $0.name) }
    }
    
    static func filterAdultMedia(_ items: [UnifiedMediaItem], consented: Bool?) -> [UnifiedMediaItem] {
        guard consented != true else { return items } // If consented == true, return all
        
        return items.filter { item in
            !isAdult(category: item.genres?.first, name: item.title)
        }
    }
    
    static func hasAdultContent(channels: [IPTVChannel], media: [UnifiedMediaItem]) -> Bool {
        for channel in channels {
            if isAdult(category: channel.category, name: channel.name) {
                return true
            }
        }
        for item in media {
            if isAdult(category: item.genres?.first, name: item.title) {
                return true
            }
        }
        return false
    }
}
