//
//  M3UParser.swift
//  MoviesApp
//
//  Created by Antigravity on 14/05/26.
//

import Foundation

class M3UParser {
    static func parseStream(from url: URL) async throws -> AsyncThrowingStream<IPTVChannel, Error> {
        return AsyncThrowingStream(IPTVChannel.self) { continuation in
            let task = Task(priority: .userInitiated) {
                do {
                    let session = await IPTVRequestManager.shared.getStreamingSession(for: .m3u)
                    let (bytes, response) = try await session.bytes(from: url)
                    
                    if let httpResponse = response as? HTTPURLResponse {
                        if !(200...299).contains(httpResponse.statusCode) {
                            continuation.finish(throwing: URLError(.badServerResponse))
                            return
                        }
                    } else if url.scheme?.lowercased() != "file" {
                        continuation.finish(throwing: URLError(.badServerResponse))
                        return
                    }
                    
                    var currentInfo: [String: String] = [:]
                    
                    for try await line in bytes.lines {
                        if Task.isCancelled {
                            continuation.finish(throwing: CancellationError())
                            return
                        }
                        
                        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        #if DEBUG
                        print("📡 [M3UParser] Fetched Line: \(trimmedLine)")
                        #endif
                        
                        if trimmedLine.isEmpty { continue }
                        
                        if trimmedLine.hasPrefix("#EXTINF:") {
                            currentInfo = parseExtInf(trimmedLine)
                        } else if !trimmedLine.hasPrefix("#") {
                            if let streamUrl = URL(string: trimmedLine) {
                                let name = currentInfo["name"] ?? currentInfo["tvg-name"] ?? "Unknown Channel"
                                let logo = currentInfo["logo"].flatMap { URL(string: $0) }
                                let category = currentInfo["group"]
                                let epg = currentInfo["epg-id"] ?? currentInfo["id"]
                                
                                let channel = IPTVChannel(
                                    name: name,
                                    streamUrl: streamUrl,
                                    logoUrl: logo,
                                    category: category,
                                    epgId: epg
                                )
                                continuation.yield(channel)
                            }
                            currentInfo = [:]
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            
            continuation.onTermination = { termination in
                if case .cancelled = termination {
                    task.cancel()
                }
            }
        }
    }

    static func parse(_ content: String) -> [IPTVChannel] {
        var channels: [IPTVChannel] = []
        let lines = content.components(separatedBy: .newlines)
        
        var currentInfo: [String: String] = [:]
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedLine.isEmpty { continue }
            
            if trimmedLine.hasPrefix("#EXTINF:") {
                currentInfo = parseExtInf(trimmedLine)
            } else if !trimmedLine.hasPrefix("#") {
                if let url = URL(string: trimmedLine) {
                    let name = currentInfo["name"] ?? currentInfo["tvg-name"] ?? "Unknown Channel"
                    let logo = currentInfo["logo"].flatMap { URL(string: $0) }
                    let category = currentInfo["group"]
                    let epg = currentInfo["epg-id"] ?? currentInfo["id"]
                    
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
        
        var commaIndex: String.Index? = nil
        var insideQuotes = false
        var insideSingleQuotes = false
        
        for idx in line.indices {
            let char = line[idx]
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "'" {
                insideSingleQuotes.toggle()
            } else if char == "," && !insideQuotes && !insideSingleQuotes {
                commaIndex = idx
                break
            }
        }
        
        let divider = commaIndex ?? line.endIndex
        let attributePart = line[line.startIndex..<divider]
        
        let scanner = Scanner(string: String(attributePart))
        scanner.charactersToBeSkipped = .whitespaces
        
        _ = scanner.scanString("#EXTINF:")
        _ = scanner.scanInt()
        
        while !scanner.isAtEnd {
            guard let key = scanner.scanUpToString("=") else { break }
            _ = scanner.scanString("=")
            
            var value = ""
            if scanner.scanString("\"") != nil {
                if let val = scanner.scanUpToString("\"") {
                    value = val
                }
                _ = scanner.scanString("\"")
            } else if scanner.scanString("'") != nil {
                if let val = scanner.scanUpToString("'") {
                    value = val
                }
                _ = scanner.scanString("'")
            } else {
                if let val = scanner.scanUpToCharacters(from: .whitespaces) {
                    value = val
                }
            }
            
            let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedVal = value.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !trimmedKey.isEmpty {
                let normalizedKey = trimmedKey.replacingOccurrences(of: "tvg-", with: "")
                                              .replacingOccurrences(of: "group-title", with: "group")
                info[normalizedKey] = trimmedVal
            }
        }
        
        if let commaIndex = commaIndex {
            let name = String(line[line.index(after: commaIndex)...]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !name.isEmpty {
                info["name"] = name
            }
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
