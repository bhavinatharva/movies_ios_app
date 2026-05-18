//
//  ApiFetchStatus.swift
//  MoviesApp
//
//  Created by Bhavin Parghi on 11/11/25.
//

import Foundation

enum ApiFetchStatus: Equatable {
    case notstarted
    case loading
    case success
    case error (underlyingError : Error)
    
    static func == (lhs: ApiFetchStatus, rhs: ApiFetchStatus) -> Bool {
        switch (lhs, rhs) {
        case (.notstarted, .notstarted): return true
        case (.loading, .loading): return true
        case (.success, .success): return true
        case (.error, .error): return true
        default: return false
        }
    }
}
