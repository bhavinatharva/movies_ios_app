//
//  UserDataManager.swift
//  MoviesApp
//

import Foundation

@Observable
class UserDataManager {
    static let shared = UserDataManager()
    
    private let favoritesKey = "iptv_favorites"
    private let historyKey = "iptv_history"
    private let progressKey = "iptv_progress"
    
    var favorites: Set<String> = []
    var recentlyWatched: [UnifiedMediaItem] = []
    var watchProgress: [String: Double] = [:] // streamId -> duration in seconds
    
    private init() {
        loadData()
    }
    
    func loadData() {
        // Load Favorites
        if let favArray = UserDefaults.standard.stringArray(forKey: favoritesKey) {
            self.favorites = Set(favArray)
        } else {
            self.favorites = []
        }
        
        // Load Watch History
        if let historyData = UserDefaults.standard.data(forKey: historyKey),
           let history = try? JSONDecoder().decode([UnifiedMediaItem].self, from: historyData) {
            self.recentlyWatched = history
        } else {
            self.recentlyWatched = []
        }
        
        // Load Progress
        if let progressDict = UserDefaults.standard.dictionary(forKey: progressKey) as? [String: Double] {
            self.watchProgress = progressDict
        } else {
            self.watchProgress = [:]
        }
    }
    
    // MARK: - Favorites
    
    func isFavorite(id: String) -> Bool {
        favorites.contains(id)
    }
    
    func toggleFavorite(id: String) {
        if favorites.contains(id) {
            favorites.remove(id)
        } else {
            favorites.insert(id)
        }
        UserDefaults.standard.set(Array(favorites), forKey: favoritesKey)
    }
    
    // MARK: - Recently Watched
    
    func addToHistory(_ item: UnifiedMediaItem) {
        recentlyWatched.removeAll { $0.id == item.id }
        recentlyWatched.insert(item, at: 0)
        
        // Keep only top 20 items
        if recentlyWatched.count > 20 {
            recentlyWatched = Array(recentlyWatched.prefix(20))
        }
        
        saveHistory()
    }
    
    func removeFromHistory(id: String) {
        recentlyWatched.removeAll { $0.id == id }
        saveHistory()
    }
    
    private func saveHistory() {
        if let data = try? JSONEncoder().encode(recentlyWatched) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }
    
    // MARK: - Continue Watching Progress
    
    func updateProgress(id: String, seconds: Double) {
        watchProgress[id] = seconds
        UserDefaults.standard.set(watchProgress, forKey: progressKey)
    }
    
    func getProgress(id: String) -> Double {
        watchProgress[id] ?? 0.0
    }
}
