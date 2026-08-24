
//
//  TitleModels.swift

//
//  Created by Bhavin Parghi on 11/11/25.
//

import SwiftData

struct ActorAPIObejct : Decodable {
    var results : [ActorModel] = []
}

@Model
class ActorModel : Decodable, Identifiable, Hashable {
    var id :Int?
    var name : String?
    var knownForDepartment : String?
    var profilePath : String?
    var adult : Bool?
    var knownFor: [TrendingModel]?
    
    init(id: Int? = nil, name: String? = nil, knownForDepartment: String? = nil, profilePath: String? = nil,adult:Bool? = false, knownFor: [TrendingModel]? = nil) {
        self.id = id
        self.name = name
        self.knownForDepartment = knownForDepartment
        self.profilePath = profilePath
        self.adult = adult
        self.knownFor = knownFor
    }
    
    enum CodingKeys:String, CodingKey {
        case id
        case name
        case knownForDepartment = "known_for_department"
        case profilePath = "profile_path"
        case adult
        case knownFor = "known_for"
    }
    
    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        knownForDepartment = try container.decodeIfPresent(String.self, forKey: .knownForDepartment)
        profilePath = try container.decodeIfPresent(String.self, forKey: .profilePath)
        adult = try container.decodeIfPresent(Bool.self, forKey: .adult)
        knownFor = try container.decodeIfPresent([TrendingModel].self, forKey: .knownFor)
    }
    
    static var previeTitles = [
        ActorModel(id: 934433,
                      name: "Scream VI",
                   knownForDepartment: "Acting",
                      profilePath: Constants.ImageConstants.image1,
                      adult: false
                     ),
        ActorModel(id: 868759,
                      name: "Ghosted",
                   knownForDepartment: "Acting",
                      profilePath: Constants.ImageConstants.image2,
                      adult: false
                     )
    ]
}
