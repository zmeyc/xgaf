// XGAF file format parser for Swift.
// (c) 2016 Andrey Fidrya. MIT license. See LICENSE for more information.

import Foundation

enum Value {
    case number(Int64)
    case enumeration(Int64)
    case flags(Int64)
    case list(Set<Int64>)
    case dictionary([Int64: Int64])
    case line(String)
    case longText(String)
    case dice(Int64, Int64, Int64)
}
