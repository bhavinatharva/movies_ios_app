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
    
    func fetchM3U(url: URL) async throws -> [IPTVChannel] {
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let content = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "IPTVService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid M3U Encoding"])
        }
        return M3UParser.parse(content)
    }
    
    // Xtream Codes Implementation
    func loginXtream(creds: XtreamCredentials) async throws -> Bool {
        let urlString = "\(creds.serverUrl)/player_api.php?username=\(creds.username)&password=\(creds.password)"
        guard let url = URL(string: urlString) else { return false }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(XtreamResponse.self, from: data)
        return response.userInfo.auth == 1
    }
    
    func fetchXtreamChannels(creds: XtreamCredentials) async throws -> [IPTVChannel] {
        let urlString = "\(creds.serverUrl)/player_api.php?username=\(creds.username)&password=\(creds.password)&action=get_live_streams"
        guard let url = URL(string: urlString) else { return [] }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let streams = try JSONDecoder().decode([XtreamStream].self, from: data)
        
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
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([XtreamCategory].self, from: data)
    }

    func fetchVODCategories(creds: XtreamCredentials) async throws -> [XtreamCategory] {
        let urlString = "\(creds.serverUrl)/player_api.php?username=\(creds.username)&password=\(creds.password)&action=get_vod_categories"
        guard let url = URL(string: urlString) else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([XtreamCategory].self, from: data)
    }

    func fetchVODStreams(creds: XtreamCredentials, categoryId: String? = nil) async throws -> [XtreamVODStream] {
        var urlString = "\(creds.serverUrl)/player_api.php?username=\(creds.username)&password=\(creds.password)&action=get_vod_streams"
        if let catId = categoryId {
            urlString += "&category_id=\(catId)"
        }
        guard let url = URL(string: urlString) else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([XtreamVODStream].self, from: data)
    }

    func fetchSeriesCategories(creds: XtreamCredentials) async throws -> [XtreamCategory] {
        let urlString = "\(creds.serverUrl)/player_api.php?username=\(creds.username)&password=\(creds.password)&action=get_series_categories"
        guard let url = URL(string: urlString) else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([XtreamCategory].self, from: data)
    }

    func fetchSeries(creds: XtreamCredentials, categoryId: String? = nil) async throws -> [XtreamSeries] {
        var urlString = "\(creds.serverUrl)/player_api.php?username=\(creds.username)&password=\(creds.password)&action=get_series"
        if let catId = categoryId {
            urlString += "&category_id=\(catId)"
        }
        guard let url = URL(string: urlString) else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([XtreamSeries].self, from: data)
    }

    func fetchSeriesInfo(creds: XtreamCredentials, seriesId: Int) async throws -> XtreamSeriesInfoResponse {
        let urlString = "\(creds.serverUrl)/player_api.php?username=\(creds.username)&password=\(creds.password)&action=get_series_info&series_id=\(seriesId)"
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "IPTVService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(XtreamSeriesInfoResponse.self, from: data)
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
