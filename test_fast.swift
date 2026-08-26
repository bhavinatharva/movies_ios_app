import Foundation

let adultKeywords = [
    "adult", "adults", "xxx", "porn", "18+", "18 plus", "onlyfans", "playboy",
    "brazzers", "vixen", "naughty", "erotic", "nsfw"
]
let adultKeywordsUtf8 = adultKeywords.map { Array($0.utf8) }

func isAdultUtf8(_ text: String) -> Bool {
    let lower = text.lowercased()
    let textUtf8 = Array(lower.utf8)
    for kw in adultKeywordsUtf8 {
        // Simple sub-array search (naive)
        if textUtf8.count >= kw.count {
            for i in 0...(textUtf8.count - kw.count) {
                var match = true
                for j in 0..<kw.count {
                    if textUtf8[i+j] != kw[j] {
                        match = false
                        break
                    }
                }
                if match { return true }
            }
        }
    }
    return false
}

let testData = (0..<100_000).map { "VOD Channel \($0) with some normal text" }

let start = Date()
var adultCount = 0
for text in testData {
    if isAdultUtf8(text) { adultCount += 1 }
}
let time = Date().timeIntervalSince(start)

print("Utf8: \(time) sec")
