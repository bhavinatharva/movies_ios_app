//
//  SearchViewModel.swift
//  MoviesApp
//
//  Created by Bhavin Parghi on 11/11/25.
//

import Foundation

@Observable
class SearchViewModel {
    private(set) var searchingStatus = ApiFetchStatus.notstarted
    private(set) var errorMessage : String?
    
    private let apiService = ApiServices()
    var searchingMovies: [TrendingModel] = []
    
    
    func getSearchMovies(for type:String,searchPhase : String) async {
        
        
            do{
                if searchPhase.isEmpty {
                    searchingMovies = try await apiService.fetchTrendings(for: type, by: "trending")
                }else {
                    searchingMovies = try await apiService.fetchTrendings(for:type, by: "search",searchBy: searchPhase)
                }

            }
            catch {
                errorMessage = error.localizedDescription
            }
        
    }
    
}
