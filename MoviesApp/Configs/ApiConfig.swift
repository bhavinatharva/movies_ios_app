//
//  ApiConfig.swift
//  MoviesApp
//
//  Created by Bhavin Parghi on 11/11/25.
//

import Foundation

struct ApiConfig: Decodable {
    var baseUrl : String?
    var apiKey : String?
    var apiToken : String?
    
    static let shared : ApiConfig? = {
        do {
            return try loadConfig()
        }catch {
            print("Failed to load Api Config \(error.localizedDescription)")
            return nil
        }
    } ()
    
    private static func loadConfig () throws -> ApiConfig {
        guard let url = Bundle.main.url(forResource: "ApiConfig", withExtension: "json") else {
            throw ApiConfigError.fileNotFound
        }
        do {
            let data = try Data (contentsOf: url)
            return try JSONDecoder().decode(ApiConfig.self, from: data)
            
        }catch let error as DecodingError {
            throw ApiConfigError.decodingFailed(underlyingError: error)
        }catch {
            throw ApiConfigError.dataLoadingFailed(underlyingError: error)
        }
    }
}
