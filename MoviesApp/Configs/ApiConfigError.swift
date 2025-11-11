//
//  ApiConfigError.swift
//  MoviesApp
//
//  Created by Bhavin Parghi on 11/11/25.
//

import Foundation

enum ApiConfigError: LocalizedError,Error {
    case fileNotFound
    case dataLoadingFailed(underlyingError: Error)
    case decodingFailed (underlyingError: Error)
    
    var errorDescription:String? {
        switch self {
        case .fileNotFound:
            return "ApiConfig.json file is not found"
        case .dataLoadingFailed(underlyingError:let error):
            return "Failed to load data from ApiConfig.json file: \(error.localizedDescription)"
        case .decodingFailed(underlyingError: let error):
            return "Failed to decode ApiConfig.json file \(error.localizedDescription)"
        }
    }
}
