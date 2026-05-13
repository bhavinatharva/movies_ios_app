//
//  ApiFetchStatus.swift
//  MoviesApp
//
//  Created by Bhavin Parghi on 11/11/25.
//

import Foundation

enum ApiFetchStatus {
    case notstarted
    case loading
    case success
    case error (underlyingError : Error)
}
