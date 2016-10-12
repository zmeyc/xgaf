// XGAF file format parser for Swift.
// (c) 2016 Andrey Fidrya. MIT license. See LICENSE for more information.

import Foundation

let wordCharacters = CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "/;:()[]=")).inverted

extension Scanner {
    
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
                guard !skipString("\n") else { continue }

                guard skipUpTo("\n") else { return }
                skipString("\n")
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
}
