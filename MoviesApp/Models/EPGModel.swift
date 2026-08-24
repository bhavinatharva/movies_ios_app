//
//  EPGModel.swift

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
    
    // Parse XMLTV format in background
    func parseXMLTV(data: Data) async throws -> [EPGProgram] {
        return try await Task.detached(priority: .userInitiated) {
            let parser = XMLTVParser()
            return parser.parse(data: data)
        }.value
    }
}
