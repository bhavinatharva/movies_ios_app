//
//  UnifiedMediaDetailViewModel.swift

//

import Foundation
import SwiftUI
import Combine

@MainActor
@Observable
class UnifiedMediaDetailViewModel {
    var item: UnifiedMediaItem
    var isLoading: Bool = false
    var error: Error? = nil
    
    var relatedMovies: [UnifiedMediaItem] = []
    
    // Simple static memory cache to prevent duplicate loads during a session
    private static var detailsCache: [String: UnifiedMediaItem] = [:]
    private static var cacheQueue: [String] = []
    private static let maxCacheSize = 20
    
    init(item: UnifiedMediaItem) {
        self.item = item
    }
    
    func loadDetails() async {
        // Return immediately if already cached
        if let cached = Self.detailsCache[item.id] {
            self.item = cached
            Task { await fetchRelatedMovies() }
            return
        }
        
        // Only fetch if it's an IPTV movie
        guard item.source == .iptv, item.mediaType == .movie else {
            return
        }
        
        // Ensure we have credentials
        guard let creds = AuthManager.shared.credentials, let vodId = Int(item.id) else {
            return
        }
        
        self.isLoading = true
        self.error = nil
        
        do {
            let response = try await IPTVService.shared.fetchVODInfo(creds: creds, vodId: vodId)
            if let info = response.info {
                let detailItem = UnifiedMediaItem(from: info)
                
                // Keep the original item's ID, title, stream URL, etc., and merge the new details
                self.item = self.item.merged(with: detailItem)
                
                // Cache it
                Self.detailsCache[self.item.id] = self.item
                if !Self.cacheQueue.contains(self.item.id) {
                    Self.cacheQueue.append(self.item.id)
                    if Self.cacheQueue.count > Self.maxCacheSize {
                        let oldest = Self.cacheQueue.removeFirst()
                        Self.detailsCache.removeValue(forKey: oldest)
                    }
                }
            }
            
            Task { await fetchRelatedMovies() }
        } catch {
            self.error = error
            #if DEBUG
            print("⚠️ [UnifiedMediaDetailViewModel] Failed to fetch VOD Info: \(error)")
            #endif
        }
        
        self.isLoading = false
    }
    
    private func fetchRelatedMovies() async {
        // Run on background thread to prevent UI freezing
        let allMovies = IPTVDataManager.shared.movies
        let currentItem = self.item
        
        let related = await Task.detached(priority: .background) {
            let currentGenres = currentItem.genres ?? []
            let currentYear = currentItem.releaseDate
            
            let filtered = allMovies.filter { movie in
                if movie.id == currentItem.id { return false }
                
                // Match genre
                if let genres = movie.genres, !currentGenres.isEmpty, !Set(genres).isDisjoint(with: Set(currentGenres)) {
                    return true
                }
                
                // Match year if genre is empty
                if let year = movie.releaseDate, year == currentYear, currentYear != nil {
                    return true
                }
                
                return false
            }
            return Array(filtered.shuffled().prefix(15))
        }.value
        
        self.relatedMovies = related
    }
}
