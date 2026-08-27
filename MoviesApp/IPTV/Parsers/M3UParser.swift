//
//  M3UParser.swift

//
//  Created by Antigravity on 14/05/26.
//

import Foundation

class M3UParser: IPTVPlaylistParser {
    // Compiled once; reused for every #EXTINF: line — avoids 5000+ compilations per import.
    private static let extinfRegex: NSRegularExpression? = try? NSRegularExpression(
        pattern: "([a-zA-Z0-9\\-]+)=[\"']([^\"']*)[\"']",
        options: []
    )
    static func parseStream(from url: URL, onProgress: ((Double?) -> Void)? = nil) async throws -> AsyncThrowingStream<IPTVChannel, Error> {
        return AsyncThrowingStream(IPTVChannel.self) { continuation in
            let task = Task(priority: .userInitiated) {
                do {
                    var linesSinceLastProgress = 0
                    var lastReportedProgress: Double = -1
                    var currentInfo: [String: String] = [:]
                    var bytesRead: Int64 = 0
                    
                    if url.scheme?.lowercased() == "file" {
                        var content = ""
                        do {
                            content = try String(contentsOf: url, encoding: .utf8)
                        } catch {
                            content = try String(contentsOf: url, encoding: .isoLatin1)
                        }
                        let lines = content.components(separatedBy: .newlines)
                        let expectedLength = lines.count
                        
                        for (index, line) in lines.enumerated() {
                            if Task.isCancelled {
                                continuation.finish(throwing: CancellationError())
                                return
                            }
                            
                            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                            linesSinceLastProgress += 1
                            if linesSinceLastProgress >= 50 {
                                linesSinceLastProgress = 0
                                let progress = min(1.0, Double(index) / Double(expectedLength))
                                if progress - lastReportedProgress >= 0.01 || progress >= 1.0 {
                                    lastReportedProgress = progress
                                    Task { @MainActor in onProgress?(progress) }
                                }
                            }
                            
                            if trimmedLine.isEmpty { continue }
                            
                            if trimmedLine.hasPrefix("#EXTINF:") {
                                currentInfo = parseExtInf(trimmedLine)
                            } else if !trimmedLine.hasPrefix("#") {
                                if let streamUrl = URL(string: trimmedLine) ?? URL(string: trimmedLine.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") {
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
                        return
                    }
                    
                    let session = await IPTVRequestManager.shared.getStreamingSession(for: .m3u)
                    let (localUrl, response) = try await session.download(from: url)
                    defer { try? FileManager.default.removeItem(at: localUrl) }
                    
                    if let httpResponse = response as? HTTPURLResponse {
                        if !(200...299).contains(httpResponse.statusCode) {
                            continuation.finish(throwing: URLError(.badServerResponse))
                            return
                        }
                    } else if url.scheme?.lowercased() != "file" {
                        continuation.finish(throwing: URLError(.badServerResponse))
                        return
                    }
                    
                    var content = ""
                    do {
                        content = try String(contentsOf: localUrl, encoding: .utf8)
                    } catch {
                        content = try String(contentsOf: localUrl, encoding: .isoLatin1)
                    }
                    let lines = content.components(separatedBy: .newlines)
                    let expectedLength = lines.count
                    
                    for (index, line) in lines.enumerated() {
                        if Task.isCancelled {
                            continuation.finish(throwing: CancellationError())
                            return
                        }
                        
                        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        linesSinceLastProgress += 1
                        if linesSinceLastProgress >= 50 {
                            linesSinceLastProgress = 0
                            let progress = min(1.0, Double(index) / Double(expectedLength))
                            if progress - lastReportedProgress >= 0.01 || progress >= 1.0 {
                                lastReportedProgress = progress
                                Task { @MainActor in onProgress?(progress) }
                            }
                        }
                        
                        if trimmedLine.isEmpty { continue }
                        
                        if trimmedLine.hasPrefix("#EXTINF:") {
                            currentInfo = parseExtInf(trimmedLine)
                        } else if !trimmedLine.hasPrefix("#") {
                            if let streamUrl = URL(string: trimmedLine) ?? URL(string: trimmedLine.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") {
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
                if let url = URL(string: trimmedLine) ?? URL(string: trimmedLine.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") {
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
        
        // Use the pre-compiled regex (compiled once at class load, not per call)
        if let regex = extinfRegex {
            let matches = regex.matches(in: line, options: [], range: NSRange(location: 0, length: line.utf16.count))
            for match in matches {
                if let keyRange = Range(match.range(at: 1), in: line),
                   let valRange = Range(match.range(at: 2), in: line) {
                    let key = String(line[keyRange])
                    let val = String(line[valRange])
                    
                    let normalizedKey = key.replacingOccurrences(of: "tvg-", with: "")
                                           .replacingOccurrences(of: "group-title", with: "group")
                    info[normalizedKey] = val
                }
            }
        }
        
        // Find the channel name which comes after the first unquoted comma
        var commaIndex: String.Index? = nil
        var inQuotes = false
        var inSingleQuotes = false
        
        for idx in line.indices {
            let char = line[idx]
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "'" {
                inSingleQuotes.toggle()
            } else if char == "," && !inQuotes && !inSingleQuotes {
                commaIndex = idx
                break
            }
        }
        
        if let commaIndex = commaIndex {
            let name = String(line[line.index(after: commaIndex)...]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !name.isEmpty {
                // If it starts with a hyphen (some providers do this), trim it
                if name.hasPrefix("- ") {
                    info["name"] = String(name.dropFirst(2))
                } else {
                    info["name"] = name
                }
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
