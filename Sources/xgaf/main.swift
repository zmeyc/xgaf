// XGAF file format parser for Swift.
// (c) 2016 Andrey Fidrya. MIT license. See LICENSE for more information.

import Foundation

// For setlocale()
#if os(OSX)
    import Darwin
#elseif os(Linux) || os(Windows)
    import Glibc
#endif

let silent = true
let brief = true
var definitionsFilename: String?
var areaFilename: String
var destinationFilename: String?

setlocale(LC_ALL, "")

let arguments = CommandLine.arguments

var toExtendedFormat = false

var initialPositionalIndex = 1
if (arguments.count >= 2 && arguments[1] == "-e") {
    toExtendedFormat = true
    initialPositionalIndex += 1
}

switch arguments.count - initialPositionalIndex {
case 3:
    definitionsFilename = arguments[initialPositionalIndex + 2]
    fallthrough
case 2:
    destinationFilename = arguments[initialPositionalIndex + 1]
    fallthrough
case 1:
    areaFilename = arguments[initialPositionalIndex]
default:
    print("Usage:\n" +
        "xgaf [-e] file.wlx [file.wld] [xgaf.txt]")
    exit(1)
}

if definitionsFilename == nil {
    #if CYGWIN
    definitionsFilename = try URL(fileURLWithPath: arguments[0])
	.deletingLastPathComponent()
        .appendingPathComponent("xgaf.txt", isDirectory: false)
        .path
    #else
    definitionsFilename = URL(fileURLWithPath: arguments[0])
	.deletingLastPathComponent()
        .appendingPathComponent("xgaf.txt", isDirectory: false)
        .path
    #endif
}

if destinationFilename == nil {
    let url = URL(fileURLWithPath: areaFilename)
    var destinationExtension: String
    #if CYGWIN
    let fileExtension = url.pathExtension?.lowercased() ?? ""
    #else
    let fileExtension = url.pathExtension.lowercased()
    #endif
    switch fileExtension {
    case "wlx": destinationExtension = "wld"
    case "mox": destinationExtension = "mob"
    case "obx": destinationExtension = "obj"
    case "wld": destinationExtension = "wlx"
    case "mob": destinationExtension = "mox"
    case "obj": destinationExtension = "obx"
    default:
        print("invalid source file extension, unable to deduce output filename")
        exit(1)
    }
    #if CYGWIN
    destinationFilename = try url.deletingPathExtension()
        .appendingPathExtension(destinationExtension)
        .path
    #else
    destinationFilename = url.deletingPathExtension()
        .appendingPathExtension(destinationExtension)
        .path
    #endif
}

if !silent && !brief {
    print("Loading definitions: \(definitionsFilename!)")
}
let definitions: Definitions
do {
    definitions = try Definitions(filename: definitionsFilename!)
} catch {
    print("While parsing definitions:\n" +
        "\(definitionsFilename!):\(error)")
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
        "\(areaFilename):\(error)")
    exit(1)
}

if !silent && !brief {
    print("Saving simplified format: \(destinationFilename!)")
}
let generator: AreaFormatGenerator = toExtendedFormat ?
    ExtendedAreaFormatGenerator(areas: areas) : SimpleAreaFormatGenerator(areas: areas)
do {
    try generator.save(toFileNamed: destinationFilename!)
} catch {
    print("While saving simplified version of \(areaFilename): \(error)")
    exit(1)
}

if !silent {
    print("Converted '\(areaFilename)' to '\(destinationFilename!)'")
}
