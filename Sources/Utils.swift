// XGAF file format parser for Swift.
// (c) 2016 Andrey Fidrya. MIT license. See LICENSE for more information.

import Foundation

func structureName(fromFieldName name: String) -> String? {
    guard name.contains(".") else { return nil }
    return name.components(separatedBy: ".").first
}
