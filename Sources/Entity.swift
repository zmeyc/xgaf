// XGAF file format parser for Swift.
// (c) 2016 Andrey Fidrya. MIT license. See LICENSE for more information.

import Foundation

class Entity {
    private var lastAddedIndex = 0
    private var values = [String: Value]()
    private(set) var orderedNames = [String]()
    
    func add(name: String, value: Value) -> Bool {
        guard values[name] == nil else { return false }
        values[name] = value
        orderedNames.append(name)
        return true
    }
    
    func replace(name: String, value: Value) {
        guard values[name] == nil else {
            values[name] = value
            return
        }
        values[name] = value
        orderedNames.append(name)
    }
    
    func value(named name: String) -> Value? {
        return values[name]
    }
    
    func containsField(named name: String) -> Bool {
        return values[name] != nil
    }
}
