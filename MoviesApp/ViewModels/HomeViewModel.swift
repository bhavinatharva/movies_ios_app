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
    
    func getMovies(type:String) async {
        homeStatus=ApiFetchStatus.loading
        
        do{
            if type == "trending" {
                trendingMovies = try await apiService.fetchTrendings(for: "movie", by: type)
            }else if type == "top_rated" {
                topRatedMovies = try await apiService.fetchTrendings(for: "movie", by: type)
            }
            
            homeStatus = ApiFetchStatus.success
        }
        catch {
            homeStatus=ApiFetchStatus.error(underlyingError: error)
        }
    }
    
    func getTVShows(type:String) async {
        homeStatus=ApiFetchStatus.loading
        
        do{
            if type == "trending" {
                trendingTVShows = try await apiService.fetchTrendings(for: "tv", by: type)
            }else if type == "top_rated"{
                topRatedTVShows = try await apiService.fetchTrendings(for: "tv", by: type)
            }
            homeStatus = ApiFetchStatus.success
        }
        catch {
            homeStatus=ApiFetchStatus.error(underlyingError: error)
        }
    }
    
}
