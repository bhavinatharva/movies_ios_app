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
    
    var mediaType: MediaType {
        let group = (category ?? "").lowercased()
        let streamStr = streamUrl.absoluteString.lowercased()
        let nameLower = name.lowercased()
        
        // Series check
        if group.contains("series") || group.contains("tv show") || group.contains("shows") || 
            streamStr.contains("/series/") || nameLower.matchesSeriesPattern() {
            return .tvSeries
        }
        
        // VOD Movies check
        if group.contains("movies") || group.contains("vod") || group.contains("cinema") ||
            streamStr.contains("/movie/") || streamStr.hasSuffix(".mp4") || streamStr.hasSuffix(".mkv") {
            return .movie
        }
        
        // Fallback to Live TV
        return .liveTV
    }
    
    var toUnified: UnifiedMediaItem {
        UnifiedMediaItem(
            id: streamUrl.absoluteString,
            title: name,
            overview: mediaType == .liveTV ? "Live from \(category ?? "IPTV")" : "VOD from \(category ?? "IPTV")",
            posterPath: logoUrl?.absoluteString,
            backdropPath: nil,
            mediaType: mediaType,
            source: .iptv,
            releaseDate: mediaType == .liveTV ? "LIVE" : nil,
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
    
    init(id: String, episodeNum: Int?, title: String, containerExtension: String, info: XtreamEpisodeInfo? = nil) {
        self.id = id
        self.episodeNum = episodeNum
        self.title = title
        self.containerExtension = containerExtension
        self.info = info
    }
    
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
    
    init(movieImage: String?, plot: String?) {
        self.movieImage = movieImage
        self.plot = plot
    }
    
    enum CodingKeys: String, CodingKey {
        case movieImage = "movie_image"
        case plot
    }
}

struct XtreamSeriesInfoResponse: Codable {
    let episodes: [String: [XtreamEpisode]]
}

extension String {
    func matchesSeriesPattern() -> Bool {
        let pattern = "s\\d{1,2}\\s*e\\d{1,2}"
        if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
            let range = NSRange(location: 0, length: self.count)
            return regex.firstMatch(in: self, options: [], range: range) != nil
        }
        return false
    }
}
