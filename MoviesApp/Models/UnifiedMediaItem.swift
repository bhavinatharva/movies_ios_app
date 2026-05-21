//
//  UnifiedMediaItem.swift
//  MoviesApp
//
//  Created by Antigravity on 14/05/26.
//

import Foundation

enum MediaType: String, Codable {
    case movie
    case tvSeries
    case liveTV
    case uncategorized
}

enum MediaSource: String, Codable {
    case tmdb
    case iptv
}

struct UnifiedMediaItem: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let mediaType: MediaType
    let source: MediaSource
    
    // Metadata
    var releaseDate: String?
    var voteAverage: Double?
    var runtime: Int?
    var genres: [String]?
    var streamUrl: URL? // For IPTV HLS streams
    var epgId: String? // For EPG matching
    var adult: Bool?
    
    // General Initializer
    init(id: String,
         title: String,
         overview: String?,
         posterPath: String?,
         backdropPath: String?,
         mediaType: MediaType,
         source: MediaSource,
         releaseDate: String? = nil,
         voteAverage: Double? = nil,
         runtime: Int? = nil,
         genres: [String]? = nil,
         streamUrl: URL? = nil,
         epgId: String? = nil,
         adult: Bool? = false) {
        self.id = id
        self.title = title
        self.overview = overview
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.mediaType = mediaType
        self.source = source
        self.releaseDate = releaseDate
        self.voteAverage = voteAverage
        self.runtime = runtime
        self.genres = genres
        self.streamUrl = streamUrl
        self.epgId = epgId
        self.adult = adult
    }

    // Initializer from TrendingModel (TMDB)
    init(from trending: TrendingModel) {
        self.id = String(trending.id ?? 0)
        self.title = trending.title ?? trending.name ?? "Unknown"
        self.overview = trending.overview
        self.posterPath = trending.posterPath
        self.backdropPath = nil
        self.mediaType = trending.name != nil ? .tvSeries : .movie
        self.source = .tmdb
        self.releaseDate = trending.release_date
        self.voteAverage = nil
        self.runtime = nil
        self.genres = nil
        self.streamUrl = nil
        self.epgId = nil
        self.adult = trending.adult
    }

    // Initializer from XtreamVODStream
    init(from vod: XtreamVODStream, creds: XtreamCredentials) {
        self.id = String(vod.streamId)
        self.title = vod.name
        self.overview = nil
        self.posterPath = vod.streamIcon
        self.backdropPath = nil
        self.mediaType = .movie
        self.source = .iptv
        self.releaseDate = nil
        self.voteAverage = nil
        self.runtime = nil
        self.genres = vod.categoryId != nil ? [vod.categoryId!] : nil
        self.streamUrl = URL(string: "\(creds.serverUrl)/movie/\(creds.username)/\(creds.password)/\(vod.streamId).mp4")
        self.epgId = nil
    }
    
    // Initializer from XtreamSeries
    init(from series: XtreamSeries) {
        self.id = String(series.seriesId)
        self.title = series.name
        self.overview = nil
        self.posterPath = series.cover
        self.backdropPath = nil
        self.mediaType = .tvSeries
        self.source = .iptv
        self.releaseDate = nil
        self.voteAverage = nil
        self.runtime = nil
        self.genres = series.categoryId != nil ? [series.categoryId!] : nil
        self.streamUrl = nil
        self.epgId = nil
    }
    
    // Initializer from IPTVChannel (M3U channels)
    init(from channel: IPTVChannel) {
        self.id = channel.streamUrl.absoluteString
        self.title = channel.name
        self.overview = channel.mediaType == .liveTV ? "Live from \(channel.category ?? "IPTV")" : "VOD from \(channel.category ?? "IPTV")"
        self.posterPath = channel.logoUrl?.absoluteString
        self.backdropPath = nil
        self.mediaType = channel.mediaType
        self.source = .iptv
        self.releaseDate = channel.mediaType == .liveTV ? "LIVE" : nil
        self.voteAverage = nil
        self.runtime = nil
        self.genres = channel.category != nil ? [channel.category!] : nil
        self.streamUrl = channel.streamUrl
        self.epgId = channel.epgId
        self.adult = false
    }

    // Initializer from XtreamEpisode
    init(from episode: XtreamEpisode, seriesId: String, creds: XtreamCredentials) {
        self.id = episode.id
        self.title = episode.title
        self.overview = episode.info?.plot
        self.posterPath = episode.info?.movieImage
        self.backdropPath = nil
        self.mediaType = .movie
        self.source = .iptv
        self.releaseDate = nil
        self.voteAverage = nil
        self.runtime = nil
        self.genres = nil
        self.streamUrl = URL(string: "\(creds.serverUrl)/series/\(creds.username)/\(creds.password)/\(episode.id).\(episode.containerExtension)")
        self.epgId = nil
        self.adult = false
    }
}

// Extension to help existing views
extension TrendingModel {
    var toUnified: UnifiedMediaItem {
        UnifiedMediaItem(from: self)
    }
}

func isAdultString(_ text: String) -> Bool {
    let lower = text.lowercased()
    let adultKeywords = [
        "18+", "xxx", "adult", "redlight", "porno", "erot", "nsfw",
        "pink", "hentai", "onlyfans", "brazzers", "playboy", "penthouse",
        "hustler", "mature", "uncensored", "sex"
    ]
    return adultKeywords.contains(where: { lower.contains($0) })
}

extension UnifiedMediaItem {
    var isAdult: Bool {
        if adult == true { return true }
        if isAdultString(title) { return true }
        if let genres = genres {
            for genre in genres {
                if isAdultString(genre) {
                    return true
                }
            }
        }
        return false
    }
}

extension IPTVChannel {
    var isAdult: Bool {
        if isAdultString(name) { return true }
        if let cat = category, isAdultString(cat) { return true }
        return false
    }
}
