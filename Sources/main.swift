// XGAF file format parser for Swift.
// (c) 2016 Andrey Fidrya. MIT license. See LICENSE for more information.

import Foundation

let silent = true
let brief = true
var definitionsFilename: String?
var areaFilename: String
var destinationFilename: String?

switch CommandLine.arguments.count {
case 4:
    definitionsFilename = CommandLine.arguments[3]
    fallthrough
case 3:
    destinationFilename = CommandLine.arguments[2]
    fallthrough
case 2:
    areaFilename = CommandLine.arguments[1]
default:
    print("Usage:\n" +
        "xgaf file.wlx [file.wld] [xgaf.dat]")
    exit(1)
}

if definitionsFilename == nil {
    definitionsFilename = URL(fileURLWithPath: CommandLine.arguments[0])
        .deletingLastPathComponent()
        .appendingPathComponent("xgaf.dat", isDirectory: false)
        .path
}

if destinationFilename == nil {
    let url = URL(fileURLWithPath: areaFilename)
    var destinationExtension: String
    switch url.pathExtension.lowercased() {
    case "wlx": destinationExtension = "wld"
    case "mox": destinationExtension = "mob"
    case "obx": destinationExtension = "obj"
    default:
        print("invalid source file extension, unable to deduce output filename")
        exit(1)
    }
    destinationFilename = url.deletingPathExtension()
        .appendingPathExtension(destinationExtension)
        .path
}

if !silent && !brief {
    print("Loading definitions: \(definitionsFilename!)")
}
let definitions: Definitions
do {
    definitions = try Definitions(filename: definitionsFilename!)
} catch {
    print("While parsing definitions:\n" +
        "\(definitionsFilename!): \(error)")
    exit(1)
}

if !silent && !brief {
    print("Loading areas")
}
let areas = Areas(definitions: definitions)
do {
    try areas.load(filename: areaFilename)
} catch {
    print("While loading areas:\n" +
        "\(areaFilename):\(error)")
    exit(1)
}

if !silent && !brief {
    print("Postprocessing areas")
}
do {
    try Postprocess.run(areas: areas)
} catch {
    print("While postprocessing areas:\n" +
        "\(areaFilename): \(error)")
    exit(1)
}

if !silent && !brief {
    print("Saving simplified format: \(destinationFilename!)")
}
let generator = SimpleAreaFormatGenerator(areas: areas)
do {
    try generator.save(toFileNamed: destinationFilename!)
} catch {
    print("While saving simplified version of \(areaFilename): \(error)")
    exit(1)
}

if !silent {
    print("Converted '\(areaFilename)' to '\(destinationFilename!)'")
}
