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
    
    private let apiService = ApiServices()
    var trendingMovies: [TrendingModel] = []
    
    func getTrendingMovies() async {
        homeStatus=ApiFetchStatus.loading
        
        do{
            trendingMovies = try await apiService.fetchTrendings(for: "movie", by: "trending")
            homeStatus = ApiFetchStatus.success
        }
        catch {
            homeStatus=ApiFetchStatus.error(underlyingError: error)
        }
    }
    
}
