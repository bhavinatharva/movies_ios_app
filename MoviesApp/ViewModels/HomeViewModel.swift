//
//  HomeViewModel.swift
//  MoviesApp
//
//  Created by Bhavin Parghi on 11/11/25.
//

import Foundation

@Observable
class HomeViewModel {
    private(set) var homeStatus = ApiFetchStatus.notstarted
    private let iptvService = IPTVService.shared
    
    var liveChannels: [IPTVChannel] = []
    var categorizedChannels: [String: [IPTVChannel]] = [:]
    
    func getTitles(url: String) async {
        guard let m3uUrl = URL(string: url) else {
            homeStatus = .error(underlyingError: NSError(domain: "HomeViewModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        
        homeStatus = .loading
        
        do {
            let fetchedChannels = try await iptvService.fetchM3U(url: m3uUrl)
            self.liveChannels = fetchedChannels
            
            // Group channels by category
            self.categorizedChannels = Dictionary(grouping: fetchedChannels) { $0.category ?? "General" }
            
            homeStatus = .success
        } catch {
            homeStatus = .error(underlyingError: error)
        }
    }
}
