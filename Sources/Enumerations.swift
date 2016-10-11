// XGAF file format parser for Swift.
// (c) 2016 Andrey Fidrya. MIT license. See LICENSE for more information.

import Foundation

class Enumerations {
    typealias NamesByValue = [Int64: String]
    typealias ValuesByName = [String: Int64]
    
    var namesByValueForAlias = [String: NamesByValue]()
    var valuesByNameForAlias = [String: ValuesByName]()
    
    func add(aliases: [String], namesByValue: NamesByValue) {
        
        var namesByValueLower = NamesByValue()
        for (k, v) in namesByValue {
            namesByValueLower[k] = v
        }
        
        var valuesByNameLower = ValuesByName()
        for (k, v) in namesByValueLower {
            valuesByNameLower[v] = k
        }
        
        for alias in aliases {
            let alias = alias.lowercased()
            namesByValueForAlias[alias] = namesByValueLower
            valuesByNameForAlias[alias] = valuesByNameLower
        }
    }
}
