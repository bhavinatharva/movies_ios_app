//
//  M3UParser.swift
//  MoviesApp
//
//  Created by Antigravity on 14/05/26.
//

import Foundation

class M3UParser {
    static func parse(_ content: String) -> [IPTVChannel] {
        var channels: [IPTVChannel] = []
        let lines = content.components(separatedBy: .newlines)
        
        var currentInfo: [String: String] = [:]
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmedLine.isEmpty { continue }
            
            if trimmedLine.hasPrefix("#EXTINF:") {
                currentInfo = parseExtInf(trimmedLine)
            } else if trimmedLine.hasPrefix("http") {
                if let url = URL(string: trimmedLine) {
                    let name = currentInfo["name"] ?? "Unknown Channel"
                    let logo = currentInfo["logo"].flatMap { URL(string: $0) }
                    let category = currentInfo["group"]
                    let epg = currentInfo["epg-id"]
                    
                    let channel = IPTVChannel(
                        name: name,
                        streamUrl: url,
                        logoUrl: logo,
                        category: category,
                        epgId: epg
                    )
                    channels.append(channel)
                }
                currentInfo = [:]
            }
        }
        
        return channels
    }
    
    private static func parseExtInf(_ line: String) -> [String: String] {
        var info: [String: String] = [:]
        
        // Extract attributes
        let attributes = ["tvg-logo", "group-title", "tvg-id", "tvg-name"]
        for attr in attributes {
            if let value = line.extractValue(for: attr) {
                let key = attr.replacingOccurrences(of: "tvg-", with: "")
                              .replacingOccurrences(of: "group-title", with: "group")
                info[key] = value
            }
        }
        
        // Extract channel name (everything after the last comma)
        if let lastComma = line.lastIndex(of: ",") {
            let name = String(line[line.index(after: lastComma)...]).trimmingCharacters(in: .whitespacesAndNewlines)
            info["name"] = name
        }
        
        return info
    }
}

extension String {
    func extractValue(for attribute: String) -> String? {
        let pattern = "\(attribute)=\"([^\"]*)\""
        if let regex = try? NSRegularExpression(pattern: pattern, options: []),
           let match = regex.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.count)) {
            let range = match.range(at: 1)
            if let swiftRange = Range(range, in: self) {
                return String(self[swiftRange])
            }
        }
        return nil
    }
}
