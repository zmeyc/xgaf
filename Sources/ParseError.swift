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
        
        var description: String {
            switch self {
            case .unterminatedComment: return "unterminated comment found"
            case .expectedSectionStart: return "expected '['"
            case .expectedSectionName: return "expected section name terminated with ']'"
            case .expectedSectionEnd: return "expected ']'"
            case .unsupportedSectionType: return "unsupported section type"
            case .flagsExpected: return "flags expected"
            case .invalidFieldFlags: return "invalid field flags"
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
            case .invalidEnumerationValue: return "expected enumeration value"
            case .duplicateValue: return "duplicate value"
            }
        }
    }
    
    let kind: Kind
    let line: Int?
    let column: Int?
    
    var description: String {
        guard let line = line, let column = column else {
            return kind.description
        }
        return "[\(line):\(column)] \(kind.description)"
    }
    
    var localizedDescription: String {
        return description
    }
}
