// XGAF file format parser for Swift.
// (c) 2016 Andrey Fidrya. MIT license. See LICENSE for more information.

import Foundation

let areasLog = false

class Areas {
    var scanner: Scanner!
    let definitions: Definitions
    
    var items = [Int64: Entity]()
    var mobiles = [Int64: Entity]()
    var rooms = [Int64: Entity]()
    
    var fieldDefinitions: FieldDefinitions!
    var currentEntity: Entity!
    var currentFieldName = "" // struct.name
    var currentFieldNameWithIndex = "" // struct.name[0]
    var currentStructureName = "" // struct
    var firstFieldInStructure = false
    
    init(definitions: Definitions) {
        self.definitions = definitions
    }
    
    func load(filename: String) throws {
        let contents = try String(contentsOfFile: filename, encoding: .utf8)

        scanner = Scanner(string: contents)
        currentEntity = nil
        currentFieldName = ""
        currentFieldNameWithIndex = ""
        currentStructureName = ""
        firstFieldInStructure = false
        
        try scanner.skipComments()
        while !scanner.isAtEnd {
            try scanNextEntity()

            try scanner.skipComments()
        }
        
        try finalizeCurrentEntity()
        
        guard currentStructureName.isEmpty else {
            try throwError(.unterminatedStructure)
        }
    }
    
    private func scanNextEntity() throws {
        try scanner.skipComments()
        
        guard let field = scanner.scanWord() else {
            try throwError(.expectedFieldName)
        }

        currentFieldName = field.lowercased()
        if currentStructureName.isEmpty {
            switch currentFieldName {
            case "предмет":
                try finalizeCurrentEntity()
                fieldDefinitions = definitions.items
            case "монстр":
                try finalizeCurrentEntity()
                fieldDefinitions = definitions.mobiles
            case "комната":
                try finalizeCurrentEntity()
                fieldDefinitions = definitions.rooms
            default:
                break
            }
        }
        
        if !currentStructureName.isEmpty {
            currentFieldName = "\(currentStructureName).\(currentFieldName)"
        }
        
        let requireFieldSeparator: Bool
        if try openStructure() {
            if areasLog {
                print("--- Structure opened: \(currentStructureName)")
            }
            requireFieldSeparator = false
        } else {
            try scanValue()
            requireFieldSeparator = true
        }

        if try closeStructure() {
            if areasLog {
                print("--- Structure closed")
            }
        }

        if requireFieldSeparator {
            try scanner.skipping(CharacterSet.whitespaces) {
                try scanner.skipComments()
                guard scanner.skipString(":") ||
                    scanner.skipString("\r\n") ||
                    scanner.skipString("\n") ||
                    scanner.isAtEnd
                else {
                    try throwError(.expectedFieldSeparator)
                }
            }
        }
    }
    
    private func openStructure() throws -> Bool {
        guard currentStructureName.isEmpty else { return false }
        
        try scanner.skipComments()
        guard scanner.skipString("(") else {
            return false // Not a structure
        }
        
        currentStructureName = currentFieldName
        firstFieldInStructure = true
        
        if let current = currentEntity.lastStructureIndex[currentStructureName] {
            currentEntity.lastStructureIndex[currentStructureName] = current + 1
        } else {
            currentEntity.lastStructureIndex[currentStructureName] = 0
        }
        //print("openStructure: named=\(currentStructureName), index=\(currentEntity.lastStructureIndex[currentStructureName]!)")
        
        return true
    }

    private func closeStructure() throws -> Bool {
        guard !currentStructureName.isEmpty else { return false }
        
        try scanner.skipComments()
        guard scanner.skipString(")") else {
            return false
        }
        
        currentStructureName = ""
        firstFieldInStructure = false
        return true
    }
    
    private func appendCurrentIndex(toName name: String) -> String {
        if let structureName = structureName(fromFieldName: name),
            let index = currentEntity.lastStructureIndex[structureName] {
            return appendIndex(toName: name, index: index)
        }
        return name
    }

    private func scanValue() throws {
        if fieldDefinitions == nil {
            try throwError(.unsupportedEntityType)
        }
        guard let field = fieldDefinitions.field(name: currentFieldName) else {
            try throwError(.unknownFieldType)
        }
        
        if firstFieldInStructure {
            firstFieldInStructure = false
            if !field.flags.contains(.structureStart) {
                try throwError(.structureCantStartFromThisField)
            }
        }
        
        if let name = structureName(fromFieldName: currentFieldName),
                let index = currentEntity.lastStructureIndex[name] {
            currentFieldNameWithIndex = appendIndex(toName: currentFieldName, index: index)
        } else {
            currentFieldNameWithIndex = currentFieldName
        }
        
        try scanner.skipComments()
        try scanner.skipping(CharacterSet.whitespaces) {
            switch field.type {
            case .number: try scanNumber()
            case .enumeration: try scanEnumeration()
            case .flags: try scanFlags()
            case .list: try scanList()
            case .dictionary: try scanDictionary()
            case .line: try scanLine()
            case .longText: try scanLongText()
            case .dice: try scanDice()
            //default: fatalError()
            }
            assert(scanner.charactersToBeSkipped == CharacterSet.whitespaces)
        }
    }
    
    private func scanNumber() throws {
        assert(scanner.charactersToBeSkipped == CharacterSet.whitespaces)

        var result: Int64 = 0
        guard scanner.scanInt64(&result) else {
            try throwError(.expectedNumber)
        }
        let value = Value.number(result)
        guard currentEntity.add(name: currentFieldNameWithIndex, value: value) else {
            try throwError(.duplicateField)
        }
        if areasLog {
            print("\(currentFieldNameWithIndex): \(result)")
        }
    }
    
    private func scanEnumeration() throws {
        assert(scanner.charactersToBeSkipped == CharacterSet.whitespaces)

        guard let word = scanner.scanWord() else {
            try throwError(.expectedEnumerationValue)
        }
        let result = word.lowercased()
        
        guard let valuesByName = definitions.enumerations.valuesByNameForAlias[currentFieldName],
            let number = valuesByName[result] else {
                try throwError(.invalidEnumerationValue)
        }
        
        let value = Value.enumeration(number)
        guard currentEntity.add(name: currentFieldNameWithIndex, value: value) else {
            try throwError(.duplicateField)
        }
        if areasLog {
            print("\(currentFieldNameWithIndex): .\(result)")
        }
    }
    
    private func scanFlags() throws {
        assert(scanner.charactersToBeSkipped == CharacterSet.whitespaces)

        let valuesByName = definitions.enumerations.valuesByNameForAlias[currentFieldName]
        
        var result: Int64
        if let previousValue = currentEntity.value(named: currentFieldNameWithIndex),
            case .flags(let previousResult) = previousValue {
                result = previousResult
        } else {
                result = 0
        }

        while true {
            var bitNumber: Int64 = 0
            if scanner.scanInt64(&bitNumber) {
                let flags: Int64 = bitNumber <= 0 ? 0 : 1 << (bitNumber - 1)
                guard (result & flags) == 0 else {
                    try throwError(.duplicateValue)
                }
                result |= flags
            } else if let word = scanner.scanWord()?.lowercased() {
                guard let valuesByName = valuesByName else {
                    // List without associated enumeration names
                    try throwError(.expectedNumber)
                }
                guard let bitNumber = valuesByName[word] else {
                    try throwError(.invalidEnumerationValue)
                }
                let flags: Int64 = bitNumber <= 0 ? 0 : 1 << (bitNumber - 1)
                guard (result & flags) == 0 else {
                    try throwError(.duplicateValue)
                }
                result |= flags
            } else {
                break
            }
        }

        let value = Value.flags(result)
        currentEntity.replace(name: currentFieldNameWithIndex, value: value)
        if areasLog {
            print("\(currentFieldNameWithIndex): \(result)")
        }
    }

    private func scanList() throws {
        assert(scanner.charactersToBeSkipped == CharacterSet.whitespaces)

        let valuesByName = definitions.enumerations.valuesByNameForAlias[currentFieldName]
        
        var result: Set<Int64>
        if let previousValue = currentEntity.value(named: currentFieldNameWithIndex),
            case .list(let previousResult) = previousValue {
            result = previousResult
        } else {
            result = Set<Int64>()
        }
        
        while true {
            var number: Int64 = 0
            if scanner.scanInt64(&number) {
                guard result.insert(number).inserted else {
                    try throwError(.duplicateValue)
                }
            } else if let word = scanner.scanWord()?.lowercased() {
                guard let valuesByName = valuesByName else {
                    // List without associated enumeration names
                    try throwError(.expectedNumber)
                }
                guard let number = valuesByName[word] else {
                    try throwError(.invalidEnumerationValue)
                }
                guard result.insert(number).inserted else {
                    try throwError(.duplicateValue)
                }
            } else {
                break
            }
        }

        let value = Value.list(result)
        currentEntity.replace(name: currentFieldNameWithIndex, value:  value)
        if areasLog {
            print("\(currentFieldNameWithIndex): \(result)")
        }
    }

    private func scanDictionary() throws {
        assert(scanner.charactersToBeSkipped == CharacterSet.whitespaces)
        
        let valuesByName = definitions.enumerations.valuesByNameForAlias[currentFieldName]
        
        var result: [Int64: Int64]
        if let previousValue = currentEntity.value(named: currentFieldNameWithIndex),
            case .dictionary(let previousResult) = previousValue {
            result = previousResult
        } else {
            result = [Int64: Int64]()
        }
        
        while true {
            var key: Int64 = 0
            if scanner.scanInt64(&key) {
                guard result[key] == nil else {
                    try throwError(.duplicateValue)
                }
                var value: Int64 = 0
                if scanner.skipString("=") {
                    guard scanner.scanInt64(&value) else {
                        try throwError(.expectedNumber)
                    }
                }
                result[key] = value
            } else if let word = scanner.scanWord()?.lowercased() {
                guard let valuesByName = valuesByName else {
                    // List without associated enumeration names
                    try throwError(.expectedNumber)
                }
                guard let key = valuesByName[word] else {
                    try throwError(.invalidEnumerationValue)
                }
                guard result[key] == nil else {
                    try throwError(.duplicateValue)
                }
                var value: Int64 = 0
                if scanner.skipString("=") {
                    guard scanner.scanInt64(&value) else {
                        try throwError(.expectedNumber)
                    }
                }
                result[key] = value
            } else {
                break
            }
        }
        
        let value = Value.dictionary(result)
        currentEntity.replace(name: currentFieldNameWithIndex, value: value)
        if areasLog {
            print("\(currentFieldNameWithIndex): \(result)")
        }
    }

    private func scanQuotedText() throws -> String {
        var result = ""
        guard scanner.skipString("\"") else {
            try throwError(.expectedDoubleQuote)
        }
        while true {
            guard let text = scanner.scanUpTo("\"") else {
                try throwError(.unterminatedString)
            }
            result += text
            
            scanner.skipString("\"")
            
            var shouldBreak = false
            try scanner.skipping(nil) {
                if scanner.skipString("\"") {
                    // Escaped "
                    result += "\""
                } else {
                    shouldBreak = true
                }
            }
            if shouldBreak {
                break
            }
        }
        return result
    }
    
    private func scanLine() throws {
        assert(scanner.charactersToBeSkipped == CharacterSet.whitespaces)

        let result = try scanQuotedText()
        let value = Value.line(result)
        if currentEntity.value(named: currentFieldNameWithIndex) != nil {
            try throwError(.duplicateField)
        }
        currentEntity.replace(name: currentFieldNameWithIndex, value: value)
        if areasLog {
            print("\(currentFieldNameWithIndex): \(result)")
        }
    }
    
    private func scanLongText() throws {
        assert(scanner.charactersToBeSkipped == CharacterSet.whitespaces)

        var result = try scanQuotedText()
        while true {
            do {
                assert(scanner.charactersToBeSkipped == CharacterSet.whitespaces)
                try scanner.skipping(CharacterSet.whitespacesAndNewlines) {
                    let nextLine = try scanQuotedText()
                    result += nextLine
                }
            } catch let error as ParseError {
                if case .expectedDoubleQuote = error.kind {
                    // It's normal to not have continuation lines
                    break
                } else {
                    throw error
                }
            }
        }
        let value = Value.longText(result)
        if currentEntity.value(named: currentFieldNameWithIndex) != nil {
            try throwError(.duplicateField)
        }
        currentEntity.replace(name: currentFieldNameWithIndex, value:  value)
        if areasLog {
            print("\(currentFieldNameWithIndex): \(result)")
        }
    }
    
    private func scanDice() throws {
        assert(scanner.charactersToBeSkipped == CharacterSet.whitespaces)
        
        var v1: Int64 = 0
        guard scanner.scanInt64(&v1) else {
            try throwError(.expectedNumber)
        }
        
        let hasK = scanner.skipString("К") || scanner.skipString("к")

        var v2: Int64 = 0
        let hasV2 = scanner.scanInt64(&v2)
        
        let hasPlus = scanner.skipString("+")

        var v3: Int64 = 0
        let hasV3 = scanner.scanInt64(&v3)
        
        if hasK && !hasV2 {
            try throwError(.syntaxError)
        }
        if hasPlus && (!hasV2 || !hasV3) {
            try throwError(.syntaxError)
        }
        
        let value: Value
        if !hasV2 && !hasV3 {
            value = Value.dice(0, 0, v1)
        } else {
            value = Value.dice(v1, v2, v3)
        }
        

        if currentEntity.value(named: currentFieldNameWithIndex) != nil {
            try throwError(.duplicateField)
        }
        currentEntity.replace(name: currentFieldNameWithIndex, value:  value)
        if areasLog {
            print("\(currentFieldNameWithIndex): \(v1)к\(v2)+\(v3)")
        }
    }

    private func finalizeCurrentEntity() throws {
        if let entity = currentEntity {
            if let item = entity.value(named: "предмет"),
                case .number(let itemId) = item {
                    items[itemId] = entity
            } else if let mobile = entity.value(named: "монстр"),
                case .number(let mobileId) = mobile {
                    mobiles[mobileId] = entity
            } else if let room = entity.value(named: "комната"),
                case .number(let roomId) = room {
                    rooms[roomId] = entity
            } else {
                try throwError(.unknownEntityType)
            }
            
            if areasLog {
                print("---")
            }
        }
        currentEntity = Entity()
    }
    
    private func throwError(_ kind: ParseError.Kind) throws -> Never  {
        throw ParseError(kind: kind, scanner: scanner)
    }
}
