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

struct M3USeriesParser {
    struct ParsedEpisode: Hashable {
        let showTitle: String
        let seasonNumber: Int
        let episodeNumber: Int
        let episodeTitle: String
    }
    
    static func parseEpisode(from name: String) -> ParsedEpisode? {
        // Look for patterns like "S01E02", "S1E2", "S01 E02", "Season 1 Episode 2", etc.
        let patterns = [
            "s(\\d{1,2})\\s*e(\\d{1,2})",
            "season\\s*(\\d{1,2})\\s*episode\\s*(\\d{1,2})"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
               let match = regex.firstMatch(in: name, options: [], range: NSRange(location: 0, length: name.count)) {
                
                let rangeS = match.range(at: 1)
                let rangeE = match.range(at: 2)
                
                if let swiftRangeS = Range(rangeS, in: name),
                   let swiftRangeE = Range(rangeE, in: name),
                   let seasonNum = Int(name[swiftRangeS]),
                   let episodeNum = Int(name[swiftRangeE]) {
                    
                    // Split the name to get show title and episode title
                    let fullMatchRange = Range(match.range(at: 0), in: name)!
                    
                    let showTitle = String(name[..<fullMatchRange.lowerBound])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .trimmingCharacters(in: .punctuationCharacters)
                        .trimmingCharacters(in: .symbols)
                    
                    var episodeTitle = String(name[fullMatchRange.upperBound...])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .trimmingCharacters(in: .punctuationCharacters)
                        .trimmingCharacters(in: .symbols)
                    
                    if episodeTitle.isEmpty {
                        episodeTitle = "Episode \(episodeNum)"
                    }
                    
                    return ParsedEpisode(
                        showTitle: showTitle.isEmpty ? "Unknown Series" : showTitle,
                        seasonNumber: seasonNum,
                        episodeNumber: episodeNum,
                        episodeTitle: episodeTitle
                    )
                }
            }
        }
        return nil
    }
}
