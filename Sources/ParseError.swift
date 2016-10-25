// XGAF file format parser for Swift.
// (c) 2016 Andrey Fidrya. MIT license. See LICENSE for more information.

import Foundation

struct ParseError: Error, CustomStringConvertible {
    enum Kind: CustomStringConvertible {
        case unterminatedComment
        case expectedSectionStart
        case expectedSectionName
        case expectedSectionEnd
        case unsupportedSectionType
        case flagsExpected
        case invalidFieldFlags
        case duplicateFieldDefinition
        case syntaxError
        case expectedFieldName
        case unsupportedEntityType
        case unknownFieldType
        case expectedNumber
        case duplicateField
        case expectedFieldSeparator
        case expectedDoubleQuote
        case unterminatedString
        case expectedEnumerationValue
        case invalidEnumerationValue
        case duplicateValue
        case unterminatedStructure
        case unknownEntityType
        
        var description: String {
            switch self {
            case .unterminatedComment: return "unterminated comment found"
            case .expectedSectionStart: return "expected '['"
            case .expectedSectionName: return "expected section name terminated with ']'"
            case .expectedSectionEnd: return "expected ']'"
            case .unsupportedSectionType: return "unsupported section type"
            case .flagsExpected: return "flags expected"
            case .invalidFieldFlags: return "invalid field flags"
            case .duplicateFieldDefinition: return "duplicate field definition"
            case .syntaxError: return "syntax error"
            case .expectedFieldName: return "expected field name"
            case .unsupportedEntityType: return "unsupported entity type"
            case .unknownFieldType: return "unknown field type"
            case .expectedNumber: return "expected number"
            case .duplicateField: return "duplicate field"
            case .expectedFieldSeparator: return "expected field separator"
            case .expectedDoubleQuote: return "expected double quote"
            case .unterminatedString: return "unterminated string"
            case .expectedEnumerationValue: return "expected enumeration value"
            case .invalidEnumerationValue: return "invalid enumeration value"
            case .duplicateValue: return "duplicate value"
            case .unterminatedStructure: return "unterminated structure"
            case .unknownEntityType: return "unknown entity type"
            }
        }
    }
    
    let kind: Kind
    let scanner: Scanner?
    
    var description: String {
        guard let scanner = scanner else {
            return kind.description
        }
        return "\(scanner.line):\(scanner.column): \(kind.description). Offending line:\n" +
            "\(scanner.lineBeingParsed)"
    }
    
    var localizedDescription: String {
        return description
    }
}
