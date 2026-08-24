//
//  CastMember.swift

//

import Foundation

struct CastMember: Identifiable, Hashable {
    var id: String { name }
    let name: String
    let role: String
    let imageUrl: URL?
}

extension String {
    func parseCastMembers(role: String = "Actor") -> [CastMember] {
        // Match a full HTTP(S) URL or a TMDB-style relative image path
        let pattern = "(https?://[^\\s]+|/[\\w\\-/]+\\.(?:jpg|png|jpeg|webp))"
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        
        // Ensure commas in paths/urls don't break the split
        let components = self.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        
        return components.map { comp in
            let nsString = comp as NSString
            if let match = regex?.firstMatch(in: comp, options: [], range: NSRange(location: 0, length: nsString.length)),
               let matchRange = Range(match.range(at: 1), in: comp) {
                
                let urlString = String(comp[matchRange])
                
                // Clean the name by removing the URL, brackets, quotes
                var name = comp.replacingOccurrences(of: urlString, with: "").trimmingCharacters(in: .whitespaces)
                name = name.trimmingCharacters(in: CharacterSet(charactersIn: "()[]{}<>'\"")).trimmingCharacters(in: .whitespaces)
                
                let finalUrlStr = urlString.hasPrefix("/") ? Constants.ImageConstants.posterPathStart + urlString : urlString
                return CastMember(name: name.isEmpty ? "Unknown" : name, role: role, imageUrl: URL(string: finalUrlStr))
            }
            
            return CastMember(name: comp, role: role, imageUrl: nil)
        }
    }
}
