//
//  Playlist.swift

//
//  Created by Antigravity on 15/05/26.
//

import Foundation

struct Playlist: Identifiable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var url: String
    var isDefault: Bool = false
    var createdAt: Date = Date()
    
    // Adult Content
    var hasAdultContent: Bool = false
    var userConsentedAdult: Bool? = nil
    
    init(name: String, url: String, isDefault: Bool = false) {
        self.name = name
        self.url = url
        self.isDefault = isDefault
    }
}

struct CachedChannel: Identifiable, Codable {
    var id: String // playlistUrl + streamUrl hash
    var playlistUrl: String
    var name: String
    var streamUrl: String
    var logoUrl: String?
    var category: String?
    var epgId: String?
    
    init(playlistUrl: String, channel: IPTVChannel) {
        self.playlistUrl = playlistUrl
        self.name = channel.name
        self.streamUrl = channel.streamUrl.absoluteString
        self.logoUrl = channel.logoUrl?.absoluteString
        self.category = channel.category
        self.epgId = channel.epgId
        self.id = "\(playlistUrl)_\(channel.streamUrl.absoluteString)".md5() // Assuming md5 or simple concat
    }
    
    var toIPTVChannel: IPTVChannel {
        IPTVChannel(
            name: name,
            streamUrl: URL(string: streamUrl)!,
            logoUrl: logoUrl.flatMap { URL(string: $0) },
            category: category,
            epgId: epgId
        )
    }
}

extension String {
    func md5() -> String {
        // Simple fallback if no crypto library is used, just for unique ID
        return self.base64Encoded() ?? self
    }
    
    func base64Encoded() -> String? {
        return data(using: .utf8)?.base64EncodedString()
    }
}
