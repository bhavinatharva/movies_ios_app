import Foundation

// Simulate Adult Content Detector
let adultKeywords = [
    "18+", "xxx", "adult", "redlight", "porno", "erot", "nsfw",
    "pink", "hentai", "onlyfans", "brazzers", "playboy", "penthouse",
    "hustler", "mature", "uncensored", "sex"
]

func isAdultStringSlow(_ text: String) -> Bool {
    let lower = text.lowercased()
    let adultKeywords = [
        "18+", "xxx", "adult", "redlight", "porno", "erot", "nsfw",
        "pink", "hentai", "onlyfans", "brazzers", "playboy", "penthouse",
        "hustler", "mature", "uncensored", "sex"
    ]
    return adultKeywords.contains(where: { lower.contains($0) })
}

func isAdultStringFast(_ text: String) -> Bool {
    let lower = text.lowercased()
    return adultKeywords.contains(where: { lower.contains($0) })
}

let testData = (0..<100_000).map { "VOD Channel \($0) with some normal text" }

let startSlow = Date()
var adultCount = 0
for text in testData {
    if isAdultStringSlow(text) { adultCount += 1 }
}
let timeSlow = Date().timeIntervalSince(startSlow)

let startFast = Date()
var adultCount2 = 0
for text in testData {
    if isAdultStringFast(text) { adultCount2 += 1 }
}
let timeFast = Date().timeIntervalSince(startFast)

print("Slow: \(timeSlow) sec, Fast: \(timeFast) sec")
