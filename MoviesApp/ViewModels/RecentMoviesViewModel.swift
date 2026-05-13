//
//  RecentMoviesViewModel.swift
//  MoviesApp
//
//  Created by Antigravity on 13/05/26.
//

import Foundation
import Observation

@Observable
class RecentMoviesViewModel {
    private(set) var fetchStatus = ApiFetchStatus.notstarted
    private let apiService = ApiServices()
    
    var recentChanges: [MovieChange] = []
    
    func getRecentChanges() async {
        fetchStatus = .loading
        
        do {
            let changes = try await apiService.fetchRecentMovieChanges()
            self.recentChanges = changes
            self.fetchStatus = .success
        } catch {
            self.fetchStatus = .error(underlyingError: error)
            print("Error fetching recent changes: \(error)")
        }
    }
}
