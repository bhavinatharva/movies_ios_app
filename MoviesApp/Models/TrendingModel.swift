//
//  TitleModels.swift
//  MoviesApp
//
//  Created by Bhavin Parghi on 11/11/25.
//

import Foundation

struct APIObejct : Decodable {
    var results : [TrendingModel] = []
}

struct TrendingModel : Decodable, Identifiable {
    var id :Int?
    var title : String?
    var name : String?
    var overview : String?
    var posterPath : String?
    
    static var previeTitles = [
        TrendingModel(id: 934433, title: "Scream VI", name: "Scream VI", overview: "Following the latest Ghostface killings, the four survivors leave Woodsboro behind and start a fresh chapter.", posterPath: Constants.ImageConstants.image1),
        TrendingModel(id: 868759, title: "Ghosted", name: "Ghosted", overview: "Salt-of-the-earth Cole falls head over heels for enigmatic Sadie — but then makes the shocking discovery that she’s a",posterPath: Constants.ImageConstants.image2)
    ]
}
