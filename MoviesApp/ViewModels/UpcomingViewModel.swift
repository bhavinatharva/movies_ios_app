//
//  HomeViewModel.swift
//  MoviesApp
//
//  Created by Bhavin Parghi on 11/11/25.
//

import Foundation

@Observable
class UpcomingViewModel {
    private(set) var upcomingStatus = ApiFetchStatus.notstarted
    
    private let apiService = ApiServices()
    var upcomingMovies: [TrendingModel] = []
    
    
    func getUpcomingsMovies() async {
        upcomingStatus=ApiFetchStatus.loading
        
        if upcomingMovies.isEmpty {
            do{
                async let tMovies =  apiService.fetchTrendings(for: "movie", by: "upcoming")
                
                upcomingMovies = try await tMovies
                upcomingStatus = ApiFetchStatus.success
            }
            catch {
                upcomingStatus=ApiFetchStatus.error(underlyingError: error)
            }
        }else {
            upcomingStatus = ApiFetchStatus.success
        }
    }
    
}
