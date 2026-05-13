//
//  MovieDetailModel.swift
//  MoviesApp
//
//  Created by Antigravity on 13/05/26.
//

import Foundation

struct MovieDetailModel: Decodable {
    let id: Int
    let title: String?
    let originalTitle: String?
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let runtime: Int?
    let voteAverage: Double?
    let voteCount: Int?
    let status: String?
    let tagline: String?
    let genres: [Genre]?
    let adult: Bool?
    let popularity: Double?
    
    struct Genre: Decodable, Identifiable {
        let id: Int
        let name: String
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, overview, status, tagline, genres, adult, popularity, runtime
        case originalTitle = "original_title"
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate = "release_date"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
    }
}
