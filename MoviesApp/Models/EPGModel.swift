//
//  EPGModel.swift
//  MoviesApp
//
//  Created by Antigravity on 14/05/26.
//

import Foundation

struct EPGProgram: Identifiable, Codable {
    let id = UUID()
    let channelId: String
    let start: Date
    let stop: Date
    let title: String
    let description: String?
}

class EPGService {
    static let shared = EPGService()
    private init() {}
    
    // In a real app, this would parse XMLTV format
    func fetchEPG(url: URL) async throws -> [EPGProgram] {
        // Placeholder for XMLTV parsing logic
        return []
    }
}
