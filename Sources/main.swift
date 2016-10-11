// XGAF file format parser for Swift.
// (c) 2016 Andrey Fidrya. MIT license. See LICENSE for more information.

import Foundation

let definitions: Definitions
do {
    definitions = try Definitions(filename: "xgaf.dat")
} catch {
    print("While parsing definitions: \(error)")
    exit(1)
}

let areas = Areas(definitions: definitions)
do {
    try areas.load(filename: "020.mox")
} catch {
    print("While loading areas: \(error)")
    exit(1)
}
