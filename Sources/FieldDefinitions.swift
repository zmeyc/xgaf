// XGAF file format parser for Swift.
// (c) 2016 Andrey Fidrya. MIT license. See LICENSE for more information.

import Foundation

class FieldDefinitions {
    private var fields = [String: FieldInfo]()

    func insert(fieldInfo: FieldInfo) {
        fields[fieldInfo.name] = fieldInfo
    }
    
    func field(name: String) -> FieldInfo? {
        return fields[name]
    }
}
