// XGAF file format parser for Swift.
// (c) 2016 Andrey Fidrya. MIT license. See LICENSE for more information.

import Foundation

class ExtendedAreaFormatGenerator: AreaFormatGenerator {
    let areas: Areas
    
    init(areas: Areas) {
        self.areas = areas
    }
    
    func save(toFileNamed filename: String) throws {
        let out = generateOutput()

        do {
            try out.write(toFile: filename, atomically: true, encoding: .utf8)
        } catch {
            throw SaveError(kind: .ioError(error: error))
        }
    }
    
    private func generateOutput() -> String {
        var out = ""
        out.reserveCapacity(256 * 1024)
        
        generate(entities: areas.items, enumerations: areas.definitions.enumerations, primaryField: "предмет", appendTo: &out)
        generate(entities: areas.mobiles, enumerations: areas.definitions.enumerations, primaryField: "монстр", appendTo: &out)
        generate(entities: areas.rooms, enumerations: areas.definitions.enumerations, primaryField: "комната", appendTo: &out)
        
        return out
    }
    
    private func generate(entities: [Int64: Entity], enumerations: Enumerations, primaryField: String, appendTo out: inout String) {
        
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
                out += "\(key.uppercased()) \(value.toExtendedFormat(fieldAlias: key.lowercased(), enumerations: enumerations))\n"
            }
        }
    }
}
