// XGAF file format parser for Swift.
// (c) 2016 Andrey Fidrya. MIT license. See LICENSE for more information.

import Foundation

enum Value {
    case number(Int64)
    case enumeration(Int64)
    case flags(Int64)
    case list(Set<Int64>)
    case dictionary([Int64: Int64?])
    case line([String])
    case longText([String])
    case dice(Int64, Int64, Int64)
    
    var toSimplifiedFormat: String {
        switch self {
        case .number(let value): return "\(value)"
        case .enumeration(let value): return "\(value)"
        case .flags(let value): return "\(value)"
        case .list(let values): return values.sorted().map { "\($0)" }.joined(separator: " ")
        case .dictionary(let values):
            let keys = values.keys.sorted()
            return keys.map {
                if let optionalValue = values[$0], let value = optionalValue {
                    return "\($0)=\(value)"
                } else {
                    return "\($0)"
                }
            }.joined(separator: " ")
        case .line(let values), .longText(let values):
            return values.map { value in
                return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
            }.joined(separator: "\n")
        case let .dice(x, y, z):
            return "\(x) \(y) \(z)"
        }
    }
}
