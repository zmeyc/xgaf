// XGAF file format parser for Swift.
// (c) 2016 Andrey Fidrya. MIT license. See LICENSE for more information.

import Foundation

class Morpher {
    let definitions: Definitions
    
    init(definitions: Definitions) {
        self.definitions = definitions
    }
    
    func convertToSimpleAreaFormat(text: String) -> String {
        return text
    }
}
