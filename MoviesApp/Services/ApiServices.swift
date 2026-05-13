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
        }else if type == "top_rated" || type == "upcoming" || type == "popular"  || type == "now_playing"{
            path = "3/\(media)/\(type)"
        }else if type == "search" {
            path = "3/search/\(media)"
        }else if type == "changes" {
            path = "3/\(media)/\(type)"
        }else {
            throw NetworkError.urlBuildFailed(underlyingError: NSError(domain: "ApiServices", code: -1,userInfo: [NSLocalizedDescriptionKey:"type not matching"]))
        }
        var urlQueryParams:[URLQueryItem] = []
        if let searchPhase {
            urlQueryParams.append(URLQueryItem(name: "query", value: searchPhase))
        }
        guard let builedURL = URL(string: url)?
            .appending(path :path)
            .appending(queryItems: urlQueryParams)
        else {
            throw NetworkError.urlBuildFailed(underlyingError: NSError(domain: "ApiServices", code: -1,userInfo: [NSLocalizedDescriptionKey:"Failed to Build URL"]))
        }
        return builedURL
    }
    
    func buildPersonURL(searchPhase :String? = nil) throws -> URL?{
        guard let url = baseUrl else {
            throw NetworkError.missingConfig(underlyingError: NSError(domain: "ApiServices", code: -1, userInfo: [NSLocalizedDescriptionKey: "baseUrl not found"]))
        }
        
        var path=""
        if searchPhase != nil {
            path = "3/search/person"
        }else {
            path = "3/person/popular"
        }
        var urlQueryParams:[URLQueryItem] = []
        if let searchPhase {
            urlQueryParams.append(URLQueryItem(name: "query", value: searchPhase))
        }
        guard var builedURL = URL(string: url)
        else {
            throw NetworkError.urlBuildFailed(underlyingError: NSError(domain: "ApiServices", code: -1,userInfo: [NSLocalizedDescriptionKey:"Failed to Build URL"]))
        }
        
        builedURL = builedURL.appending(path :path)
        if !urlQueryParams.isEmpty {
            builedURL =     builedURL.appending(queryItems: urlQueryParams)
        }
        return builedURL
    }
    
    func fetchTrendings(for media:String,by type:String,searchBy searchPhase :String? = nil) async throws -> [TrendingModel] {
        
        guard let token = apiToken else {
            throw NetworkError.missingConfig(underlyingError: NSError(domain: "ApiServices", code: -1, userInfo: [NSLocalizedDescriptionKey: "apiToken not found"]))
        }
        
        
        let trendingsUrl = try buildURL(media: media, type: type,searchPhase: searchPhase)
        guard let trendingsUrl = trendingsUrl else {
            throw NetworkError.urlBuildFailed(underlyingError: NSError(domain: "ApiServices", code: -1,userInfo: [NSLocalizedDescriptionKey:"Invalid Build URL"]))
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
    
    func fetchRecentMovieChanges() async throws -> [MovieChange] {
        guard let token = apiToken else {
            throw NetworkError.missingConfig(underlyingError: NSError(domain: "ApiServices", code: -1, userInfo: [NSLocalizedDescriptionKey: "apiToken not found"]))
        }
        
        let url = try buildURL(media: "movie", type: "changes")
        guard let url = url else {
            throw NetworkError.urlBuildFailed(underlyingError: NSError(domain: "ApiServices", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Build URL"]))
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-type")
        urlRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, urlResponse) = try await URLSession.shared.data(for: urlRequest)
        
        guard let response = urlResponse as? HTTPURLResponse, response.statusCode == 200 else {
            throw NetworkError.badURLResponse(
                underlyingError: NSError(
                    domain: "ApiServices",
                    code: (urlResponse as? HTTPURLResponse)?.statusCode ?? -1,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response"]))
        }
        
        let decoder = JSONDecoder()
        // No snake case conversion needed for the results array itself, 
        // but MovieChangeResponse has total_pages etc.
        let changeResponse = try decoder.decode(MovieChangeResponse.self, from: data)
        return changeResponse.results
    }
    
    func fetchMovieDetail(id: Int) async throws -> MovieDetailModel {
        guard let token = apiToken else {
            throw NetworkError.missingConfig(underlyingError: NSError(domain: "ApiServices", code: -1, userInfo: [NSLocalizedDescriptionKey: "apiToken not found"]))
        }
        
        guard let urlString = baseUrl, var url = URL(string: urlString) else {
            throw NetworkError.urlBuildFailed(underlyingError: NSError(domain: "ApiServices", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Base URL"]))
        }
        
        url = url.appending(path: "3/movie/\(id)")
        
        var urlRequest = URLRequest(url: url)
        urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-type")
        urlRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, urlResponse) = try await URLSession.shared.data(for: urlRequest)
        
        guard let response = urlResponse as? HTTPURLResponse, response.statusCode == 200 else {
            throw NetworkError.badURLResponse(
                underlyingError: NSError(
                    domain: "ApiServices",
                    code: (urlResponse as? HTTPURLResponse)?.statusCode ?? -1,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response"]))
        }
        
        let decoder = JSONDecoder()
        // We use our model's custom coding keys
        let movieDetail = try decoder.decode(MovieDetailModel.self, from: data)
        return movieDetail
    }
    
    func fetchActors(searchBy searchPhase :String? = nil) async throws -> [ActorModel] {
        
        guard let token = apiToken else {
            throw NetworkError.missingConfig(underlyingError: NSError(domain: "ApiServices", code: -1, userInfo: [NSLocalizedDescriptionKey: "apiToken not found"]))
        }
        
        
        let trendingsUrl = try buildPersonURL(searchPhase: searchPhase)
        guard let trendingsUrl = trendingsUrl else {
            throw NetworkError.urlBuildFailed(underlyingError: NSError(domain: "ApiServices", code: -1,userInfo: [NSLocalizedDescriptionKey:"Invalid Build URL"]))
        }
        print("trendingsUrl",trendingsUrl)
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
//        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        
        
        var actorData = try decoder.decode(ActorAPIObejct.self, from: data)
        Constants.ImageConstants.addProfilePath(to: &actorData.results)
        
        return actorData.results
    }
}
