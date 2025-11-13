//
//  ApiServices.swift
//  MoviesApp
//
//  Created by Bhavin Parghi on 11/11/25.
//

import Foundation

struct ApiServices {
    let baseUrl = ApiConfig.shared?.baseUrl
    let apiKey = ApiConfig.shared?.apiKey
    let apiToken = ApiConfig.shared?.apiToken
    
    func buildURL(media:String,type:String,searchPhase :String? = nil) throws -> URL?{
        guard let url = baseUrl else {
            throw NetworkError.missingConfig(underlyingError: NSError(domain: "ApiServices", code: -1, userInfo: [NSLocalizedDescriptionKey: "baseUrl not found"]))
        }
        
        var path:String
        if type == "trending" {
            path = "3/\(type)/\(media)/day"
        }else if type == "top_rated" || type == "upcoming" {
            path = "3/\(media)/\(type)"
        }else if type == "search" {
            path = "3/search/\(media)"
        }else {
            throw NetworkError.urlBuildFailed
        }
        var urlQueryParams:[URLQueryItem] = []
        if let searchPhase {
            urlQueryParams.append(URLQueryItem(name: "query", value: searchPhase))
        }
        guard let builedURL = URL(string: url)?
            .appending(path :path)
            .appending(queryItems: urlQueryParams)
        else {
            throw NetworkError.urlBuildFailed
        }
        return builedURL
    }
    
    func fetchTrendings(for media:String,by type:String,searchBy searchPhase :String? = nil) async throws -> [TrendingModel] {
        
        guard let token = apiToken else {
            throw NetworkError.missingConfig(underlyingError: NSError(domain: "ApiServices", code: -1, userInfo: [NSLocalizedDescriptionKey: "apiToken not found"]))
        }
        
        
        let trendingsUrl = try buildURL(media: media, type: type,searchPhase: searchPhase)
        guard let trendingsUrl = trendingsUrl else {
            throw NetworkError.urlBuildFailed
        }
        print(trendingsUrl)
        var urlRequest = URLRequest(url: trendingsUrl)
        urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-type")
        urlRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data,urlResponse) = try await URLSession.shared.data(for: urlRequest)
        
        guard let response = urlResponse as? HTTPURLResponse, response .statusCode == 200 else {
            throw NetworkError.badURLResponse(
                underlyingError: NSError(
                    domain: "ApiServices",
                    code: (urlResponse as? HTTPURLResponse)?.statusCode ?? -1 ,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response"]))
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        var trendings =  try decoder.decode(APIObejct.self, from: data).results
        Constants.ImageConstants.addPosterPth(to: &trendings)
        return trendings
    }
}
