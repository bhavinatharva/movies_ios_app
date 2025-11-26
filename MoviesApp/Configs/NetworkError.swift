//
//  NetworkError.swift
//  MoviesApp
//
//  Created by Bhavin Parghi on 11/11/25.
//

import Foundation

enum NetworkError: Error,LocalizedError {
    case badURLResponse(underlyingError:Error)
    case missingConfig(underlyingError:Error)
    case urlBuildFailed(underlyingError:Error)
    
    var errorDescription:String? {
        switch self {
        case .badURLResponse(underlyingError: let error):
            return "Failed to parse URl Response : \(error.localizedDescription)"
        case .missingConfig(underlyingError: let error):
            return "Missing ApiConfig.json file. \(error.localizedDescription)"
        case .urlBuildFailed(underlyingError: let error):
            return "Failed to Build URL. \(error.localizedDescription)"
        }
    
    }
}
