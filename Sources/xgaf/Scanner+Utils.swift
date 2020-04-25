// XGAF file format parser for Swift.
// (c) 2016 Andrey Fidrya. MIT license. See LICENSE for more information.

import Foundation

#if os(Linux) || os(Windows)
// CharacterSet.union does not work in SwiftFoundation
let wordCharacters: CharacterSet = {
    var c = CharacterSet.whitespacesAndNewlines
    c.insert(charactersIn: "/;:()[]=")
    c.invert()
    return c
}()
#else
let wordCharacters = CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "/;:()[]=")).inverted
#endif

extension Scanner {
    public func skipString(_ string: String) -> Bool {
        #if true
        return scanString(string) != nil
        #else
        let utf16 = self.string.utf16
        let startOffset = skippingCharacters(startingAt: scanLocation, in: utf16)
        let toSkip = string.utf16
        let toSkipCount = toSkip.count
        let fromIndex = utf16.index(utf16.startIndex, offsetBy: startOffset)
        if let toIndex = utf16.index(fromIndex, offsetBy: toSkipCount, limitedBy: utf16.endIndex),
                utf16[fromIndex..<toIndex].elementsEqual(toSkip) {
            scanLocation = toIndex.encodedOffset
            return true
        }
        return false
        #endif
    }
    
    func skipping(_ characters: CharacterSet?, closure: () throws->()) throws {
        let previous = charactersToBeSkipped
        defer { charactersToBeSkipped = previous }
        charactersToBeSkipped = characters
        try closure()
    }
    
    func skipComments() throws {
        while true {
            if skipString(";") {
                let previousCharactersToBeSkipped = charactersToBeSkipped
                charactersToBeSkipped = nil
                defer { charactersToBeSkipped = previousCharactersToBeSkipped }
                
                // If at "\n" already, do nothing
                //guard !skipString("\n") else { continue }
                //guard !skipString("\r\n") else { continue }
                guard let cu = peekUtf16CodeUnit(),
                    cu != 10 && cu != 13 else { continue }

                guard skipUpToCharacters(from: CharacterSet.newlines) else {
                    // No more newlines, skip until the end of text
                    scanLocation = string.utf16.count
                    return
                }
                // No: parser will expect field separator
                //if !skipString("\n") {
                //    skipString("\r\n")
                //}
            } else if skipString("/*") {
                guard skipUpTo("*/") else {
                    throw ParseError(kind: .unterminatedComment, scanner: self)
                }
                skipString("*/")
            } else {
                return
            }
        }
    }
    
    func scanWord() -> String? {
        //return scanUpToCharacters(from: CharacterSet.whitespacesAndNewlines)
        return scanCharacters(from: wordCharacters)
    }
    
    func peekUtf16CodeUnit() -> UTF16.CodeUnit? {
        let originalScanLocation = scanLocation
        defer { scanLocation = originalScanLocation }
        
        let originalCharactersToBeSkipped = charactersToBeSkipped
        defer { charactersToBeSkipped = originalCharactersToBeSkipped }
        
        if let characters = charactersToBeSkipped {
            charactersToBeSkipped = nil
            let _ = scanCharacters(from: characters)
        }
        
        guard scanLocation < string.utf16.count else { return nil }
        let index = string.utf16.index(string.utf16.startIndex, offsetBy: scanLocation)
        return string.utf16[index]
    }
    
    public var lineBeingParsed: String {
        let targetLine = self.line()
        var currentLine = 1
        var line = ""
        line.reserveCapacity(256)
        for character in string {
            if currentLine > targetLine {
                break
            }
        
            if character == "\n" || character == "\r\n" {
                currentLine += 1
                continue
            }
        
            if currentLine == targetLine {
                line.append(character)
            }
        }
        return line
    }
    
    // Very slow, do not in use in loops
    public func line() -> Int {
        var newLinesCount = 0
        parsedText.forEach {
            if $0 == "\n" || $0 == "\r\n" {
                newLinesCount += 1
            }
        }
        return 1 + newLinesCount
    }
    
    // Very slow, do not in use in loops
    public func column() -> Int {
        let text = parsedText
        if let range = text.range(of: "\n", options: .backwards) {
            return text.distance(from: range.upperBound, to: text.endIndex) + 1
        }
        return parsedText.count + 1
    }
    
    public func skipUpTo(_ string: String) -> Bool {
         return scanUpTo(string) != nil
    }
    
    @discardableResult
    public func skipUpToCharacters(from set: CharacterSet) -> Bool {
         return scanUpToCharacters(from: set) != nil
    }
    
    public var parsedText: Substring {
        guard let index = currentCharacterIndex else { return "" }
        return string[..<index]
    }

    public var textToParse: Substring {
        guard let index = currentCharacterIndex else { return "" }
        return string[index...]
    }
    
    #if os(Linux) || os(Windows)
    public func scanUpTo(_ string: String) -> String? {
        return scanUpToString(string)
    }
    #elseif os(OSX)
    public func scanUpTo(_ string: String) -> String? {
        var result: NSString?
        guard scanUpTo(string, into: &result) else { return nil }
        return result as String?
    }
    #endif
    
    private var currentCharacterIndex: String.Index? {
        let utf16 = string.utf16
        guard let to16 = utf16.index(utf16.startIndex, offsetBy: scanLocation, limitedBy: utf16.endIndex),
            let to = String.Index(to16, within: string) else {
                return nil
        }
        // to is a String.CharacterView.Index
        return to
    }
}
