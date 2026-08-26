import Foundation

struct AdultContentDetector {
    private static let adultKeywords = [
        "adult", "adults", "xxx", "porn", "18\\+", "18 plus", "onlyfans", "playboy",
        "brazzers", "vixen", "naughty", "erotic", "nsfw"
    ]
    
    private static let regex: NSRegularExpression = {
        let pattern = "(?i)" + adultKeywords.joined(separator: "|")
        return try! NSRegularExpression(pattern: pattern, options: [])
    }()
    
    static func isAdult(category: String?, name: String?) -> Bool {
        if let cat = category, regex.firstMatch(in: cat, options: [], range: NSRange(location: 0, length: cat.utf16.count)) != nil {
            return true
        }
        if let nm = name, regex.firstMatch(in: nm, options: [], range: NSRange(location: 0, length: nm.utf16.count)) != nil {
            return true
        }
        return false
    }
}

let testData = (0..<100_000).map { "VOD Channel \($0) with some normal text" }

let start = Date()
var adultCount = 0
for text in testData {
    if AdultContentDetector.isAdult(category: "Movies", name: text) { adultCount += 1 }
}
let time = Date().timeIntervalSince(start)

print("Regex Time: \(time) sec")
