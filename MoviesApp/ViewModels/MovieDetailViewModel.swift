//
//  MovieDetailViewModel.swift
//  MoviesApp
//
//  Created by Antigravity on 13/05/26.
//

import Foundation
import Observation

@Observable
class MovieDetailViewModel {
    private(set) var status = ApiFetchStatus.notstarted
    private let apiService = ApiServices()
    
    var movieDetail: MovieDetailModel?
    
    func getMovieDetail(id: Int) async {
        status = .loading
        do {
            let detail = try await apiService.fetchMovieDetail(id: id)
            self.movieDetail = detail
            self.status = .success
        } catch {
            self.status = .error(underlyingError: error)
            print("Error fetching movie detail: \(error)")
        }
    }
}
