// XGAF file format parser for Swift.
// (c) 2016 Andrey Fidrya. MIT license. See LICENSE for more information.

import Foundation

class SimpleAreaFormatGenerator {
    let areas: Areas
    
    init(areas: Areas) {
        self.areas = areas
    }
    
    func save(originalFilename: String) throws {
        let url = URL(fileURLWithPath: originalFilename)
        let fileExtension: String
        switch url.pathExtension.lowercased() {
            case "wlx": fileExtension = "wld"
            case "mox": fileExtension = "mob"
            case "obx": fileExtension = "obj"
        default: throw SaveError(kind: .invalidExtension)
        }
        
        let outFilename = "\(url.deletingPathExtension().relativeString).\(fileExtension)"
        
        let out = generateOutput()

        do {
            try out.write(toFile: "\(outFilename)", atomically: true, encoding: .utf8)
        } catch {
            throw SaveError(kind: .ioError(error: error))
        }
    }
    
    private func generateOutput() -> String {
        var out = ""
        out.reserveCapacity(256 * 1024)
        
        //areas.
        
        return out
    }
}
