// XGAF file format parser for Swift.
// (c) 2024 Andrey Fidrya. MIT license. See LICENSE for more information.

import Foundation

protocol AreaFormatGenerator {
    func save(toFileNamed filename: String) throws
}
