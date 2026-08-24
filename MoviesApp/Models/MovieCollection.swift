//
//  MovieCollection.swift

//
//  Created by Antigravity on 21/05/26.
//

import Foundation

struct MovieCollection: Identifiable, Hashable {
    let id: String
    let title: String
    let movies: [UnifiedMediaItem]
    
    init(id: String, title: String, movies: [UnifiedMediaItem]) {
        self.id = id
        self.title = title
        
        // Deduplicate movies by normalized title to prevent duplicate entries in grids
        var seen = Set<String>()
        var uniqueMovies: [UnifiedMediaItem] = []
        for movie in movies {
            let key = movie.title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            if !seen.contains(key) {
                seen.insert(key)
                uniqueMovies.append(movie)
            }
        }
        self.movies = uniqueMovies
    }
    
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
        return lhs.id == rhs.id
    }
    
    var subCollections: [(name: String, movies: [UnifiedMediaItem])] {
        var groups: [String: [UnifiedMediaItem]] = [:]
        
        for movie in movies {
            let title = movie.title
            var groupName = "Other"
            
            var cleanedTitle = title
            let prefixesToRemove = ["The ", "A ", "An "]
            for prefix in prefixesToRemove {
                if cleanedTitle.lowercased().hasPrefix(prefix.lowercased()) {
                    cleanedTitle = String(cleanedTitle.dropFirst(prefix.count))
                    break
                }
            }
            
            if let colonRange = cleanedTitle.range(of: ":") {
                groupName = String(cleanedTitle[..<colonRange.lowerBound]).trimmingCharacters(in: .whitespaces)
            } else if let dashRange = cleanedTitle.range(of: " - ") {
                groupName = String(cleanedTitle[..<dashRange.lowerBound]).trimmingCharacters(in: .whitespaces)
            } else {
                if let firstWord = cleanedTitle.components(separatedBy: " ").first, firstWord.count > 2 {
                    groupName = firstWord
                } else {
                    groupName = cleanedTitle
                }
            }
            
            groups[groupName, default: []].append(movie)
        }
        
        var finalGroups: [(name: String, movies: [UnifiedMediaItem])] = []
        var others: [UnifiedMediaItem] = []
        
        for (name, items) in groups {
            if items.count > 1 {
                finalGroups.append((name: "\(name) Movies", movies: items.sorted { ($0.releaseDate ?? "") < ($1.releaseDate ?? "") }))
            } else {
                others.append(contentsOf: items)
            }
        }
        
        finalGroups.sort { $0.movies.count > $1.movies.count }
        
        if !others.isEmpty {
            if finalGroups.isEmpty {
                return [("Movies in Collection", movies)]
            } else {
                others.sort { ($0.releaseDate ?? "") < ($1.releaseDate ?? "") }
                // Only add 'Other Movies' if we actually formed subgroups
                finalGroups.append((name: "Other Movies", movies: others))
            }
        }
        
        return finalGroups
    }
}
