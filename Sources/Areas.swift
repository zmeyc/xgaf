// XGAF file format parser for Swift.
// (c) 2016 Andrey Fidrya. MIT license. See LICENSE for more information.

import Foundation

let areasLog = false

class Areas {
    enum StructureType {
        case none
        case extended
        case base
    }
    
    var scanner: Scanner!
    var lineUtf16Offsets = [Int]()
    let definitions: Definitions
    
    var items = [Int64: Entity]()
    var mobiles = [Int64: Entity]()
    var rooms = [Int64: Entity]()
    
    var fieldDefinitions: FieldDefinitions!
    var morpher: Morpher!
    var currentEntity: Entity!
    var currentFieldInfo: FieldInfo?
    var currentFieldName = "" // struct.name
    var currentFieldNameWithIndex = "" // struct.name[0]
    var currentStructureType: StructureType = .none
    var currentStructureName = "" // struct
    var firstFieldInStructure = false
    
    init(definitions: Definitions) {
        self.definitions = definitions
        self.morpher = Morpher(cases: definitions.cases)
    }
    
    func load(filename: String) throws {
        let contents: String
        do {
            contents = try String(contentsOfFile: filename, encoding: .utf8)
        } catch {
            throw ParseError(kind: .unableToLoadFile(error: error), scanner: nil)
        }

        scanner = Scanner(string: contents)
        currentEntity = nil
        currentFieldInfo = nil
        currentFieldName = ""
        currentFieldNameWithIndex = ""
        currentStructureType = .none
        currentStructureName = ""
        firstFieldInStructure = false
        
        lineUtf16Offsets = findLineUtf16Offsets(text: contents)
        
        try scanner.skipComments()
        while !scanner.isAtEnd {
            try scanNextEntity()

            try scanner.skipComments()
        }
        
        try finalizeCurrentEntity()
        
        guard currentStructureType == .none else {
            try throwError(.unterminatedStructure)
        }
    }
    
    func findLineUtf16Offsets(text: String) -> [Int] {
        var offsets = [0]
        
        var at = 0
        for cu in text.utf16 {
            if cu == 10 { // \n
                offsets.append(at + 1)
            }
            at += 1
        }
        
        return offsets
    }
    
    private func scanNextEntity() throws {
        try scanner.skipComments()
        
        guard let word = scanner.scanWord() else {
            try throwError(.expectedFieldName)
        }
        let (baseStructureName, field) = structureAndFieldName(word)
        
        if !baseStructureName.isEmpty {
            // Base format style structure name encountered: struct.field
            currentStructureType = .base
            currentStructureName = baseStructureName.lowercased()
            if areasLog {
                print("--- Base structure opened: \(currentStructureName)")
            }
        }

        currentFieldName = field.lowercased()
        if currentStructureType == .none {
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
        
        if currentStructureType != .none {
            currentFieldName = "\(currentStructureName).\(currentFieldName)"
        }
        
        let requireFieldSeparator: Bool
        if try openExtendedStructure() {
            if areasLog {
                print("--- Extended structure opened: \(currentStructureName)")
            }
            requireFieldSeparator = false
        } else {
            try scanValue()
            requireFieldSeparator = true
        }

        if currentStructureType == .base {
            currentStructureType = .none
            currentStructureName = ""
            if areasLog {
                print("--- Base structure closed")
            }
        } else if try closeExtendedStructure() {
            if areasLog {
                print("--- Extended structure closed")
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
    
    private func assignIndexToNewStructure(named name: String) {
        if let current = currentEntity.lastStructureIndex[name] {
            currentEntity.lastStructureIndex[name] = current + 1
        } else {
            currentEntity.lastStructureIndex[name] = 0
        }
        if areasLog {
            print("assignIndexToNewStructure: named=\(name), index=\(currentEntity.lastStructureIndex[name]!)")
        }
    }
    
    private func openExtendedStructure() throws -> Bool {
        guard currentStructureType == .none else { return false }
        
        try scanner.skipComments()
        guard scanner.skipString("(") else {
            return false // Not a structure
        }
        
        currentStructureType = .extended
        currentStructureName = currentFieldName
        firstFieldInStructure = true
        
        assignIndexToNewStructure(named: currentStructureName)
        
        return true
    }

    private func closeExtendedStructure() throws -> Bool {
        guard currentStructureType == .extended else { return false }
        
        try scanner.skipComments()
        guard scanner.skipString(")") else {
            return false
        }
        
        currentStructureType = .none
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
        guard let fieldInfo = fieldDefinitions.field(name: currentFieldName) else {
            try throwError(.unknownFieldType)
        }
        currentFieldInfo = fieldInfo
        
        switch currentStructureType {
        case .none:
            break
        case .base:
            // For base structures, assign a new index every time
            // a structure start field is encountered.
            if fieldInfo.flags.contains(.structureStart) {
                assignIndexToNewStructure(named: currentStructureName)
            }
        case .extended:
            // For extended structures, new index was assigned when
            // the structure was opened.
            if firstFieldInStructure {
                firstFieldInStructure = false
                if !fieldInfo.flags.contains(.structureStart) {
                    try throwError(.structureCantStartFromThisField)
                }
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
            switch fieldInfo.type {
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

        guard let result = scanner.scanInt64() else {
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

        let value: Value
        if let number = scanner.scanInt64() {
            value = Value.enumeration(number)
            if areasLog {
                print("\(currentFieldNameWithIndex): .\(number)")
            }
        } else if let word = scanner.scanWord() {
            let result = word.lowercased()
            guard let valuesByName = definitions.enumerations.valuesByNameForAlias[currentFieldName],
                    let number = valuesByName[result] else {
                try throwError(.invalidEnumerationValue)
            }
            value = Value.enumeration(number)
            if areasLog {
                print("\(currentFieldNameWithIndex): .\(number)")
            }
        } else {
            try throwError(.expectedEnumerationValue)
        }
        
        guard currentEntity.add(name: currentFieldNameWithIndex, value: value) else {
            try throwError(.duplicateField)
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
            if let flags = scanner.scanInt64() {
                //let flags: Int64 = bitNumber <= 0 ? 0 : 1 << (bitNumber - 1)
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
                let flags = bitNumber <= 0 ? 0 : 1 << (bitNumber - 1)
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
            if let number = scanner.scanInt64() {
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
        
        var result: [Int64: Int64?]
        if let previousValue = currentEntity.value(named: currentFieldNameWithIndex),
            case .dictionary(let previousResult) = previousValue {
            result = previousResult
        } else {
            result = [Int64: Int64?]()
        }
        
        while true {
            if let key = scanner.scanInt64() {
                guard result[key] == nil else {
                    try throwError(.duplicateValue)
                }
                if scanner.skipString("=") {
                    guard let value = scanner.scanInt64() else {
                        try throwError(.expectedNumber)
                    }
                    result[key] = value
                } else {
                    result[key] = nil as Int64?
                }
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
                if scanner.skipString("=") {
                    guard let value = scanner.scanInt64() else {
                        try throwError(.expectedNumber)
                    }
                    result[key] = value
                } else {
                    result[key] = nil as Int64?
                }
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
        try scanner.skipping(nil) {
            while true {
                if scanner.skipString("\"") {
                    // End of string or escaped quote?
                    if let cu = scanner.peekUtf16CodeUnit(), cu == 34 { // "
                        // If a quote is immediately followed by another quote,
                        // this is an escaped quote
                        scanner.skipString("\"")
                        result += "\""
                        continue
                    } else {
                        // End of string
                        break
                    }
                }
                
                guard let text = scanner.scanUpTo("\"") else {
                    try throwError(.unterminatedString)
                }
                result += text
            }
        }
        return result
    }
    
    private func scanLine() throws {
        assert(scanner.charactersToBeSkipped == CharacterSet.whitespaces)

        var result = try scanQuotedText()
        if currentFieldInfo?.flags.contains(.automorph) ?? false {
            result = morpher.convertToSimpleAreaFormat(text: result)
        }
        let value = Value.line([result])
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

        var result = [try scanQuotedText()]
        while true {
            do {
                assert(scanner.charactersToBeSkipped == CharacterSet.whitespaces)
                try scanner.skipping(CharacterSet.whitespacesAndNewlines) {
                    let nextLine = try scanQuotedText()
                    result.append(nextLine)
                    try scanner.skipComments()
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
        if currentFieldInfo?.flags.contains(.automorph) ?? false {
            result = result.map { morpher.convertToSimpleAreaFormat(text: $0) }
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
        
        guard let v1 = scanner.scanInt64() else {
            try throwError(.expectedNumber)
        }
        
        let hasK = scanner.skipString("К") || scanner.skipString("к")

        let v2OrNil = scanner.scanInt64()
        
        let hasPlus = scanner.skipString("+")

        let v3OrNil = scanner.scanInt64()
        
        if hasK && v2OrNil == nil {
            try throwError(.syntaxError)
        }
        if hasPlus && (v2OrNil == nil || v3OrNil == nil) {
            try throwError(.syntaxError)
        }
        
        let value: Value
        if v2OrNil == nil && v3OrNil == nil {
            value = Value.dice(0, 0, v1)
            if areasLog {
                print("\(currentFieldNameWithIndex): 0к0+\(v1)")
            }
        } else {
            value = Value.dice(v1, (v2OrNil ?? 0), (v3OrNil ?? 0))
            if areasLog {
                print("\(currentFieldNameWithIndex): \(v1)к\(v2OrNil ?? 0)+\(v3OrNil ?? 0)")
            }
        }

        if currentEntity.value(named: currentFieldNameWithIndex) != nil {
            try throwError(.duplicateField)
        }
        currentEntity.replace(name: currentFieldNameWithIndex, value:  value)
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
        currentEntity.startLine = lineAtUtf16Offset(scanner.scanLocation)
        //print("\(scanner.scanLocation): \(currentEntity.startLine)")
    }
    
    func lineAtUtf16Offset(_ offset: Int) -> Int {
        return lineUtf16Offsets.binarySearch { $0 < offset } /* - 1 */
    }
    
    private func throwError(_ kind: ParseError.Kind) throws -> Never  {
        throw ParseError(kind: kind, scanner: scanner)
    }
}
