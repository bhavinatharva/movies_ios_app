//
//  URL+Extensions.swift
//

import Foundation

// Helper extension to parse query parameters from the URL
extension URL {
    var queryParameters: [String: String] {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: true),
              let queryItems = components.queryItems else {
            return [:]
        }
        return queryItems.reduce(into: [:]) { result, item in
            result[item.name.lowercased()] = item.value
        }
    }
}
