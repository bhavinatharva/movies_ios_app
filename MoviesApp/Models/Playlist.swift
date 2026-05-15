//
//  Playlist.swift
//  MoviesApp
//
//  Created by Antigravity on 15/05/26.
//

import Foundation
import RealmSwift

class Playlist: Object, Identifiable {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var name: String
    @Persisted var url: String
    @Persisted var isDefault: Bool = false
    @Persisted var createdAt: Date = Date()
    
    convenience init(name: String, url: String, isDefault: Bool = false) {
        self.init()
        self.name = name
        self.url = url
        self.isDefault = isDefault
    }
}

class CachedChannel: Object, Identifiable {
    @Persisted(primaryKey: true) var id: String // playlistUrl + streamUrl hash
    @Persisted var playlistUrl: String
    @Persisted var name: String
    @Persisted var streamUrl: String
    @Persisted var logoUrl: String?
    @Persisted var category: String?
    @Persisted var epgId: String?
    
    convenience init(playlistUrl: String, channel: IPTVChannel) {
        self.init()
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
