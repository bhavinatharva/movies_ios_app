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
    let mediaType: MediaType
    let toUnified: UnifiedMediaItem
    
    init(name: String, streamUrl: URL, logoUrl: URL?, category: String?, epgId: String?) {
        self.name = name
        self.streamUrl = streamUrl
        self.logoUrl = logoUrl
        self.category = category
        self.epgId = epgId
        
        let group = (category ?? "").lowercased()
        let streamStr = streamUrl.absoluteString.lowercased()
        let nameLower = name.lowercased()
        
        var type: MediaType = .uncategorized
        
        let seriesKeywords = ["series", "tv show", "shows", "season", "episodes", "netflix", "hulu", "amazon prime", "apple tv+", "web series"]
        let hasSeriesKeyword = seriesKeywords.contains(where: { group.contains($0) })
        
        if hasSeriesKeyword || streamStr.contains("/series/") || nameLower.matchesSeriesPattern() {
            type = .tvSeries
        } else {
            let movieKeywords = ["movies", "movie", "vod", "cinema", "film", "box office", "boxoffice", "premiere", "blockbuster", "new release", "marvel", "dc", "disney+"]
            let hasMovieKeyword = movieKeywords.contains(where: { group.contains($0) })
            
            if hasMovieKeyword || streamStr.contains("/movie/") || streamStr.hasSuffix(".mp4") || streamStr.hasSuffix(".mkv") || streamStr.hasSuffix(".avi") || nameLower.matchesMovieYearPattern() {
                type = .movie
            }
        }
        self.mediaType = type
        
        self.toUnified = UnifiedMediaItem(
            id: streamUrl.absoluteString,
            title: name,
            overview: type == .liveTV ? "Live from \(category ?? "IPTV")" : "VOD from \(category ?? "IPTV")",
            posterPath: logoUrl?.absoluteString,
            backdropPath: nil,
            mediaType: type,
            source: .iptv,
            releaseDate: type == .liveTV ? "LIVE" : nil,
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
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = (try? container.decodeIfPresent(String.self, forKey: .name)) ?? "Unknown"
        
        if let idStr = try? container.decode(String.self, forKey: .id) {
            id = idStr
        } else if let idInt = try? container.decode(Int.self, forKey: .id) {
            id = String(idInt)
        } else {
            id = UUID().uuidString
        }
    }
}

struct XtreamVODInfoResponse: Codable {
    let info: XtreamVODInfo?
    let movieData: XtreamVODMovieData?
    
    enum CodingKeys: String, CodingKey {
        case info
        case movieData = "movie_data"
    }
}

struct XtreamVODMovieData: Codable {
    let streamId: Int?
    let name: String?
    let added: String?
    let categoryId: String?
    let containerExtension: String?
    let rating: Double?
    
    enum CodingKeys: String, CodingKey {
        case streamId = "stream_id"
        case name
        case added
        case categoryId = "category_id"
        case containerExtension = "container_extension"
        case rating
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try? container.decodeIfPresent(String.self, forKey: .name)
        
        if let idInt = try? container.decode(Int.self, forKey: .streamId) { streamId = idInt }
        else if let idStr = try? container.decode(String.self, forKey: .streamId), let idInt = Int(idStr) { streamId = idInt }
        else { streamId = nil }
        
        if let aS = try? container.decode(String.self, forKey: .added) { added = aS }
        else if let aI = try? container.decode(Int.self, forKey: .added) { added = String(aI) }
        else { added = nil }
        
        if let cS = try? container.decode(String.self, forKey: .categoryId) { categoryId = cS }
        else if let cI = try? container.decode(Int.self, forKey: .categoryId) { categoryId = String(cI) }
        else { categoryId = nil }
        
        containerExtension = try? container.decodeIfPresent(String.self, forKey: .containerExtension)
        
        if let rD = try? container.decode(Double.self, forKey: .rating) { rating = rD }
        else if let rS = try? container.decode(String.self, forKey: .rating), let rD = Double(rS) { rating = rD }
        else if let rI = try? container.decode(Int.self, forKey: .rating) { rating = Double(rI) }
        else { rating = nil }
    }
}

struct XtreamVODInfo: Codable {
    let movieImage: String?
    let plot: String?
    let cast: String?
    let director: String?
    let genre: String?
    let releaseDate: String?
    let rating: String?
    let duration: String?
    let tmdbId: String?
    let country: String?
    let backdropPath: [String]?
    let youtubeTrailer: String?
    
    enum CodingKeys: String, CodingKey {
        case movieImage = "movie_image"
        case plot
        case cast
        case director
        case genre
        case releaseDate = "releasedate"
        case rating
        case duration
        case tmdbId = "tmdb_id"
        case country
        case backdropPath = "backdrop_path"
        case youtubeTrailer = "youtube_trailer"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        movieImage = try? container.decodeIfPresent(String.self, forKey: .movieImage)
        plot = try? container.decodeIfPresent(String.self, forKey: .plot)
        cast = try? container.decodeIfPresent(String.self, forKey: .cast)
        director = try? container.decodeIfPresent(String.self, forKey: .director)
        genre = try? container.decodeIfPresent(String.self, forKey: .genre)
        releaseDate = try? container.decodeIfPresent(String.self, forKey: .releaseDate)
        
        if let rS = try? container.decode(String.self, forKey: .rating) { rating = rS }
        else if let rD = try? container.decode(Double.self, forKey: .rating) { rating = String(rD) }
        else if let rI = try? container.decode(Int.self, forKey: .rating) { rating = String(rI) }
        else { rating = nil }
        
        if let dS = try? container.decode(String.self, forKey: .duration) { duration = dS }
        else if let dI = try? container.decode(Int.self, forKey: .duration) { duration = String(dI) }
        else { duration = nil }
        
        if let tS = try? container.decode(String.self, forKey: .tmdbId) { tmdbId = tS }
        else if let tI = try? container.decode(Int.self, forKey: .tmdbId) { tmdbId = String(tI) }
        else { tmdbId = nil }
        
        country = try? container.decodeIfPresent(String.self, forKey: .country)
        youtubeTrailer = try? container.decodeIfPresent(String.self, forKey: .youtubeTrailer)
        
        if let bArray = try? container.decode([String].self, forKey: .backdropPath) {
            backdropPath = bArray
        } else if let bString = try? container.decode(String.self, forKey: .backdropPath) {
            backdropPath = [bString]
        } else {
            backdropPath = nil
        }
    }
}

struct XtreamVODStream: Codable {
    let name: String
    let streamId: Int
    let streamIcon: String?
    let categoryId: String?
    let rating: Double?
    let rating5based: Double?
    let added: String?
    let year: String?
    let containerExtension: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case streamId = "stream_id"
        case streamIcon = "stream_icon"
        case categoryId = "category_id"
        case rating
        case rating5based = "rating_5based"
        case added
        case year
        case containerExtension = "container_extension"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = (try? container.decodeIfPresent(String.self, forKey: .name)) ?? "Unknown"
        
        if let idInt = try? container.decode(Int.self, forKey: .streamId) {
            streamId = idInt
        } else if let idStr = try? container.decode(String.self, forKey: .streamId), let idInt = Int(idStr) {
            streamId = idInt
        } else {
            streamId = 0
        }
        
        streamIcon = try? container.decodeIfPresent(String.self, forKey: .streamIcon)
        categoryId = try? container.decodeIfPresent(String.self, forKey: .categoryId)
        
        if let rD = try? container.decode(Double.self, forKey: .rating) {
            rating = rD
        } else if let rS = try? container.decode(String.self, forKey: .rating), let rD = Double(rS) {
            rating = rD
        } else if let rI = try? container.decode(Int.self, forKey: .rating) {
            rating = Double(rI)
        } else {
            rating = nil
        }
        
        if let r5D = try? container.decode(Double.self, forKey: .rating5based) {
            rating5based = r5D
        } else if let r5S = try? container.decode(String.self, forKey: .rating5based), let r5D = Double(r5S) {
            rating5based = r5D
        } else {
            rating5based = nil
        }
        
        if let aS = try? container.decode(String.self, forKey: .added) {
            added = aS
        } else if let aI = try? container.decode(Int.self, forKey: .added) {
            added = String(aI)
        } else {
            added = nil
        }
        
        if let yS = try? container.decode(String.self, forKey: .year) {
            year = yS
        } else if let yI = try? container.decode(Int.self, forKey: .year) {
            year = String(yI)
        } else {
            year = nil
        }
        
        containerExtension = try? container.decodeIfPresent(String.self, forKey: .containerExtension)
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
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = (try? container.decodeIfPresent(String.self, forKey: .name)) ?? "Unknown"
        
        if let idInt = try? container.decode(Int.self, forKey: .seriesId) {
            seriesId = idInt
        } else if let idStr = try? container.decode(String.self, forKey: .seriesId), let idInt = Int(idStr) {
            seriesId = idInt
        } else {
            seriesId = 0
        }
        
        cover = try? container.decodeIfPresent(String.self, forKey: .cover)
        categoryId = try? container.decodeIfPresent(String.self, forKey: .categoryId)
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
    
    func matchesMovieYearPattern() -> Bool {
        // Detects patterns like (2012), [2019], (1998) which are highly indicative of movies
        let pattern = "(\\(|\\[)\\s*(19|20)\\d{2}\\s*(\\)|\\])"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let range = NSRange(location: 0, length: self.count)
            return regex.firstMatch(in: self, options: [], range: range) != nil
        }
        return false
    }
}
