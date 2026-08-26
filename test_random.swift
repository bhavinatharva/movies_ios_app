import Foundation

func pickRandom<T>(_ array: inout [T], limit: Int) -> [T] {
    var result: [T] = []
    let count = min(limit, array.count)
    for i in 0..<count {
        let randomIndex = Int.random(in: i..<array.count)
        array.swapAt(i, randomIndex)
        result.append(array[i])
    }
    return result
}

struct Item {
    let id: Int
    let text: String
}

var items = (0..<100_000).map { Item(id: $0, text: "Some long text \($0)") }

let start = Date()
var x1 = items
let r1 = pickRandom(&x1, limit: 15)
var x2 = items
let r2 = pickRandom(&x2, limit: 15)
var x3 = items
let r3 = pickRandom(&x3, limit: 15)
var x4 = items
let r4 = pickRandom(&x4, limit: 15)
let time = Date().timeIntervalSince(start)

print("PickRandom time: \(time) sec")
