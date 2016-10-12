// XGAF file format parser for Swift.
// (c) 2016 Andrey Fidrya. MIT license. See LICENSE for more information.

import Foundation

class SimpleAreaFormatGenerator {
    let areas: Areas
    
    init(areas: Areas) {
        self.areas = areas
    }
    
    func save(areaName: String) throws {
        var out = ""
        out.reserveCapacity(256 * 1024)
        
        try out.write(toFile: "\(areaName).out", atomically: true, encoding: .utf8)
    }
}
