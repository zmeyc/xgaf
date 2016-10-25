// XGAF file format parser for Swift.
// (c) 2016 Andrey Fidrya. MIT license. See LICENSE for more information.

import Foundation

class FieldDefinitions {
    private var fields = [String: FieldInfo]()
    private(set) public var requiredFieldNames = [String]()

    func insert(fieldInfo: FieldInfo) -> Bool {
        guard fields[fieldInfo.name] == nil else { return false }
        fields[fieldInfo.name] = fieldInfo
        if fieldInfo.flags.contains(.required) {
            requiredFieldNames.append(fieldInfo.name)
        }
        return true
    }
    
    func field(name: String) -> FieldInfo? {
        return fields[name]
    }
}
