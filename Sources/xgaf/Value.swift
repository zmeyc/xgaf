// XGAF file format parser for Swift.
// (c) 2016 Andrey Fidrya. MIT license. See LICENSE for more information.

import Foundation

enum Value {
    case number(Int64)
    case enumeration(Int64)
    case flags(Int64)
    case list(Set<Int64>)
    case dictionary([Int64: Int64?])
    case line(String)
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
        case .line(let value):
            return escaping(value)
        case .longText(let values):
            return values.map { value in
                return escaping(value)
            }.joined(separator: "\n")
        case let .dice(x, y, z):
            return "\(x) \(y) \(z)"
        }
    }
    
    func toExtendedFormat(fieldAlias: String, enumerations: Enumerations) -> String {
        switch self {
        case .number(let value): return "\(value)"
        case .enumeration(let value):
            if let names = enumerations.namesByValueForAlias[fieldAlias] {
                if let name = names[value] {
                    return name.uppercased()
                }
            }
            return "\(value)"
        case .flags(let value):
            if let names = enumerations.namesByValueForAlias[fieldAlias] {
                let result = (0..<64).compactMap { (bitIndex: Int64) -> String? in
                    if 0 != value & (1 << bitIndex) {
                        let oneBasedBitIndex = bitIndex + 1
                        return names[oneBasedBitIndex]?.uppercased() ?? String(oneBasedBitIndex)
                    }
                    return nil
                }.joined(separator: " ")
                return result
            }
            return "\(value)"
        case .list(let values):
            if let names = enumerations.namesByValueForAlias[fieldAlias] {
                let result = values.sorted(by: <).map{
                    names[$0]?.uppercased() ?? String($0)
                }.joined(separator: " ")
                return result
            }
            return values.sorted().map { "\($0)" }.joined(separator: " ")
        case .dictionary(let keysAndValues):
            if let names = enumerations.namesByValueForAlias[fieldAlias] {
                let result = keysAndValues.sorted(by: { $0.key < $1.key }).map { key, value in
                    let key = names[key]?.uppercased() ?? String(key)
                    if let value = value {
                        return "\(key)=\(value)"
                    } else {
                        return key
                    }
                }.joined(separator: " ")
                return result
            }
            let keys = keysAndValues.keys.sorted()
            return keys.map {
                if let optionalValue = keysAndValues[$0], let value = optionalValue {
                    return "\($0)=\(value)"
                } else {
                    return "\($0)"
                }
            }.joined(separator: " ")
        case .line(let value):
            return escaping(value)
        case .longText(let values):
            let continuationIndent = fieldAlias.count + 1
            let separator = "\n" + String(repeating: " ", count: continuationIndent)
            let finalText = values.map { escaping($0) }.joined(separator: separator)
            let result = !finalText.isEmpty ? finalText : escaping("")
            return result
        case let .dice(number, size, add):
            if add != 0 {
                // Not '&&' to log '0d5', '5d0' cases otherwise that would be information loss
                if number != 0 || size != 0 {
                    return "\(number)к\(size)+\(add)"
                } else {
                    return "\(add)"
                }
            }
            return "\(number)к\(size)"
        }
    }
    
    private func escaping(_ value: String) -> String {
        return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
