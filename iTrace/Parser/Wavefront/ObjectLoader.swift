//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

import Foundation
import PathKit

enum ObjectLoaderError: Error {
    case UnexpectedFileFormat(error: String)
}

final class ObjectLoader {
    // parsing state
    final class State {
        var objectName: String?
        var vertices: [VectorShape] = []
        var normals: [VectorShape] = []
        var textureCoords: [VectorShape] = []
        var faces: [[VertexIndex]] = []
        var material: Material?
    }

    static let commentMarker = "#"
    static let vertexMarker = "v"
    static let normalMarker = "vn"
    static let textureCoordMarker = "vt"
    static let objectMarker = "o"
    static let groupMarker = "g"
    static let faceMarker = "f"
    static let materialLibraryMarker = "mtllib"
    static let useMaterialMarker = "usemtl"

    let parser: ObjectParser
    let basePath: String
    var materialCache: [String: Material] = [:]

    let url: URL
    
    var state = State()
    /*
    var vertexCount = 0
    var normalCount = 0
    var textureCoordCount = 0
    var facesCount = 0
    */
    
    // Init an objloader with the
    // source of the .obj file as a string
    init(source: String, basePath: String) {
        parser = ObjectParser(source: source)
        
        self.basePath = basePath
        
        url = URL(fileURLWithPath: "")
    }

    init(_ url: URL) {
        parser = ObjectParser(source: "")
        
        self.basePath = ""
        
        self.url = url
    }
    
    func read() throws -> (state: State, shapes: [Shape]) {
        let t: TraceTimer = TraceTimer()
        
        t.start()
        
        /*
        let lines = try Data(contentsOf: url).withUnsafeBytes {
            return $0.split(separator: UInt8(ascii: "\n")).map { String(decoding: UnsafeRawBufferPointer(rebasing: $0), as: UTF8.self) }
        }.filter{!$0.isEmpty}
        */
        
        let lines = try! String(contentsOf: url).components(separatedBy: .newlines).filter{!$0.isEmpty}
        
        t.end()

        UI.printDetailed(.GEOM, "  * Splitting lines time:  \(t.toString())")
        
        var shapes: [Shape] = []
        
        resetState()

        t.start()
        
        var line_number = 0

        for m in lines {
            line_number += 1
            
            // double check empty lines
            if m.isEmpty {
                UI.printError(.GEOM, "Empty line")
                
                continue
            }
            
            // Read comment line
            if m.starts(with: "#") {
                continue
            }
            
            // Read 3 space separated double values
            // Example:
            //  19.2938 1.29019 0.2839
            //
            if m.starts(with: "vn") {
                let vn = m.components(separatedBy: .whitespacesAndNewlines).filter{!$0.isEmpty}.dropFirst().map { _tmp -> Double in
                    let tmp = _tmp.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard Double(tmp) != nil else {
                        UI.printError(.GEOM, "Error reading vertex normal: \(tmp) at line: \(line_number) - defaulting to 0.0")
                        
                        return 0.0
                    }
                    
                    return Double(tmp)!
                }

                guard vn.count == 3 else {
                    UI.printError(.GEOM, "Error reading vertex normal: '\(m)' at line: \(line_number)")
                    
                    continue
                }
                
                state.normals.append(vn)
                
                continue
            }

            // Read 2 (optionally 3) space separated double values
            // The third w value defaults to 1.0 if not present
            // Example:
            //  19.2938 1.29019
            //  1.29349 -0.93829 0.6
            //
            if m.starts(with: "vt") {
                //let vt = m.components(separatedBy: .whitespacesAndNewlines).filter{!$0.isEmpty}.dropFirst().map { Double($0.trimmingCharacters(in: .whitespacesAndNewlines))! }
                let vt = m.components(separatedBy: .whitespacesAndNewlines).filter{!$0.isEmpty}.dropFirst().map { _tmp -> Double in
                    let tmp = _tmp.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard Double(tmp) != nil else {
                        UI.printError(.GEOM, "Error reading vertex texture: \(tmp) at line: \(line_number) - defaulting to 0.0")
                        
                        return 0.0
                    }
                    
                    return Double(tmp)!
                }
                
                guard vt.count >= 2 && vt.count <= 3 else {
                    UI.printError(.GEOM, "Error reading vertex texture: '\(m)' at line: \(line_number)")
                    
                    continue
                }
                
                state.textureCoords.append(vt)
                
                continue
            }

            // Read 3 space separated double values
            // Example:
            //  19.2938 1.29019 0.2839
            //
            if m.starts(with: "v") {
                /*
                let v = Data(line[1...].utf8).withUnsafeBytes {
                    return $0.split(separator: UInt8(ascii: " ")).map { String(decoding: UnsafeRawBufferPointer(rebasing: $0), as: UTF8.self) }
                }.map { Double($0.trimmingCharacters(in: .whitespacesAndNewlines))! }
                */
                //let v = m.components(separatedBy: .whitespacesAndNewlines).filter{!$0.isEmpty}.dropFirst().map { Double($0.trimmingCharacters(in: .whitespacesAndNewlines))! }
                let v = m.components(separatedBy: .whitespacesAndNewlines).filter{!$0.isEmpty}.dropFirst().map { _tmp -> Double in
                    let tmp = _tmp.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard Double(tmp) != nil else {
                        UI.printError(.GEOM, "Error reading vertex: \(tmp) at line: \(line_number) - defaulting to 0.0")
                        
                        return 0.0
                    }

                    return Double(tmp)!
                }
                
                guard v.count == 3 else {
                    UI.printError(.GEOM, "Error reading vertex: '\(m)' at line: \(line_number)")
                    
                    continue
                }
                
                state.vertices.append(v)
                
                continue
            }
            
            /*
            if ObjectLoader.isObject(m) {
                state.objectName = parser.readLine()
                
                parser.moveToNextLine()
                
                continue
            }

            if ObjectLoader.isGroup(m) {
                if let s = buildShape() {
                    shapes.append(s)
                }

                let _vertices = state.vertices
                let _normals = state.normals
                let _textureCoords = state.textureCoords
                let _material = state.material
                
                state = State()
                
                state.vertices = _vertices
                state.normals = _normals
                state.textureCoords = _textureCoords
                state.material = _material
                
                state.objectName = try parser.readString()
                
                parser.moveToNextLine()
                
                continue
            }
            */
            
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
            if m.starts(with: "f") {
                let faces = m.components(separatedBy: .whitespacesAndNewlines).filter{!$0.isEmpty}.dropFirst().map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                
                var indices: [VertexIndex] = [VertexIndex]()
                
                for face in faces {
                    let indexes = face.components(separatedBy: "/").filter{!$0.isEmpty}.map { _tmp -> Int32 in
                        let tmp = _tmp.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard Int32(tmp) != nil else {
                            UI.printError(.GEOM, "Error reading face: \(tmp) at line: \(line_number) - defaulting to 0")
                            
                            return 0
                        }

                        return Int32(tmp)!
                    }
                    
                    if indexes.isEmpty {
                        indices.append(VertexIndex(vIndex: indexes[0], nIndex: nil, tIndex: nil))
                    } else if indexes.count == 2 {
                        if face.filter({ $0 == "/" }).count == 1 {
                            indices.append(VertexIndex(vIndex: indexes[0], nIndex: nil, tIndex: indexes[1]))
                        } else {
                            indices.append(VertexIndex(vIndex: indexes[0], nIndex: indexes[1], tIndex: nil))
                        }
                    } else {
                        indices.append(VertexIndex(vIndex: indexes[0], nIndex: indexes[1], tIndex: indexes[2]))
                    }
                }
                
                /*
                if (triangulate) {
                  size_t k;
                  size_t n = 0;

                  tinyobj_vertex_index_t i0 = f[0];
                  tinyobj_vertex_index_t i1;
                  tinyobj_vertex_index_t i2 = f[1];

                  assert(3 * num_f < TINYOBJ_MAX_FACES_PER_F_LINE);

                  for (k = 2; k < num_f; k++) {
                    i1 = i2;
                    i2 = f[k];
                    command->f[3 * n + 0] = i0;
                    command->f[3 * n + 1] = i1;
                    command->f[3 * n + 2] = i2;

                    command->f_num_verts[n] = 3;
                    n++;
                  }
                  command->num_f = 3 * n;
                  command->num_f_num_verts = n;

                }
                */
                
                state.faces.append(normalizeVertexIndices(indices))
                
                continue
            }

            /*
            if ObjectLoader.isMaterialLibrary(m) {
                let filenames = try parser.readTokens()
                
                try parseMaterialFiles(filenames)
                
                parser.moveToNextLine()
                
                continue
            }

            if ObjectLoader.isUseMaterial(m) {
                let materialName = try parser.readString()

                guard let material = materialCache[materialName] else {
                    throw ObjectLoaderError.UnexpectedFileFormat(error: "Material \(materialName) referenced before it was definited")
                }

                state.material = material
                
                parser.moveToNextLine()
                
                continue
            }
            */
        }

        if let s = buildShape() {
            shapes.append(s)
        }

        t.end()

        UI.printDetailed(.GEOM, "  * Parsing time:  \(t.toString())")
        
        return (state: state, shapes: shapes)
    }
    /*
    // Read the specified source.
    // This operation is singled threaded and
    // should not be invoked again before
    // the call has returned
    func read() throws -> [Shape] {
        var shapes: [Shape] = []
        resetState()

        do {
            while parser.dataAvailable {
                let marker = parser.readMarker()
    
                guard let m = marker, m.length > 0 else {
                    parser.moveToNextLine()
                    
                    continue
                }

                if ObjectLoader.isComment(m) {
                    parser.moveToNextLine()
                    
                    continue
                }

                if ObjectLoader.isVertex(m) {
                    if let v = try readVertex() {
                        state.vertices.append(v)
                    }

                    parser.moveToNextLine()
                    
                    continue
                }

                if ObjectLoader.isNormal(m) {
                    if let n = try readVertex() {
                        state.normals.append(n)
                    }

                    parser.moveToNextLine()
                    
                    continue
                }

                if ObjectLoader.isTextureCoord(m) {
                    if let vt = parser.readTextureCoord() {
                        state.textureCoords.append(vt)
                    }

                    parser.moveToNextLine()
                    
                    continue
                }

                if ObjectLoader.isObject(m) {
                    state.objectName = parser.readLine()
                    
                    parser.moveToNextLine()
                    
                    continue
                }

                if ObjectLoader.isGroup(m) {
                    if let s = buildShape() {
                        shapes.append(s)
                    }

                    let _vertices = state.vertices
                    let _normals = state.normals
                    let _textureCoords = state.textureCoords
                    let _material = state.material
                    
                    state = State()
                    
                    state.vertices = _vertices
                    state.normals = _normals
                    state.textureCoords = _textureCoords
                    state.material = _material
                    
                    state.objectName = try parser.readString()
                    
                    parser.moveToNextLine()
                    
                    continue
                }

                if ObjectLoader.isFace(m) {
                    if let indices = try parser.readFace() {
                        state.faces.append(normalizeVertexIndices(indices))
                    }

                    parser.moveToNextLine()
                    
                    continue
                }

                if ObjectLoader.isMaterialLibrary(m) {
                    let filenames = try parser.readTokens()
                    
                    try parseMaterialFiles(filenames)
                    
                    parser.moveToNextLine()
                    
                    continue
                }

                if ObjectLoader.isUseMaterial(m) {
                    let materialName = try parser.readString()

                    guard let material = materialCache[materialName] else {
                        throw ObjectLoaderError.UnexpectedFileFormat(error: "Material \(materialName) referenced before it was definited")
                    }

                    state.material = material
                    
                    parser.moveToNextLine()
                    
                    continue
                }

                parser.moveToNextLine()
            }

            if let s = buildShape() {
                shapes.append(s)
            }
            
            state = State()
        } catch let e {
            resetState()
            
            throw e
        }
        
        return shapes
    }
    */
    
    static func isComment(_ marker: String) -> Bool {
        return String(marker[0]) == commentMarker
    }

    static func isVertex(_ marker: String) -> Bool {
        return marker.length == 1 && String(marker[0]) == vertexMarker
    }

    static func isNormal(_ marker: String) -> Bool {
        return marker.length == 2 && marker[0..<2] == normalMarker
    }

    static func isTextureCoord(_ marker: String) -> Bool {
        return marker.length == 2 && marker[0..<2] == textureCoordMarker
    }

    static func isObject(_ marker: String) -> Bool {
        return marker.length == 1 && String(marker[0]) == objectMarker
    }

    static func isGroup(_ marker: String) -> Bool {
        return marker.length == 1 && String(marker[0]) == groupMarker
    }

    static func isFace(_ marker: String) -> Bool {
        return marker.length == 1 && String(marker[0]) == faceMarker
    }

    static func isMaterialLibrary(_ marker: String) -> Bool {
        return marker == materialLibraryMarker
    }

    static func isUseMaterial(_ marker: String) -> Bool {
        return marker == useMaterialMarker
    }

    func readVertex() throws -> [Double]? {
        do {
            return try parser.readVertex()
        } catch let ObjectScannerError.UnreadableData(error) {
            throw ObjectLoaderError.UnexpectedFileFormat(error: error)
        }
    }

    func resetState() {
        parser.reset()
        
        state = State()
        /*
        vertexCount = 0
        
        normalCount = 0
        
        textureCoordCount = 0
        */
    }

    func buildShape() -> Shape? {
        // FIXME: controllo solo che le faces siano > 0
        //if state.vertices.isEmpty && state.normals.isEmpty && state.textureCoords.isEmpty {
        if state.faces.isEmpty {
            return nil
        }

        let result = Shape(name: state.objectName, vertices: state.vertices, normals: state.normals, textureCoords: state.textureCoords, material: state.material, faces: state.faces)
        /*
        vertexCount += state.vertices.count
        normalCount += state.normals.count
        textureCoordCount += state.textureCoords.count
        */
        return result
    }

    func normalizeVertexIndices(_ unnormalizedIndices: [VertexIndex]) -> [VertexIndex] {
        return unnormalizedIndices.map {
            return VertexIndex(vIndex: ObjectLoader.normalizeIndex($0.vIndex, count: Int32(state.vertices.count)),
                               nIndex: ObjectLoader.normalizeIndex($0.nIndex, count: Int32(state.normals.count)),
                               tIndex: ObjectLoader.normalizeIndex($0.tIndex, count: Int32(state.textureCoords.count)))
        }
    }

    func parseMaterialFiles(_ filenames: [String]) throws {
        for filename in filenames {
            let fullPath = Path(filename).isAbsolute ? filename : Path(components: [basePath, filename]).string
            
            do {
                let fileContents = try String(contentsOfFile: fullPath, encoding: String.Encoding.utf8)
                
                let loader = MaterialLoader(source: fileContents as String, basePath: basePath)

                let materials = try loader.read()

                for material in materials {
                    materialCache[material.name] = material
                }

            } catch let MaterialLoadingError.UnexpectedFileFormat(msg) {
                throw ObjectLoaderError.UnexpectedFileFormat(error: msg)
            } catch {
                throw ObjectLoaderError.UnexpectedFileFormat(error: "Invalid material file at \(fullPath)")
            }
        }
    }

    static func normalizeIndex(_ index: Int32?, count: Int32) -> Int32? {
        guard let i = index else {
            return nil
        }

        if i > 0 {
            return i - 1
        }
        
        if i == 0 {
            return 0
        }

        return count + i /* negative value = relative */
    }
}
