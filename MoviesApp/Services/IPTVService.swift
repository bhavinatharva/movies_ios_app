//
//  IPTVService.swift
//  MoviesApp
//
//  Created by Antigravity on 14/05/26.
//

import Foundation

class IPTVService {
    static let shared = IPTVService()
    
    private init() {}
    
    // Background decoder helper
    private func decodeInBackground<T: Decodable>(_ type: T.Type, from data: Data) async throws -> T {
        return try await Task.detached(priority: .userInitiated) {
            return try JSONDecoder().decode(T.self, from: data)
        }.value
    }
    
    func fetchM3U(url: URL) async throws -> [IPTVChannel] {
        let data = try await IPTVRequestManager.shared.performFetch(url: url, type: .m3u)
        guard let content = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "IPTVService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid M3U Encoding"])
        }
        return M3UParser.parse(content)
    }
    
    func fetchGetM3U(creds: XtreamCredentials) async throws -> [IPTVChannel] {
        let urlString = "\(creds.serverUrl)/get.php?username=\(creds.username)&password=\(creds.password)&output=ts"
        guard let url = URL(string: urlString) else { return [] }
        return try await fetchM3U(url: url)
    }
    
    func fetchMoviePHP(creds: XtreamCredentials) async throws -> [XtreamVODStream] {
        let urlString = "\(creds.serverUrl)/movie.php?username=\(creds.username)&password=\(creds.password)"
        guard let url = URL(string: urlString) else { return [] }
        let data = try await IPTVRequestManager.shared.performFetch(url: url, type: .vod)
        return try await decodeInBackground([XtreamVODStream].self, from: data)
    }
    
    func fetchSeriesPHP(creds: XtreamCredentials) async throws -> [XtreamSeries] {
        let urlString = "\(creds.serverUrl)/series.php?username=\(creds.username)&password=\(creds.password)"
        guard let url = URL(string: urlString) else { return [] }
        let data = try await IPTVRequestManager.shared.performFetch(url: url, type: .series)
        return try await decodeInBackground([XtreamSeries].self, from: data)
    }
    
    func fetchEPG(creds: XtreamCredentials) async throws -> Data {
        let urlString = "\(creds.serverUrl)/xmltv.php?username=\(creds.username)&password=\(creds.password)"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        return try await IPTVRequestManager.shared.performFetch(url: url, type: .epg)
    }
    
    func loginXtream(creds: XtreamCredentials) async throws -> Bool {
        let urlString = "\(creds.serverUrl)/player_api.php?username=\(creds.username)&password=\(creds.password)"
        guard let url = URL(string: urlString) else { return false }
        let data = try await IPTVRequestManager.shared.performFetch(url: url, type: .auth, useCache: false)
        let response = try await decodeInBackground(XtreamResponse.self, from: data)
        return response.userInfo.auth == 1
    }
    
    func fetchXtreamChannels(creds: XtreamCredentials) async throws -> [IPTVChannel] {
        let urlString = "\(creds.serverUrl)/player_api.php?username=\(creds.username)&password=\(creds.password)&action=get_live_streams"
        guard let url = URL(string: urlString) else { return [] }
        let data = try await IPTVRequestManager.shared.performFetch(url: url, type: .live)
        
        #if DEBUG
        if let jsonStr = String(data: data, encoding: .utf8) {
            print("📡 [Xtream] Fetched Live Streams JSON (Size: \(data.count) bytes)")
            print("📡 [Xtream] Preview: \(jsonStr.prefix(500))")
        }
        #endif
        
        let streams = try await decodeInBackground([XtreamStream].self, from: data)
        return streams.map { stream in
            IPTVChannel(
                name: stream.name,
                streamUrl: URL(string: "\(creds.serverUrl)/live/\(creds.username)/\(creds.password)/\(stream.streamId).m3u8")!,
                logoUrl: URL(string: stream.streamIcon),
                category: stream.categoryId,
                epgId: stream.epgChannelId
            )
        }
    }
    
    func fetchLiveCategories(creds: XtreamCredentials) async throws -> [XtreamCategory] {
        let urlString = "\(creds.serverUrl)/player_api.php?username=\(creds.username)&password=\(creds.password)&action=get_live_categories"
        guard let url = URL(string: urlString) else { return [] }
        let data = try await IPTVRequestManager.shared.performFetch(url: url, type: .live)
        return try await decodeInBackground([XtreamCategory].self, from: data)
    }
    
    func fetchVODCategories(creds: XtreamCredentials) async throws -> [XtreamCategory] {
        let urlString = "\(creds.serverUrl)/player_api.php?username=\(creds.username)&password=\(creds.password)&action=get_vod_categories"
        guard let url = URL(string: urlString) else { return [] }
        let data = try await IPTVRequestManager.shared.performFetch(url: url, type: .vod)
        return try await decodeInBackground([XtreamCategory].self, from: data)
    }
    
    func fetchVODStreams(creds: XtreamCredentials, categoryId: String? = nil) async throws -> [XtreamVODStream] {
        var urlString = "\(creds.serverUrl)/player_api.php?username=\(creds.username)&password=\(creds.password)&action=get_vod_streams"
        if let catId = categoryId { urlString += "&category_id=\(catId)" }
        guard let url = URL(string: urlString) else { return [] }
        let data = try await IPTVRequestManager.shared.performFetch(url: url, type: .vod)
        return try await decodeInBackground([XtreamVODStream].self, from: data)
    }
    
    func fetchSeriesCategories(creds: XtreamCredentials) async throws -> [XtreamCategory] {
        let urlString = "\(creds.serverUrl)/player_api.php?username=\(creds.username)&password=\(creds.password)&action=get_series_categories"
        guard let url = URL(string: urlString) else { return [] }
        let data = try await IPTVRequestManager.shared.performFetch(url: url, type: .series)
        return try await decodeInBackground([XtreamCategory].self, from: data)
    }
    
    func fetchSeries(creds: XtreamCredentials, categoryId: String? = nil) async throws -> [XtreamSeries] {
        var urlString = "\(creds.serverUrl)/player_api.php?username=\(creds.username)&password=\(creds.password)&action=get_series"
        if let catId = categoryId { urlString += "&category_id=\(catId)" }
        guard let url = URL(string: urlString) else { return [] }
        let data = try await IPTVRequestManager.shared.performFetch(url: url, type: .series)
        return try await decodeInBackground([XtreamSeries].self, from: data)
    }
    
    func fetchSeriesInfo(creds: XtreamCredentials, seriesId: Int) async throws -> XtreamSeriesInfoResponse {
        let urlString = "\(creds.serverUrl)/player_api.php?username=\(creds.username)&password=\(creds.password)&action=get_series_info&series_id=\(seriesId)"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        let data = try await IPTVRequestManager.shared.performFetch(url: url, type: .series)
        return try await decodeInBackground(XtreamSeriesInfoResponse.self, from: data)
    }
}

// Internal models for Xtream API
struct XtreamResponse: Codable {
    let userInfo: XtreamUserInfo
    enum CodingKeys: String, CodingKey {
        case userInfo = "user_info"
    }
}

struct XtreamUserInfo: Codable {
    let auth: Int
}

struct XtreamStream: Codable {
    let name: String
    let streamId: Int
    let streamIcon: String
    let categoryId: String
    let epgChannelId: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case streamId = "stream_id"
        case streamIcon = "stream_icon"
        case categoryId = "category_id"
        case epgChannelId = "epg_channel_id"
    }
}
