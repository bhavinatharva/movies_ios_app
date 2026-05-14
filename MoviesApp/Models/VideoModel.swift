//
//  VideoModel.swift
//  MoviesApp
//
//  Created by Antigravity on 14/05/26.
//

import Foundation

struct VideoResponse: Decodable {
    let id: Int
    let results: [VideoModel]
}

struct VideoModel: Decodable, Identifiable {
    let id: String
    let iso_639_1: String?
    let iso_3166_1: String?
    let name: String?
    let key: String?
    let site: String?
    let size: Int?
    let type: String?
    let official: Bool?
    let published_at: String?
}
