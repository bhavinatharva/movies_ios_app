//
//  UserDataManager.swift

//
//  Created by Antigravity on 18/05/26.
//

import Foundation
import SwiftUI
import CoreData

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
        // 1. Load Favorites from persistent local database (CoreData)
        self.favorites = IPTVLocalDatabase.shared.fetchFavorites()
        
        // 2. Load watchProgress from persistent local database (CoreData)
        self.watchProgress = IPTVLocalDatabase.shared.fetchProgress()
        
        // 3. Load Watch History from persistent local database (CoreData)
        let historyIds = IPTVLocalDatabase.shared.fetchHistoryIds()
        var mappedHistory: [UnifiedMediaItem] = []
        let channels = IPTVDataManager.shared.liveChannels
        let movies = IPTVDataManager.shared.movies
        let series = IPTVDataManager.shared.series
        
        for id in historyIds {
            if let ch = channels.first(where: { $0.toUnified.id == id }) {
                mappedHistory.append(ch.toUnified)
            } else if let mv = movies.first(where: { $0.id == id }) {
                mappedHistory.append(mv)
            } else if let sr = series.first(where: { $0.id == id }) {
                mappedHistory.append(sr)
            }
        }
        
        // Fallback: If not present in memory, load from CoreData media items cache directly
        if mappedHistory.count < historyIds.count {
            let coreMovies = IPTVLocalDatabase.shared.fetchMediaItems(type: .movie)
            let coreSeries = IPTVLocalDatabase.shared.fetchMediaItems(type: .tvSeries)
            
            for id in historyIds {
                if !mappedHistory.contains(where: { $0.id == id }) {
                    if let mv = coreMovies.first(where: { $0.id == id }) {
                        mappedHistory.append(mv)
                    } else if let sr = coreSeries.first(where: { $0.id == id }) {
                        mappedHistory.append(sr)
                    }
                }
            }
        }
        
        self.recentlyWatched = mappedHistory
        
        // 4. Load Theme from light-weight UserDefaults
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
            IPTVLocalDatabase.shared.saveFavorite(id: id, type: "media", isFav: false)
        } else {
            favorites.insert(id)
            IPTVLocalDatabase.shared.saveFavorite(id: id, type: "media", isFav: true)
        }
    }
    
    // MARK: - Recently Watched
    
    func addToHistory(_ item: UnifiedMediaItem) {
        recentlyWatched.removeAll { $0.id == item.id }
        recentlyWatched.insert(item, at: 0)
        
        if recentlyWatched.count > 20 {
            recentlyWatched = Array(recentlyWatched.prefix(20))
        }
        
        IPTVLocalDatabase.shared.saveHistoryItem(id: item.id)
        
        // Batch and persistently cache metadata in the database for instant offline startup
        IPTVLocalDatabase.shared.saveMediaItems([item]) {}
    }
    
    func removeFromHistory(id: String) {
        recentlyWatched.removeAll { $0.id == id }
        
        let context = IPTVLocalDatabase.shared.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "HistoryEntity")
        fetchRequest.predicate = NSPredicate(format: "contentId == %@", id)
        if let results = try? context.fetch(fetchRequest) {
            for obj in results {
                context.delete(obj)
            }
            try? context.save()
        }
    }
    
    func clearHistory() {
        recentlyWatched.removeAll()
        IPTVLocalDatabase.shared.clearHistory()
    }
    
    // MARK: - Recommendations
    
    func generateRecommendations(from allItems: [UnifiedMediaItem], limit: Int = 15) -> [UnifiedMediaItem] {
        let watchedIds = Set(recentlyWatched.map { $0.id })
        var watchedGenres: Set<String> = []
        
        for item in recentlyWatched {
            if let genres = item.genres {
                for genre in genres {
                    watchedGenres.insert(genre)
                }
            }
        }
        
        // Exclude watched items
        let unwatchedItems = allItems.filter { !watchedIds.contains($0.id) }
        guard !unwatchedItems.isEmpty else { return [] }
        
        var recommendedItems: [UnifiedMediaItem] = []
        
        if watchedGenres.isEmpty {
            var items = unwatchedItems
            let count = min(limit, items.count)
            for i in 0..<count {
                let randomIndex = Int.random(in: i..<items.count)
                items.swapAt(i, randomIndex)
                recommendedItems.append(items[i])
            }
            return recommendedItems
        }
        
        var matchedItems: [UnifiedMediaItem] = []
        var fallbackItems: [UnifiedMediaItem] = []
        
        for item in unwatchedItems {
            if let genres = item.genres, !watchedGenres.isDisjoint(with: Set(genres)) {
                matchedItems.append(item)
            } else {
                fallbackItems.append(item)
            }
        }
        
        let matchCount = min(limit, matchedItems.count)
        for i in 0..<matchCount {
            let randomIndex = Int.random(in: i..<matchedItems.count)
            matchedItems.swapAt(i, randomIndex)
            recommendedItems.append(matchedItems[i])
        }
        
        let needed = limit - recommendedItems.count
        let fallbackCount = min(needed, fallbackItems.count)
        for i in 0..<fallbackCount {
            let randomIndex = Int.random(in: i..<fallbackItems.count)
            fallbackItems.swapAt(i, randomIndex)
            recommendedItems.append(fallbackItems[i])
        }
        
        return recommendedItems
    }
    
    // MARK: - Continue Watching Progress
    
    func updateProgress(id: String, seconds: Double) {
        watchProgress[id] = seconds
        IPTVLocalDatabase.shared.saveProgress(id: id, type: "media", position: seconds, duration: seconds)
    }
    
    func getProgress(id: String) -> Double {
        watchProgress[id] ?? 0.0
    }
}
