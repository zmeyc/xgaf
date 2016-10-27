// XGAF file format parser for Swift.
// (c) 2016 Andrey Fidrya. MIT license. See LICENSE for more information.

import Foundation

func structureName(fromFieldName name: String) -> String? {
    guard name.contains(".") else { return nil }
    return name.components(separatedBy: ".").first
}

func structureAndFieldName(_ fullName: String) -> (String, String) {
    guard fullName.contains(".") else { return ("", fullName) }
    
    let components = fullName.components(separatedBy: ".")
    guard components.count == 2 else { return ("", fullName) }
    return (components[0], components[1])
}

func appendIndex(toName name: String, index: Int) -> String {
    return "\(name)[\(index)]"
}
