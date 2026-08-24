//
//  CollectionGroupingService.swift

//
//  Created by Antigravity on 21/05/26.
//

import Foundation

class CollectionGroupingService {
    static let shared = CollectionGroupingService()
    
    private init() {}
    
    // Some hardcoded universes mapping
    private let knownUniverses: [String: String] = [
        "iron man": "Marvel Cinematic Universe Collection",
        "thor": "Marvel Cinematic Universe Collection",
        "captain america": "Marvel Cinematic Universe Collection",
        "avengers": "Marvel Cinematic Universe Collection",
        "black panther": "Marvel Cinematic Universe Collection",
        "guardians of the galaxy": "Marvel Cinematic Universe Collection",
        "ant-man": "Marvel Cinematic Universe Collection",
        "spider-man": "Marvel Cinematic Universe Collection",
        "doctor strange": "Marvel Cinematic Universe Collection",
        "batman": "DC Universe Collection",
        "superman": "DC Universe Collection",
        "wonder woman": "DC Universe Collection",
        "justice league": "DC Universe Collection",
        "aquaman": "DC Universe Collection",
        "harry potter": "Harry Potter Collection",
        "fantastic beasts": "Harry Potter Collection",
        "fast & furious": "Fast & Furious Collection",
        "fast and furious": "Fast & Furious Collection",
        "fast five": "Fast & Furious Collection",
        "f9": "Fast & Furious Collection",
        "mission impossible": "Mission Impossible Collection",
        "mission: impossible": "Mission Impossible Collection",
        "star wars": "Star Wars Collection",
        "john wick": "John Wick Collection",
        "transformers": "Transformers Collection",
        "the lord of the rings": "The Lord of the Rings Collection",
        "the hobbit": "The Lord of the Rings Collection",
        "twilight": "The Twilight Saga Collection",
        "hunger games": "The Hunger Games Collection",
        "the hunger games": "The Hunger Games Collection",
        "toy story": "Toy Story Collection",
        "despicable me": "Despicable Me Collection",
        "minions": "Despicable Me Collection",
        "shrek": "Shrek Collection"
    ]
    
    func groupMovies(_ movies: [UnifiedMediaItem]) -> [MovieCollection] {
        var groups: [String: [UnifiedMediaItem]] = [:]
        
        for movie in movies {
            let normalized = normalizeTitle(movie.title)
            var foundUniverse = false
            
            // Check hardcoded universes
            for (keyword, collectionName) in knownUniverses {
                if normalized.lowercased().contains(keyword) {
                    groups[collectionName, default: []].append(movie)
                    foundUniverse = true
                    break
                }
            }
            
            if !foundUniverse {
                // Determine base title
                let baseTitle = extractBaseTitle(normalized)
                if !baseTitle.isEmpty && baseTitle.count > 3 {
                    // Capitalize first letters for base title
                    groups[baseTitle.capitalized, default: []].append(movie)
                }
            }
        }
        
        var collections: [MovieCollection] = []
        for (title, items) in groups {
            // A collection should have at least 2 movies
            if items.count >= 2 {
                let sortedItems = items.sorted {
                    // Try sorting by year first, otherwise title
                    if let y1 = extractYear(from: $0.releaseDate ?? $0.title),
                       let y2 = extractYear(from: $1.releaseDate ?? $1.title) {
                        return y1 < y2
                    }
                    return $0.title < $1.title
                }
                
                let collectionTitle = title.hasSuffix("Collection") ? title : "\(title) Collection"
                // Prevent duplicate title issues by hashing
                let id = "col_\(title.lowercased().replacingOccurrences(of: " ", with: "_"))"
                collections.append(MovieCollection(id: id, title: collectionTitle, movies: sortedItems))
            }
        }
        
        // Sort by movie count (largest franchises first), then by title
        return collections.sorted { 
            if $0.movieCount == $1.movieCount {
                return $0.title < $1.title
            }
            return $0.movieCount > $1.movieCount
        }
    }
    
    private func normalizeTitle(_ title: String) -> String {
        var clean = title
        
        // Remove resolution tags
        let tagsToRemove = ["1080p", "4k", "720p", "hd", "uhd", "fhd", "hdtv", "webrip", "bluray", "brrip", "dvdrip"]
        for tag in tagsToRemove {
            clean = clean.replacingOccurrences(of: "(?i)\\b\(tag)\\b", with: "", options: .regularExpression)
        }
        
        // Remove year tags like (2023), [2023]
        clean = clean.replacingOccurrences(of: "(\\(|\\[)\\s*(19|20)\\d{2}\\s*(\\)|\\])", with: "", options: .regularExpression)
        
        // Remove other bracketed content
        clean = clean.replacingOccurrences(of: "\\[.*?\\]", with: "", options: .regularExpression)
        
        return clean.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func extractBaseTitle(_ title: String) -> String {
        // Split by common separators to get the base franchise name
        // e.g., "Avengers: Endgame" -> "Avengers"
        // e.g., "Fast & Furious 6" -> "Fast & Furious"
        
        let separators = [":", "-"]
        for separator in separators {
            if let firstPart = title.components(separatedBy: separator).first {
                let trimmed = firstPart.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty && trimmed.count != title.count {
                    return removeTrailingNumbersAndSubtitles(trimmed)
                }
            }
        }
        
        return removeTrailingNumbersAndSubtitles(title)
    }
    
    private func removeTrailingNumbersAndSubtitles(_ title: String) -> String {
        var clean = title
        
        // Remove common sequel indicators like " Part 2", " Vol 3"
        let sequelIndicators = ["part", "vol", "volume", "chapter", "episode"]
        for indicator in sequelIndicators {
            clean = clean.replacingOccurrences(of: "(?i)\\s+\(indicator)\\s+\\d+", with: "", options: .regularExpression)
        }
        
        // Remove roman numerals at the end (I, II, III, IV, etc)
        clean = clean.replacingOccurrences(of: "\\s+(I|II|III|IV|V|VI|VII|VIII|IX|X|XI|XII)$", with: "", options: .regularExpression)
        
        // Remove arabic numerals at the end
        clean = clean.replacingOccurrences(of: "\\s+\\d+$", with: "", options: .regularExpression)
        
        return clean.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func extractYear(from text: String) -> Int? {
        let pattern = "(19|20)\\d{2}"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let range = NSRange(location: 0, length: text.utf16.count)
            if let match = regex.firstMatch(in: text, options: [], range: range) {
                if let swiftRange = Range(match.range, in: text) {
                    return Int(text[swiftRange])
                }
            }
        }
        return nil
    }
}
