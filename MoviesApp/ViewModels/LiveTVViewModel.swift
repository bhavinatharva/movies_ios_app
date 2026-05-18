//
//  LiveTVViewModel.swift
//  MoviesApp
//

import Foundation
import SwiftUI

@Observable
class LiveTVViewModel {
    var categories: [String] = []
    var allChannels: [IPTVChannel] = []
    var filteredChannels: [IPTVChannel] = []
    var selectedCategory: String?
    
    var isLoading = false
    var errorMessage: String?
    
    private let playlistManager = PlaylistManager.shared
    
    func loadData() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        guard let defaultPlaylist = playlistManager.fetchDefaultPlaylist() else {
            await MainActor.run {
                isLoading = false
            }
            return
        }
        
        let cached = playlistManager.getCachedChannels(forUrl: defaultPlaylist.url)
        
        await MainActor.run {
            self.allChannels = cached
            self.categories = Array(Set(cached.compactMap { $0.category })).sorted()
            if let firstCat = self.categories.first {
                self.selectCategory(firstCat)
            } else {
                self.filteredChannels = cached
            }
            self.isLoading = false
        }
    }
    
    func selectCategory(_ category: String) {
        selectedCategory = category
        filteredChannels = allChannels.filter { $0.category == category }
    }
}
