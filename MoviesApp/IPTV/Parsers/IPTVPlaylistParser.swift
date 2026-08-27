//
//  IPTVPlaylistParser.swift
//

import Foundation

protocol IPTVPlaylistParser {
    static func parseStream(from url: URL, onProgress: ((Double?) -> Void)?) async throws -> AsyncThrowingStream<IPTVChannel, Error>
    static func parse(_ content: String) -> [IPTVChannel]
}
