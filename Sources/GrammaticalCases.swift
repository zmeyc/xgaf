// XGAF file format parser for Swift.
// (c) 2016 Andrey Fidrya. MIT license. See LICENSE for more information.

import Foundation

class GrammaticalCases {
    typealias Cases = [String]
    var animateByNominativeCase = [String: Cases]()
    var inanimateByNominativeCase = [String: Cases]()
    
    func add(cases: [String]) {
        let splitted = cases.map { splitCase(word: $0) }
        guard let nominative = splitted.first else { return }
        
        animateByNominativeCase[nominative.animate] = splitted.map {
            $0.animate
        }
        
        inanimateByNominativeCase[nominative.inanimate] = splitted.map {
            $0.inanimate
        }
    }
    
    // *-a: ["", "a"]
    // жом-жем: ["жом", "жем"]
    private func splitCase(word: String) -> (inanimate: String, animate: String) {
        let words = word.components(separatedBy: "-").map {
            $0.replacingOccurrences(of: "*", with: "")
        }
        switch words.count {
        case 1:
            return (inanimate: words[0], animate: words[0])
        case 2:
            return (inanimate: words[0], animate: words[1])
        default:
            break
        }
        
        return (inanimate: "", animate: "")
    }
}
