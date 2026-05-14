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
    var videos: [VideoModel] = []
    
    var trailerKey: String? {
        videos.first { $0.type == "Trailer" && $0.site == "YouTube" }?.key ?? videos.first?.key
    }
    
    func getMovieDetail(id: Int) async {
        status = .loading
        do {
            async let detailFetch = apiService.fetchMovieDetail(id: id)
            async let videosFetch = apiService.fetchMovieVideos(id: id)
            
            let (detail, videos) = try await (detailFetch, videosFetch)
            
            self.movieDetail = detail
            self.videos = videos
            self.status = .success
        } catch {
            self.status = .error(underlyingError: error)
            print("Error fetching movie detail or videos: \(error)")
        }
    }
}
