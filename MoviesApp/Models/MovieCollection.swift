//
//  MovieCollection.swift
//  MoviesApp
//
//  Created by Antigravity on 21/05/26.
//

import Foundation

struct MovieCollection: Identifiable, Hashable {
    let id: String
    let title: String
    let movies: [UnifiedMediaItem]
    
    var posterPath: String? {
        // Prefer a poster from a movie that has one
        return movies.first(where: { $0.posterPath != nil && !$0.posterPath!.isEmpty })?.posterPath ?? movies.first?.posterPath
    }
    
    var movieCount: Int {
        return movies.count
    }
    
    var yearRange: String? {
        let years = movies.compactMap { item -> Int? in
            guard let releaseDate = item.releaseDate else { return nil }
            // Some release dates are full dates, some are just years
            if releaseDate.count >= 4 {
                return Int(releaseDate.prefix(4))
            }
            return nil
        }.sorted()
        
        guard let first = years.first else { return nil }
        guard let last = years.last, first != last else { return "\(first)" }
        return "\(first)-\(last)"
    }
    
    var genres: [String] {
        var allGenres = Set<String>()
        for movie in movies {
            if let movieGenres = movie.genres {
                for genre in movieGenres {
                    allGenres.insert(genre)
                }
            }
        }
        return Array(allGenres).sorted()
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: MovieCollection, rhs: MovieCollection) -> Bool {
        lhs.id == rhs.id
    }
}
