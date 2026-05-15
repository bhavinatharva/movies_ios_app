//
//  PlaylistManager.swift
//  MoviesApp
//
//  Created by Antigravity on 15/05/26.
//

import Foundation
import RealmSwift

class PlaylistManager {
    static let shared = PlaylistManager()
    private let realm: Realm
    
    private init() {
        let config = Realm.Configuration(schemaVersion: 1)
        realm = try! Realm(configuration: config)
    }
    
    // MARK: - Playlist Operations
    
    func fetchAllPlaylists() -> [Playlist] {
        Array(realm.objects(Playlist.self).sorted(byKeyPath: "createdAt", ascending: false))
    }
    
    func fetchDefaultPlaylist() -> Playlist? {
        realm.objects(Playlist.self).filter("isDefault == true").first
    }
    
    func addPlaylist(name: String, url: String) {
        let isFirst = realm.objects(Playlist.self).isEmpty
        let playlist = Playlist(name: name, url: url, isDefault: isFirst)
        
        try? realm.write {
            realm.add(playlist)
        }
    }
    
    func setDefault(_ playlist: Playlist) {
        try? realm.write {
            let all = realm.objects(Playlist.self)
            for p in all {
                p.isDefault = (p.id == playlist.id)
            }
        }
    }
    
    func deletePlaylist(_ playlist: Playlist) {
        try? realm.write {
            // Delete associated cached channels first
            let cached = realm.objects(CachedChannel.self).filter("playlistUrl == %@", playlist.url)
            realm.delete(cached)
            realm.delete(playlist)
        }
    }
    
    // MARK: - Channel Caching
    
    func cacheChannels(_ channels: [IPTVChannel], forUrl url: String) {
        try? realm.write {
            // Clear existing cache for this URL
            let existing = realm.objects(CachedChannel.self).filter("playlistUrl == %@", url)
            realm.delete(existing)
            
            // Add new channels
            for channel in channels {
                let cached = CachedChannel(playlistUrl: url, channel: channel)
                realm.add(cached, update: .modified)
            }
        }
    }
    
    func getCachedChannels(forUrl url: String) -> [IPTVChannel] {
        let cached = realm.objects(CachedChannel.self).filter("playlistUrl == %@", url)
        return cached.map { $0.toIPTVChannel }
    }
}
