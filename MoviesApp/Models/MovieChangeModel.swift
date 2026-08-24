//
//  MovieChangeModel.swift

//
//  Created by Antigravity on 13/05/26.
//

import Foundation

struct MovieChangeResponse: Decodable {
    let results: [MovieChange]
    let page: Int
    let totalPages: Int
    let totalResults: Int
    
    enum CodingKeys: String, CodingKey {
        case results
        case page
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}

struct MovieChange: Decodable, Identifiable, Hashable {
    let id: Int
    let adult: Bool?
    
    // Conforming to Hashable and Identifiable for SwiftUI List/ForEach
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: MovieChange, rhs: MovieChange) -> Bool {
        lhs.id == rhs.id
    }
}
