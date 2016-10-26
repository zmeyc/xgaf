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
        
        generate(entities: areas.items, primaryField: "предмет", appendTo: &out)
        generate(entities: areas.mobiles, primaryField: "монстр", appendTo: &out)
        generate(entities: areas.rooms, primaryField: "комната", appendTo: &out)
        
        return out
    }
    
    private func generate(entities: [Int64: Entity], primaryField: String, appendTo out: inout String) {
        
        let sortedIds = entities.keys.sorted()
        for id in sortedIds {
            if id != sortedIds.first {
                out += "\n"
            }
            
            guard let entity = entities[id] else { continue }

            out += "\(primaryField.uppercased()) \(id)\n"
            
            for key in entity.orderedNames {
                guard key != primaryField else { continue }
                guard let value = entity.value(named: key) else { continue }
                
                let key = key.components(separatedBy: "[").first ?? key
                out += "\(key.uppercased()) \(value.toSimplifiedFormat)\n"
            }
        }
    }
}
