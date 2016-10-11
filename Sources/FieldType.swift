// XGAF file format parser for Swift.
// (c) 2016 Andrey Fidrya. MIT license. See LICENSE for more information.

import Foundation

enum FieldType {
    case number
    case enumeration
    case flags
    case list
    case dictionary
    case line
    case longText
    case dice
}
