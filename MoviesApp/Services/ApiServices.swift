//
//  ApiServices.swift

//
//  Created by Bhavin Parghi on 11/11/25.
//

import Foundation

struct ApiServices {
    let baseUrl = ApiConfig.shared?.baseUrl
    let apiKey = ApiConfig.shared?.apiKey
    let apiToken = ApiConfig.shared?.apiToken
    
    func buildURL(media:String,type:String,searchPhase :String? = nil) throws -> URL? {
        return nil
    }
    
    func buildPersonURL(searchPhase :String? = nil) throws -> URL? {
        return nil
    }
    
    func fetchTrendings(for media:String,by type:String,searchBy searchPhase :String? = nil) async throws -> [TrendingModel] {
        // Return empty trending model list immediately (0 calls to TMDB!)
        return []
    }
    
    func fetchRecentMovieChanges() async throws -> [MovieChange] {
        return []
    }
    
    func fetchMovieDetail(id: Int) async throws -> MovieDetailModel {
        // Return a clean default stub for backward compatibility
        return MovieDetailModel(
            id: id,
            title: "Local Movie",
            originalTitle: "Local Movie",
            overview: "Playback loaded from your IPTV playlist.",
            posterPath: nil,
            backdropPath: nil,
            releaseDate: nil,
            runtime: nil,
            voteAverage: nil,
            voteCount: nil,
            status: nil,
            tagline: nil,
            genres: nil,
            adult: false,
            popularity: nil
        )
    }
    
    func fetchMovieVideos(id: Int) async throws -> [VideoModel] {
        return []
    }
    
    func fetchActors(searchBy searchPhase :String? = nil) async throws -> [ActorModel] {
        return []
    }
}
