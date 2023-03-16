//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

import Foundation

enum ObjectScannerError: Error {
    case UnreadableData(error: String)
    case InvalidData(error: String)
}

// Scanner for .obj and .mtl files
class ObjectScanner {
    var dataAvailable: Bool {
        return scanner.isAtEnd == false
    }

    let scanner: StringScanner
    let source: String
    
    init(source: String) {
        scanner = StringScanner(source)
        
        self.source = source
        
        //scanner.charactersToBeSkipped = .whitespaces
    }

    func moveToNextLine() {
        try! scanner.scan(upTo: .newlines)
        try! scanner.skip(charactersIn: .whitespacesAndNewlines)
        //scanner.scanUpToCharacters(from: .newlines)
        //scanner.scanCharacters(from: .whitespacesAndNewlines)
    }

    // Read from current scanner location up to the next
    // whitespace
    func readMarker() -> String? {
        //return scanner.scanUpToCharacters(from: .whitespaces)
        return try! scanner.scan(upTo: .whitespaces)
    }

    // Read from the current scanner location till the end of the line
    @discardableResult
    func readLine() -> String? {
       //return scanner.scanUpToCharacters(from: .newlines)
        return try! scanner.scan(upTo: .newlines)
    }

    // Read a single Int32 value
    func readInt() throws -> Int32 {
        //let value: Int32? = scanner.scanInt32()
        try scanner.scan(untilIn: .whitespaces)
        let value: Int32? = Int32(try scanner.scanInt())
        
        guard (value != nil) else {
            throw ObjectScannerError.InvalidData(error: "Invalid Int value")
        }
        
        return value!
    }

    // Read a single Double value
    func readDouble() throws -> Double {
        //let value: Double? = scanner.scanDouble()
        try scanner.scan(untilIn: .whitespaces)
        let value: Double? = Double(try scanner.scanFloat())
        
        guard (value != nil) else {
            throw ObjectScannerError.InvalidData(error: "Invalid Double value")
        }
        
        return value!
    }

    func readString() throws -> String {
        //let string: String? = scanner.scanUpToCharacters(from: .whitespacesAndNewlines)
        try scanner.scan(untilIn: .whitespaces)
        let string: String? = try scanner.scan(upTo: .whitespacesAndNewlines)
        
        guard (string != nil) else {
            throw ObjectScannerError.InvalidData(error: "Invalid String value")
        }
        
        return string!
    }

    func readTokens() throws -> [String] {
        
        var result: [String] = []

        while !scanner.isAtEnd  {
            //let string = scanner.scanUpToCharacters(from: .whitespacesAndNewlines)
            let string: String? = try scanner.scan(upTo: .whitespacesAndNewlines)
            
            if string != nil {
                result.append(string!)
            }
        }
        
        return result
    }

    func reset() {
        //scanner.scanLocation = 0
        scanner.reset()
    }
}

// Scanner with specific logic for .obj files
// Inherits common logic from Scanner
final class ObjectParser: ObjectScanner {
    // Parses face declarations
    //
    // Example:
    //
    // f v1/vt1/vn1 v2/vt2/vn2 ....
    //
    // Possible cases:
    //
    // Vertex indices
    // f v1 v2 v3
    //
    // Vertex texture coordinate indices
    // f v1/vt1 v2/vt2 v3/vt3
    //
    // Vertex normal indices with texture coordinate indices
    // f v1/vt1/vn1 v2/vt2/vn2 v3/vt3/vn3
    //
    // Vertex normal indices without texture coordinate indices
    // f v1//vn1 v2//vn2 v3//vn3
    func readFace() throws -> [VertexIndex]? {
        var result: [VertexIndex] = []
        
        while true {
            var v, vn, vt: Int32?
            var tmp: Int32? = -1

            //tmp = scanner.scanInt()
            tmp = try? readInt()
            
            guard (tmp != nil) else {
                break
            }
            
            v = tmp

            //let next = scanner.scanString("/")
            let next = try? scanner.scan(upTo: "/")

            if next != nil && !next!.isEmpty {
            //if (next != nil) {
                //tmp = scanner.scanInt()
                tmp = try? readInt()
                
                if (tmp != nil) { // v1/vt1/
                    vt = tmp!
                }
                
                //guard (scanner.scanString("/") != nil) else {
                let next = try? scanner.scan(upTo: "/")

                if next != nil && !next!.isEmpty {
                //if (next != nil) {
                    throw ObjectLoaderError.UnexpectedFileFormat(error: "Lack of / when parsing face definition, each vertex index should contain 2 /")
                }

                //tmp = scanner.scanInt()
                tmp = try? readInt()
                
                if (tmp != nil) {
                    vn = tmp!
                }
            }
            
            result.append(VertexIndex(vIndex: v, nIndex: vn, tIndex: vt))
        }

        return result
    }

    // Read 3 (optionally 4) space separated double values from the scanner
    // The fourth w value defaults to 1.0 if not present
    // Example:
    //  19.2938 1.29019 0.2839
    //  1.29349 -0.93829 1.28392 0.6
    //
    func readVertex() throws -> [Double]? {
        var x = Double.infinity
        var y = Double.infinity
        var z = Double.infinity
        var w = 1.0

        var tmp: Double?
        
        //tmp = scanner.scanDouble()
        tmp = try? readDouble()
        
        guard (tmp != nil) else {
            throw ObjectScannerError.UnreadableData(error: "Bad vertex definition missing X component")
        }
        
        x = tmp!
        
        //tmp = scanner.scanDouble()
        tmp = try? readDouble()
        
        guard (tmp != nil) else {
            throw ObjectScannerError.UnreadableData(error: "Bad vertex definition missing Y component")
        }
        
        y = tmp!
        
        //tmp = scanner.scanDouble()
        tmp = try? readDouble()
        
        guard (tmp != nil) else {
            throw ObjectScannerError.UnreadableData(error: "Bad vertex definition missing Z component")
        }
        
        z = tmp!
        
        //tmp = scanner.scanDouble()
        tmp = try? readDouble()
        
        if (tmp != nil) {
            w = tmp!
        }

        return [x, y, z, w]
    }

    // Read 1, 2 or 3 texture coords from the scanner
    func readTextureCoord() -> [Double]? {
        var u = Double.infinity
        var v = 0.0
        var w = 0.0

        var tmp: Double?
        
        //tmp = scanner.scanDouble()
        tmp = try? readDouble()
        
        guard (tmp != nil) else {
            return nil
        }
        
        u = tmp!
        
        //tmp = scanner.scanDouble()
        tmp = try? readDouble()
        
        if (tmp != nil) {
            v = tmp!
        }

        //tmp = scanner.scanDouble()
        tmp = try? readDouble()
        
        if (tmp != nil) {
            w = tmp!
        }
        
        return [u, v, w]
    }
}

final class MaterialParser: ObjectScanner {
    // Parses color declaration
    //
    // Example:
    //
    //     0.2432 0.123 0.12
    //
    func readColor() throws -> Color {
        var r = Double.infinity
        var g = Double.infinity
        var b = Double.infinity

        var tmp: Double?
        
        //tmp = scanner.scanDouble()
        tmp = Double(try! scanner.scanFloat())
        
        guard (tmp != nil) else {
            throw ObjectScannerError.UnreadableData(error: "Bad color definition: missing R component")
        }
        
        r = tmp!
        
        //tmp = scanner.scanDouble()
        tmp = Double(try! scanner.scanFloat())
        
        guard (tmp != nil) else {
            throw ObjectScannerError.UnreadableData(error: "Bad color definition: missing G component")
        }
        
        g = tmp!
        
        //tmp = scanner.scanDouble()
        tmp = Double(try! scanner.scanFloat())
        
        guard (tmp != nil) else {
            throw ObjectScannerError.UnreadableData(error: "Bad color definition: missing B component")
        }
        
        b = tmp!

        if r < 0.0 || r > 1.0 {
            throw ObjectScannerError.InvalidData(
                error: "Bad R value \(r). Should be in range 0.0 to 1.0"
            )
        }

        if g < 0.0 || g > 1.0 {
            throw ObjectScannerError.InvalidData(
                error: "Bad G value \(g). Should be in range 0.0 to 1.0"
            )
        }

        if b < 0.0 || b > 1.0 {
            throw ObjectScannerError.InvalidData(
                error: "Bad B value \(b). Should be in range 0.0 to 1.0"
            )
        }

        return Color(Float(r), Float(g), Float(b))
    }
}
