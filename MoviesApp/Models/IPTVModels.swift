//
//  IPTVModels.swift
//  MoviesApp
//
//  Created by Antigravity on 14/05/26.
//

import Foundation

struct IPTVChannel: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let streamUrl: URL
    let logoUrl: URL?
    let category: String?
    let epgId: String?
    
    var toUnified: UnifiedMediaItem {
        UnifiedMediaItem(
            id: id.uuidString,
            title: name,
            overview: "Live from \(category ?? "IPTV")",
            posterPath: logoUrl?.absoluteString,
            backdropPath: nil,
            mediaType: .liveTV,
            source: .iptv,
            releaseDate: "LIVE",
            voteAverage: nil,
            runtime: nil,
            genres: category != nil ? [category!] : nil,
            streamUrl: streamUrl,
            epgId: epgId
        )
    }
}

struct XtreamCredentials: Codable {
    let serverUrl: String
    let username: String
    let password: String
}

struct XtreamCategory: Codable, Identifiable {
    let id: String
    let name: String
    
    enum CodingKeys: String, CodingKey {
        case id = "category_id"
        case name = "category_name"
    }
}
