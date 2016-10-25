// XGAF file format parser for Swift.
// (c) 2016 Andrey Fidrya. MIT license. See LICENSE for more information.

import Foundation

class FieldInfo {
    let name: String
    let type: FieldType
    var flags: FieldFlags
    
    init?(name: String, flags: String) {
        self.name = name.lowercased()
        
        var fieldType: FieldType?
        var fieldFlags = FieldFlags()
        
        for c in flags.lowercased().characters {
            switch c {
                case "ч": fieldType = .number
                case "п": fieldType = .enumeration
                case "б": fieldType = .flags
                case "с": fieldType = .list
                case "з": fieldType = .dictionary
                case "т": fieldType = .line
                case "д": fieldType = .longText
                case "к": fieldType = .dice
                
                case "*": fieldFlags.insert(.required)
                case "@": fieldFlags.insert(.automorph)
                case "!": fieldFlags.insert(.newLine)
                
                default: return nil
            }
        }
        
        guard let type = fieldType else { return nil }
        self.type = type
        
        self.flags = fieldFlags
    }
}
