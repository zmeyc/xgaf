// XGAF file format parser for Swift.
// (c) 2016 Andrey Fidrya. MIT license. See LICENSE for more information.

import Foundation

public struct FieldFlags: OptionSet {
    public let rawValue: Int
    
    public static let required   = FieldFlags(rawValue: 1 << 0)
    public static let automorph  = FieldFlags(rawValue: 1 << 1)
    public static let newLine    = FieldFlags(rawValue: 1 << 2)
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}
