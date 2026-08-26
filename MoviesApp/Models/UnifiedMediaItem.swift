//
//  UnifiedMediaItem.swift

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
    var title: String
    var overview: String?
    var posterPath: String?
    var backdropPath: String?
    let mediaType: MediaType
    let source: MediaSource
    
    // Metadata
    var releaseDate: String?
    var voteAverage: Double?
    var runtime: Int?
    var genres: [String]?
    var streamUrl: URL? // For IPTV HLS streams
    var epgId: String? // For EPG matching
    var cast: String?
    var director: String?
    var country: String?
    var trailerUrl: URL?
    var addedDate: Date?
    
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
         cast: String? = nil,
         director: String? = nil,
         country: String? = nil,
         trailerUrl: URL? = nil,
         addedDate: Date? = nil) {
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
        self.cast = cast
        self.director = director
        self.country = country
        self.trailerUrl = trailerUrl
        self.addedDate = addedDate
    }
    
    func merged(with details: UnifiedMediaItem) -> UnifiedMediaItem {
        var copy = self
        copy.overview = details.overview ?? self.overview
        copy.posterPath = details.posterPath ?? self.posterPath
        copy.backdropPath = details.backdropPath ?? self.backdropPath
        copy.releaseDate = details.releaseDate ?? self.releaseDate
        copy.voteAverage = details.voteAverage ?? self.voteAverage
        copy.runtime = details.runtime ?? self.runtime
        copy.genres = details.genres ?? self.genres
        copy.cast = details.cast ?? self.cast
        copy.director = details.director ?? self.director
        copy.country = details.country ?? self.country
        copy.trailerUrl = details.trailerUrl ?? self.trailerUrl
        copy.addedDate = details.addedDate ?? self.addedDate
        return copy
    }

    private static func parseAddedDate(_ added: String?) -> Date? {
        guard let added = added, let timestamp = TimeInterval(added) else { return nil }
        // Basic sanity check to avoid wildly incorrect dates (e.g., if it's not a timestamp)
        if timestamp > 900000000 {
            return Date(timeIntervalSince1970: timestamp)
        }
        return nil
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
        self.addedDate = nil
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
        self.releaseDate = vod.year
        self.voteAverage = vod.rating ?? (vod.rating5based != nil ? vod.rating5based! * 2 : nil)
        self.runtime = nil
        self.genres = vod.categoryId != nil ? [vod.categoryId!] : nil
        let ext = vod.containerExtension ?? "mp4"
        self.streamUrl = URL(string: "\(creds.serverUrl)/movie/\(creds.username)/\(creds.password)/\(vod.streamId).\(ext)")
        self.epgId = nil
        self.addedDate = UnifiedMediaItem.parseAddedDate(vod.added)
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
        self.addedDate = UnifiedMediaItem.parseAddedDate(series.lastModified)
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
        self.addedDate = nil
    }

    // Initializer from XtreamVODInfo (Details fetch)
    init(from info: XtreamVODInfo) {
        self.id = "" // Handled by merge
        self.title = "" // Handled by merge
        self.overview = info.plot
        self.posterPath = info.movieImage
        self.backdropPath = info.backdropPath?.first
        self.mediaType = .movie
        self.source = .iptv
        self.releaseDate = info.releaseDate
        self.voteAverage = Double(info.rating ?? "") ?? nil
        self.runtime = Int(info.duration ?? "") ?? nil
        self.genres = info.genre != nil ? [info.genre!] : nil
        self.cast = info.cast
        self.director = info.director
        self.country = info.country
        self.trailerUrl = info.youtubeTrailer != nil ? URL(string: "https://youtube.com/watch?v=\(info.youtubeTrailer!)") : nil
        self.addedDate = nil
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
        self.addedDate = UnifiedMediaItem.parseAddedDate(episode.info?.releaseDate) // Using releaseDate as fallback if available
    }
}

// Extension to help existing views
extension TrendingModel {
    var toUnified: UnifiedMediaItem {
        UnifiedMediaItem(from: self)
    }
}

