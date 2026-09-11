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

    // MARK: - TMDB Credits (cast images for detail screens)

    /// Fetches the TMDB credits for a movie or TV series and returns up to `limit` cast members.
    /// - Parameters:
    ///   - tmdbId: The numeric TMDB id as a String (sourced from XtreamVODInfo.tmdbId).
    ///   - mediaType: Pass `.movie` for movies, `.tvSeries` for series.
    ///   - limit: Maximum number of cast members to return (default 20).
    /// - Returns: Array of `TMDBCastMember`. Always returns `[]` on any failure so IPTV content is unaffected.
    func fetchTMDBCast(tmdbId: String, mediaType: MediaType, limit: Int = 20) async -> [TMDBCastMember] {
        guard let token = apiToken, !token.isEmpty,
              let baseUrlString = baseUrl,
              let idInt = Int(tmdbId) else {
            return []
        }

        let mediaPath = mediaType == .tvSeries ? "tv" : "movie"
        // TV series uses aggregate_credits which includes character names across seasons
        let creditsPath = mediaType == .tvSeries ? "aggregate_credits" : "credits"
        let urlString = "\(baseUrlString)3/\(mediaPath)/\(idInt)/\(creditsPath)"

        guard let url = URL(string: urlString) else { return [] }

        do {
            var request = URLRequest(url: url)
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.timeoutInterval = 10

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return []
            }

            let decoder = JSONDecoder()
            // TV aggregate_credits wraps character names inside a roles array;
            // map it to the same flat TMDBCastMember shape.
            if mediaType == .tvSeries {
                let tvCredits = try decoder.decode(TMDBAggregateCreditsResponse.self, from: data)
                return Array(tvCredits.cast
                    .map { TMDBCastMember(id: $0.id, name: $0.name, character: $0.roles?.first?.character ?? "", profilePath: $0.profilePath) }
                    .prefix(limit))
            } else {
                let credits = try decoder.decode(TMDBCreditsResponse.self, from: data)
                return Array(credits.cast.prefix(limit))
            }
        } catch {
            #if DEBUG
            print("⚠️ [ApiServices] TMDB cast fetch failed for \(mediaPath)/\(idInt): \(error)")
            #endif
            return []
        }
    }
}

// MARK: - TV Aggregate Credits helper types (internal, only used by fetchTMDBCast)

private struct TMDBAggregateCreditsResponse: Decodable {
    let cast: [TMDBAggregateActor]
}

private struct TMDBAggregateActor: Decodable {
    let id: Int
    let name: String
    let profilePath: String?
    let roles: [TMDBRole]?

    enum CodingKeys: String, CodingKey {
        case id, name, roles
        case profilePath = "profile_path"
    }
}

private struct TMDBRole: Decodable {
    let character: String
}
