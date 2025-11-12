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
    var topRatedMovies: [TrendingModel] = []
    var trendingTVShows: [TrendingModel] = []
    var topRatedTVShows: [TrendingModel] = []
    
    var heroTitle :TrendingModel = TrendingModel.previeTitles[0]
    
    func getTitles() async {
        homeStatus=ApiFetchStatus.loading
        
        if trendingMovies.isEmpty {
            do{
                async let tMovies =  apiService.fetchTrendings(for: "movie", by: "trending")
                async let tTopRatedMovies =  apiService.fetchTrendings(for: "movie", by: "top_rated")
                async let tTvs = apiService.fetchTrendings(for: "tv", by: "trending")
                async let tTopRatedTv = apiService.fetchTrendings(for: "tv", by: "top_rated")
                
                trendingMovies = try await tMovies
                trendingTVShows = try await tTvs
                topRatedMovies = try await tTopRatedMovies
                topRatedTVShows = try await tTopRatedTv
                homeStatus = ApiFetchStatus.success
                
                if let title = trendingMovies.randomElement(){
                    heroTitle = title
                }
            }
            catch {
                homeStatus=ApiFetchStatus.error(underlyingError: error)
            }
        }else {
            homeStatus = ApiFetchStatus.success
        }
    }
    
}
