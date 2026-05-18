//
//  LiveTVViewModel.swift
//  MoviesApp
//

import Foundation
import SwiftUI

@Observable
class LiveTVViewModel {
    var categories: [XtreamCategory] = []
    var allChannels: [IPTVChannel] = []
    var filteredChannels: [IPTVChannel] = []
    var selectedCategory: XtreamCategory?
    
    var isLoading = false
    var errorMessage: String?
    
    private let iptvService = IPTVService.shared
    private let authManager = AuthManager.shared
    
    func loadData() async {
        guard let creds = authManager.credentials else { return }
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            async let cats = iptvService.fetchLiveCategories(creds: creds)
            async let chans = iptvService.fetchXtreamChannels(creds: creds)
            
            let fetchedCategories = try await cats
            let fetchedChannels = try await chans
            
            await MainActor.run {
                self.categories = fetchedCategories
                self.allChannels = fetchedChannels
                
                if let firstCat = self.categories.first {
                    self.selectCategory(firstCat)
                } else {
                    self.filteredChannels = self.allChannels
                }
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func selectCategory(_ category: XtreamCategory) {
        selectedCategory = category
        filteredChannels = allChannels.filter { $0.category == category.id }
    }
}
