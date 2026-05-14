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
