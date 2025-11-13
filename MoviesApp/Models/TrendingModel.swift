//
//  TitleModels.swift
//  MoviesApp
//
//  Created by Bhavin Parghi on 11/11/25.
//

import SwiftData

struct APIObejct : Decodable {
    var results : [TrendingModel] = []
}

@Model
class TrendingModel : Decodable, Identifiable, Hashable {
    var id :Int?
    var title : String?
    var name : String?
    var overview : String?
    var posterPath : String?
    
    init(id: Int? = nil, title: String? = nil, name: String? = nil, overview: String? = nil, posterPath: String? = nil) {
        self.id = id
        self.title = title
        self.name = name
        self.overview = overview
        self.posterPath = posterPath
    }
    
    enum CodingKeys: CodingKey {
        case id
        case title
        case name
        case overview
        case posterPath
    }
    
    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int.self, forKey: .id)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        overview = try container.decodeIfPresent(String.self, forKey: .overview)
        posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath)
    }
    
    static var previeTitles = [
        TrendingModel(id: 934433, title: "Scream VI", name: "Scream VI", overview: "Following the latest Ghostface killings, the four survivors leave Woodsboro behind and start a fresh chapter.", posterPath: Constants.ImageConstants.image1),
        TrendingModel(id: 868759, title: "Ghosted", name: "Ghosted", overview: "Salt-of-the-earth Cole falls head over heels for enigmatic Sadie — but then makes the shocking discovery that she’s a",posterPath: Constants.ImageConstants.image2)
    ]
}
