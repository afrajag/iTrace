//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class FileMeshParameter: GeometryParameter {
    var filename: String?
    var smoothNormals: Bool = false

    private enum CodingKeys: String, CodingKey {
        case filename
        case smoothNormals = "smooth_normals"
    }
    
    init(_ name: String) {
        super.init()
        
        self.name = name
        
        self.type = ParameterType.TYPE_FILE_MESH
        
        initializable = true
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        
        self.name = name
        
        self.type = ParameterType.TYPE_FILE_MESH
        
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            filename = try container.decode(String.self, forKey: .filename)
            smoothNormals = try container.decodeIfPresent(Bool.self, forKey: .smoothNormals) ?? false
            
            initializable = true
        } catch let DecodingError.dataCorrupted(context) {
            UI.printError(.SCENE, context.debugDescription)
        } catch let DecodingError.keyNotFound(key, context) {
            UI.printError(.SCENE, "[type: \(type!.rawValue)] - Key '\(key.stringValue)' not found at path: \(context.codingPath.reduce("") { $0 + "/" + $1.stringValue })")
        } catch let DecodingError.valueNotFound(_, context) {
            UI.printError(.SCENE, "[type: \(type!.rawValue)] - Value not found at path: \(context.codingPath.reduce("") { $0 + "/" + $1.stringValue })")
        } catch let DecodingError.typeMismatch(typeMismatch, context)  {
            UI.printError(.SCENE, "[type: \(type!.rawValue)] - Type '\(typeMismatch)' mismatch at path: \(context.codingPath.reduce("") { $0 + "/" + $1.stringValue })")
        } catch {
            UI.printError(.SCENE, error.localizedDescription)
        }
    }

    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(filename, forKey: .filename)
        try container.encodeIfPresent(smoothNormals, forKey: .smoothNormals)
    }
    
    override func setup() {
        // failed decode check
        if !initializable {
            UI.printError(.SCENE, "Error setting up: \(name) of type \(type!.rawValue)")
            return
        }
        
        super.setup()

        API.shared.parameter("filename", filename!)
        API.shared.parameter("smooth_normals", smoothNormals)
        API.shared.geometry(name, Self.TYPE_FILE_MESH)

        setupInstance()
    }
}
