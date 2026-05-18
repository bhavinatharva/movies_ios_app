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
         epgId: String? = nil) {
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
}

// Extension to help existing views
extension TrendingModel {
    var toUnified: UnifiedMediaItem {
        UnifiedMediaItem(from: self)
    }
}
