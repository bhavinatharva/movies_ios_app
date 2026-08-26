import Foundation

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

let testData = (0..<100_000).map { "VOD Channel \($0) with some normal text" }

let start = Date()
var adultCount = 0
for text in testData {
    if isAdultStringSlow(text) { adultCount += 1 }
}
let time = Date().timeIntervalSince(start)

print("Adult check time for 100k items: \(time) sec")
