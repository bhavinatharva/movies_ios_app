import Foundation

let adultKeywords = [
    "adult", "adults", "xxx", "porn", "18+", "18 plus", "onlyfans", "playboy",
    "brazzers", "vixen", "naughty", "erotic", "nsfw"
]

let pattern = "(?i)" + adultKeywords.map { NSRegularExpression.escapedPattern(for: $0) }.joined(separator: "|")
let regex = try! NSRegularExpression(pattern: pattern, options: [])

func isAdultRegex(_ text: String) -> Bool {
    let range = NSRange(location: 0, length: text.utf16.count)
    return regex.firstMatch(in: text, options: [], range: range) != nil
}

func isAdultContains(_ text: String) -> Bool {
    let lower = text.lowercased()
    for kw in adultKeywords {
        if lower.contains(kw) { return true }
    }
    return false
}

let testData = (0..<100_000).map { "VOD Channel \($0) with some normal text" }

let start = Date()
var adultCount = 0
for text in testData {
    if isAdultRegex(text) { adultCount += 1 }
}
let time = Date().timeIntervalSince(start)

let start2 = Date()
var adultCount2 = 0
for text in testData {
    if isAdultContains(text) { adultCount2 += 1 }
}
let time2 = Date().timeIntervalSince(start2)

print("Regex: \(time) sec")
print("Contains: \(time2) sec")
