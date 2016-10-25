// XGAF file format parser for Swift.
// (c) 2016 Andrey Fidrya. MIT license. See LICENSE for more information.

import Foundation
import Utils

let definitionsLog = false

class Definitions {
    let scanner: Scanner
    
    var items = FieldDefinitions()
    var mobiles = FieldDefinitions()
    var rooms = FieldDefinitions()
    var enumerations = Enumerations()
    var cases = GrammaticalCases()
    
    init(filename: String) throws {
        let contents = try String(contentsOfFile: filename, encoding: .utf8)
        
        scanner = Scanner(string: contents)
        
        try scanner.skipComments()
        while !scanner.isAtEnd {
            try scanNextSection()

            try scanner.skipComments()
        }
    }
    
    
    private func scanNextSection() throws {
        try scanner.skipComments()
        guard scanner.skipString("[") else {
            try throwError(.expectedSectionStart)
        }

        try scanner.skipComments()
        guard let section = scanner.scanWord() else {
            try throwError(.expectedSectionName)
        }

        try scanner.skipComments()
        guard scanner.skipString("]") else {
            try throwError(.expectedSectionEnd)
        }
        
        if definitionsLog {
            print("[\(section)]")
        }
        switch section.lowercased() {
            case "предметы": try scanEntityFields(fieldDefinitions: &items)
            case "монстры": try scanEntityFields(fieldDefinitions: &mobiles)
            case "комнаты": try scanEntityFields(fieldDefinitions: &rooms)
            case "константы": try scanEnumerations()
            case "окончания": try scanEndings()
            default: try throwError(.unsupportedSectionType)
        }
    }
    
    private func scanEntityFields(fieldDefinitions: inout FieldDefinitions) throws {
        try scanner.skipComments()
        while let cu = scanner.peekUtf16CodeUnit(), cu != 91 { // [
            guard let name = scanner.scanWord() else { return }

            try scanner.skipComments()
            guard let flags = scanner.scanWord() else { try throwError(.flagsExpected) }
            guard let fieldInfo = FieldInfo(name: name, flags: flags) else {
                try throwError(.invalidFieldFlags)
            }
            guard fieldDefinitions.insert(fieldInfo: fieldInfo) else {
                try throwError(.duplicateFieldDefinition)
            }
         
            if definitionsLog {
                print("name: \(name), flags: \(flags)")
            }

            try scanner.skipComments()
        }
    }
    
    private func scanEnumerations() throws {
        var aliases = Set<String>()
        var namesByValue = Enumerations.NamesByValue()
        
        try scanner.skipComments()
        while let cu = scanner.peekUtf16CodeUnit(), cu != 91 { // [
            
            var value: Int64 = 0
            if scanner.scanInt64(&value) {
                
                try scanner.skipComments()
                if let name = scanner.scanWord() {
                    if definitionsLog {
                        print("name: \(name), value: \(value)")
                    }
                    namesByValue[value] = name.lowercased()
                    
                } else {
                    try throwError(.syntaxError)
                }
                
            } else if let word = scanner.scanWord() {
                if namesByValue.isEmpty {
                    // Add another alias
                    aliases.insert(word)
                } else {
                    // New enumeration starting
                    if definitionsLog {
                        print("Add enumeration with aliases: \(aliases)")
                    }
                    enumerations.add(aliases: Array(aliases), namesByValue: namesByValue)
                    aliases = Set<String>()
                    aliases.insert(word)
                    namesByValue = Enumerations.NamesByValue()
                }
                
            } else {
                try throwError(.syntaxError)
            }

            try scanner.skipComments()
        }
        
        if definitionsLog {
            print("Add enumeration with aliases: \(aliases)")
        }
        enumerations.add(aliases: Array(aliases), namesByValue: namesByValue)
    }

    private func scanEndings() throws {
        try scanner.skipComments()
        while let cu = scanner.peekUtf16CodeUnit(), cu != 91 { // [
            var forms = [String]()
            
            for _ in 0...5 {
                guard let word = scanner.scanWord() else {
                    try throwError(.syntaxError)
                }
                forms.append(word)

                cases.add(cases: forms)
                
                try scanner.skipComments()
            }
            
            if definitionsLog {
                print("forms: \(forms)")
            }
        }
    }
    
    private func throwError(_ kind: ParseError.Kind) throws -> Never  {
        throw ParseError(kind: kind, scanner: scanner)
    }
}
