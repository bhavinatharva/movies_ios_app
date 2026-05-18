//
//  UserDataManager.swift
//  MoviesApp
//

import Foundation
import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case dark = "Dark"
    case light = "Light"
    case system = "Auto (System)"
    
    var id: String { self.rawValue }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .dark: return .dark
        case .light: return .light
        case .system: return nil
        }
    }
}

@Observable
class UserDataManager {
    static let shared = UserDataManager()
    
    private let favoritesKey = "iptv_favorites"
    private let historyKey = "iptv_history"
    private let progressKey = "iptv_progress"
    private let themeKey = "iptv_app_theme"
    
    var favorites: Set<String> = []
    var recentlyWatched: [UnifiedMediaItem] = []
    var watchProgress: [String: Double] = [:] // streamId -> duration in seconds
    var currentTheme: AppTheme = .dark {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: themeKey)
        }
    }
    
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
        
        // Load Theme
        if let themeStr = UserDefaults.standard.string(forKey: themeKey),
           let theme = AppTheme(rawValue: themeStr) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .dark
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
