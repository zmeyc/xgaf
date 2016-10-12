// XGAF file format parser for Swift.
// (c) 2016 Andrey Fidrya. MIT license. See LICENSE for more information.

import Foundation

let definitionsFilename = "xgaf.dat"
let areaFilename = "020.mox"
let areaName = URL(fileURLWithPath: areaFilename).deletingPathExtension()

print("Loading definitions")
let definitions: Definitions
do {
    definitions = try Definitions(filename: definitionsFilename)
} catch {
    print("While parsing definitions:\n" +
        "\(definitionsFilename):\(error)")
    exit(1)
}

print("Loading areas")
let areas = Areas(definitions: definitions)
do {
    try areas.load(filename: areaFilename)
} catch {
    print("While loading areas:\n" +
        "\(areaFilename):\(error)")
    exit(1)
}

print("Saving simplified format")
let generator = SimpleAreaFormatGenerator(areas: areas)
do {
    try generator.save(areaName: areaName.absoluteString)
} catch {
    print("While saving area \(areaName.lastPathComponent): \(error.localizedDescription)")
    exit(1)
}

print("Finished")
