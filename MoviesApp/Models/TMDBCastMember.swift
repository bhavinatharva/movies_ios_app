//
//  TMDBCastMember.swift
//

import Foundation

/// A single cast member returned by the TMDB credits endpoint.
/// Kept lightweight — only the fields needed for the cast row UI.
struct TMDBCastMember: Identifiable, Hashable, Decodable {
    let id: Int
    let name: String
    let character: String
    /// Relative TMDB path e.g. "/abc123.jpg"  — resolved to full URL via Constants.ImageConstants.posterPathStart
    let profilePath: String?

    /// Full HTTPS URL built from posterPathStart, or nil when no image is available.
    var profileImageURL: URL? {
        guard let path = profilePath, !path.isEmpty else { return nil }
        return URL(string: Constants.ImageConstants.posterPathStart + path)
    }

    enum CodingKeys: String, CodingKey {
        case id, name, character
        case profilePath = "profile_path"
    }
}

/// Wraps the `/credits` or `/aggregate_credits` TMDB response.
struct TMDBCreditsResponse: Decodable {
    let cast: [TMDBCastMember]
}
