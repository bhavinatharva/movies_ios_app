//
//  PlaylistManager.swift

//
//  Created by Antigravity on 15/05/26.
//

import Foundation

class PlaylistManager {
    static let shared = PlaylistManager()
    
    private let playlistsKey = "saved_playlists"
    
    private init() {
        self.cleanupOversizedUserDefaults()
    }
    
    private func cleanupOversizedUserDefaults() {
        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionaryRepresentation()
        
        for (key, value) in dictionary {
            var valueSize = 0
            if let data = value as? Data {
                valueSize = data.count
            } else if let str = value as? String {
                valueSize = str.utf8.count
            } else if let array = value as? [Any] {
                if let data = try? JSONSerialization.data(withJSONObject: array, options: []) {
                    valueSize = data.count
                }
            } else if let dict = value as? [String: Any] {
                if let data = try? JSONSerialization.data(withJSONObject: dict, options: []) {
                    valueSize = data.count
                }
            }
            
            if valueSize > 1_000_000 {
                print("⚠️ Found oversized UserDefaults key '\(key)' of size \(valueSize) bytes. Performing cleanup...")
                
                if key == playlistsKey {
                    if let data = defaults.data(forKey: playlistsKey),
                       var playlists = try? JSONDecoder().decode([Playlist].self, from: data) {
                        var migrated = false
                        for i in 0..<playlists.count {
                            let url = playlists[i].url
                            if url.count > 1024 || url.contains("\n") {
                                let filename = "migrated_local_\(playlists[i].id).m3u"
                                if let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                                    let fileUrl = docs.appendingPathComponent(filename)
                                    if let fileData = url.data(using: .utf8) {
                                        try? fileData.write(to: fileUrl)
                                        playlists[i].url = fileUrl.absoluteString
                                        migrated = true
                                    }
                                }
                            }
                        }
                        if migrated, let encoded = try? JSONEncoder().encode(playlists) {
                            defaults.set(encoded, forKey: playlistsKey)
                            print("✅ Successfully migrated oversized playlist URLs to files.")
                        } else {
                            defaults.removeObject(forKey: key)
                        }
                    } else {
                        defaults.removeObject(forKey: key)
                    }
                } else {
                    defaults.removeObject(forKey: key)
                    print("🧹 Wiped unrecognized oversized key '\(key)'.")
                }
            }
        }
        
        if let activeUrl = defaults.string(forKey: "active_playlist_url"), (activeUrl.count > 1024 || activeUrl.contains("\n")) {
            defaults.removeObject(forKey: "active_playlist_url")
            print("🧹 Reset active_playlist_url because it was oversized.")
        }
        
        defaults.synchronize()
    }
    
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
    
    @discardableResult
    func addPlaylist(name: String, url: String) -> Playlist {
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
        
        return playlist
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
    }
}
