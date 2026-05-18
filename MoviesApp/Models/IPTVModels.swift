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
            id: streamUrl.absoluteString,
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

struct XtreamVODStream: Codable {
    let name: String
    let streamId: Int
    let streamIcon: String?
    let categoryId: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case streamId = "stream_id"
        case streamIcon = "stream_icon"
        case categoryId = "category_id"
    }
}

struct XtreamSeries: Codable {
    let name: String
    let seriesId: Int
    let cover: String?
    let categoryId: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case seriesId = "series_id"
        case cover
        case categoryId = "category_id"
    }
}

struct XtreamEpisode: Codable {
    let id: String
    let episodeNum: Int?
    let title: String
    let containerExtension: String
    let info: XtreamEpisodeInfo?
    
    enum CodingKeys: String, CodingKey {
        case id
        case episodeNum = "episode_num"
        case title
        case containerExtension = "container_extension"
        case info
    }
}

struct XtreamEpisodeInfo: Codable {
    let movieImage: String?
    let plot: String?
    
    enum CodingKeys: String, CodingKey {
        case movieImage = "movie_image"
        case plot
    }
}

struct XtreamSeriesInfoResponse: Codable {
    let episodes: [String: [XtreamEpisode]]
}
