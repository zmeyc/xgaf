// XGAF file format parser for Swift.
// (c) 2016 Andrey Fidrya. MIT license. See LICENSE for more information.

import Foundation

struct SaveError: Error, CustomStringConvertible {
    enum Kind: CustomStringConvertible {
        case ioError(error: Error)
        case invalidExtension
        
        var description: String {
            switch self {
            case .ioError(let error): return error.localizedDescription
            case .invalidExtension: return "invalid source file extension, unable to deduce output filename"
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
