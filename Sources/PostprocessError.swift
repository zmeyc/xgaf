// XGAF file format parser for Swift.
// (c) 2016 Andrey Fidrya. MIT license. See LICENSE for more information.

import Foundation

struct PostprocessError: Error, CustomStringConvertible {
    enum Kind: CustomStringConvertible {
        case requiredFieldMissing(entityType: String, entityId: String, fieldName: String)
        
        var description: String {
            switch self {
            case let .requiredFieldMissing(entityType, entityId, fieldName):
                return "\(entityType) \(entityId): required field '\(fieldName)' is missing"
            }
        }
    }
    
    let kind: Kind
    
    var description: String {
        return kind.description
    }
    
    var localizedDescription: String {
        return description
    }
}
