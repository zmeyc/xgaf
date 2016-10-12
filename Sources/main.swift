// XGAF file format parser for Swift.
// (c) 2016 Andrey Fidrya. MIT license. See LICENSE for more information.

import Foundation

let definitionsFilename = "xgaf.dat"
let areaFilename = "020.mox"

print("Starting conversion")

let definitions: Definitions
do {
    definitions = try Definitions(filename: definitionsFilename)
} catch {
    print("While parsing definitions:\n" +
        "\(definitionsFilename):\(error)")
    exit(1)
}

let areas = Areas(definitions: definitions)
do {
    try areas.load(filename: areaFilename)
} catch {
    print("While loading areas:\n" +
        "\(areaFilename):\(error)")
    exit(1)
}

print("Finished succesfully")
