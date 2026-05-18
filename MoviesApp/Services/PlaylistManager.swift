//
//  PlaylistManager.swift
//  MoviesApp
//
//  Created by Antigravity on 15/05/26.
//

import Foundation

class PlaylistManager {
    static let shared = PlaylistManager()
    
    private let playlistsKey = "saved_playlists"
    private let channelsCachePrefix = "channels_cache_"
    
    private init() {}
    
    // MARK: - Playlist Operations
    
    func fetchAllPlaylists() -> [Playlist] {
        guard let data = UserDefaults.standard.data(forKey: playlistsKey),
              let playlists = try? JSONDecoder().decode([Playlist].self, from: data) else {
            return []
        }
        return playlists.sorted { $0.createdAt > $1.createdAt }
    }
    
    func fetchDefaultPlaylist() -> Playlist? {
        fetchAllPlaylists().first { $0.isDefault }
    }
    
    private func savePlaylists(_ playlists: [Playlist]) {
        if let data = try? JSONEncoder().encode(playlists) {
            UserDefaults.standard.set(data, forKey: playlistsKey)
        }
    }
    
    func addPlaylist(name: String, url: String) {
        var finalUrl = url
        
        // Intercept massive data URLs or raw playlist text to save them to a file instead of UserDefaults
        if url.lowercased().hasPrefix("data:") || url.contains("\n") || url.count > 1024 {
            let filename = "local_playlist_\(UUID().uuidString).m3u"
            if let docsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let fileUrl = docsDirectory.appendingPathComponent(filename)
                
                var playlistData: Data? = nil
                if url.lowercased().hasPrefix("data:"), let parsedUrl = URL(string: url) {
                    playlistData = try? Data(contentsOf: parsedUrl)
                }
                
                if playlistData == nil {
                    playlistData = url.data(using: .utf8)
                }
                
                if let data = playlistData {
                    do {
                        try data.write(to: fileUrl)
                        finalUrl = fileUrl.absoluteString
                    } catch {
                        print("Failed to save local playlist file: \(error)")
                    }
                }
            }
        }
        
        var playlists = fetchAllPlaylists()
        let isFirst = playlists.isEmpty
        let playlist = Playlist(name: name, url: finalUrl, isDefault: isFirst)
        playlists.append(playlist)
        savePlaylists(playlists)
        
        if isFirst {
            UserDefaults.standard.set(finalUrl, forKey: "active_playlist_url")
            UserDefaults.standard.set(true, forKey: "has_default_playlist")
        }
    }
    
    func setDefault(_ playlist: Playlist) {
        var playlists = fetchAllPlaylists()
        for i in 0..<playlists.count {
            playlists[i].isDefault = (playlists[i].id == playlist.id)
        }
        savePlaylists(playlists)
        UserDefaults.standard.set(playlist.url, forKey: "active_playlist_url")
    }
    
    func deletePlaylist(_ playlist: Playlist) {
        var playlists = fetchAllPlaylists()
        let wasDefault = playlists.first(where: { $0.id == playlist.id })?.isDefault ?? false
        playlists.removeAll { $0.id == playlist.id }
        
        if wasDefault && !playlists.isEmpty {
            playlists[0].isDefault = true
            UserDefaults.standard.set(playlists[0].url, forKey: "active_playlist_url")
        }
        
        savePlaylists(playlists)
        
        if playlists.isEmpty {
            UserDefaults.standard.set("", forKey: "active_playlist_url")
            UserDefaults.standard.set(false, forKey: "has_default_playlist")
        }
        
        // Delete associated cached channels
        if let fileUrl = getCacheFileUrl(forUrl: playlist.url) {
            try? FileManager.default.removeItem(at: fileUrl)
        }
    }
    
    // MARK: - Channel Caching
    
    private func getCacheFileUrl(forUrl url: String) -> URL? {
        guard let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        let safeFilename = url.components(separatedBy: CharacterSet.alphanumerics.inverted).joined() + ".json"
        return cachesDirectory.appendingPathComponent(safeFilename)
    }
    
    func cacheChannels(_ channels: [IPTVChannel], forUrl url: String) {
        let cachedChannels = channels.map { CachedChannel(playlistUrl: url, channel: $0) }
        guard let data = try? JSONEncoder().encode(cachedChannels),
              let fileUrl = getCacheFileUrl(forUrl: url) else {
            return
        }
        try? data.write(to: fileUrl)
    }
    
    func getCachedChannels(forUrl url: String) -> [IPTVChannel] {
        guard let fileUrl = getCacheFileUrl(forUrl: url),
              let data = try? Data(contentsOf: fileUrl),
              let cached = try? JSONDecoder().decode([CachedChannel].self, from: data) else {
            return []
        }
        return cached.map { $0.toIPTVChannel }
    }
}
