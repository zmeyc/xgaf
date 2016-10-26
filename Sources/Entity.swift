// XGAF file format parser for Swift.
// (c) 2016 Andrey Fidrya. MIT license. See LICENSE for more information.

import Foundation

class Entity {
    private var lastAddedIndex = 0
    private var values = [String: Value]()
    private var structureIndexes = [String: Int]();
    private(set) var orderedNames = [String]()
    
    func startStructure(named name: String) {
        if let current = structureIndexes[name] {
            structureIndexes[name] = current + 1
        } else {
            structureIndexes[name] = 0
        }
        //print("startStructure: named=\(name), index=\(structureIndexes[name]!)")
    }
    
    func add(name: String, value: Value) -> Bool {
        let name = appendCurrentIndex(toName: name)
        
        guard values[name] == nil else { return false }
        values[name] = value
        orderedNames.append(name)
        return true
    }
    
    func replace(name: String, value: Value) {
        let name = appendCurrentIndex(toName: name)
        
        guard values[name] == nil else {
            values[name] = value
            return
        }
        values[name] = value
        orderedNames.append(name)
    }
    
    func value(named name: String) -> Value? {
        let name = appendCurrentIndex(toName: name)
        return values[name]
    }
    
    func hasRequiredField(named name: String) -> Bool {
        if let structureName = structureName(fromFieldName: name) {
            guard let lastIndex = structureIndexes[structureName] else {
                // This is a structure field, but no structures were created
                return true
            }
            // Every structure should have required field:
            for i in 0...lastIndex {
                let nameWithIndex = appendIndex(toName: name, index: i)
                guard values[nameWithIndex] != nil else { return false }
            }
            return true
        }
        
        return values[name] != nil
    }
    
    private func appendIndex(toName name: String, index: Int) -> String {
        return "\(name)[\(index)]"
    }
    
    private func appendCurrentIndex(toName name: String) -> String {
        if let structureName = structureName(fromFieldName: name),
                let index = structureIndexes[structureName] {
            return appendIndex(toName: name, index: index)
        }
        return name
    }
}
