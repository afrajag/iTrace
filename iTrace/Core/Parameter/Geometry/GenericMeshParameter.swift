//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class GenericMeshParameter: GeometryParameter {
    var points: [Float]?
    var triangles: [Int32]?
    var normals: [Float]?
    var uvs: [Float]?
    var faceVaryingNormals: Bool? = false
    var faceVaryingTextures: Bool? = false
    var faceShaders: [Int32]?

    private enum CodingKeys: String, CodingKey {
        case points
        case triangles
        case normals
        case uvs
        case faceVaryingNormals = "face_varying_normals"
        case faceVaryingTextures = "face_varying_textures"
        case faceShaders
    }
    
    init(_ name: String) {
        super.init()
        
        self.name = name
        
        self.type = ParameterType.TYPE_GENERIC_MESH
        
        initializable = true
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        
        self.name = name
        
        self.type = ParameterType.TYPE_GENERIC_MESH
        
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            points = try container.decode([Float].self, forKey: .points)
            normals = try container.decodeIfPresent([Float].self, forKey: .normals)
            uvs = try container.decodeIfPresent([Float].self, forKey: .uvs)
            triangles = try container.decode([Int32].self, forKey: .triangles)
            
            faceVaryingNormals = try container.decodeIfPresent(Bool.self, forKey: .faceVaryingNormals) ?? false
            faceVaryingTextures = try container.decodeIfPresent(Bool.self, forKey: .faceVaryingTextures) ?? false
            faceShaders = try container.decodeIfPresent([Int32].self, forKey: .faceShaders)
            
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
        
        try container.encode(points, forKey: .points)
        try container.encode(normals, forKey: .normals)
        try container.encode(uvs, forKey: .uvs)
        try container.encode(triangles, forKey: .triangles)
        
        try container.encode(faceVaryingNormals, forKey: .faceVaryingNormals)
        try container.encode(faceVaryingTextures, forKey: .faceVaryingTextures)
        try container.encode(faceShaders, forKey: .faceShaders)
    }
    
    override func setup() {
        // failed decode check
        if !initializable {
            UI.printError(.SCENE, "Error setting up: \(name) of type \(type!.rawValue)")
            return
        }
        
        super.setup()

        API.shared.parameter("triangles", triangles!)
        API.shared.parameter("points", "point", "vertex", points!)

        if normals != nil {
            if !faceVaryingNormals! {
                API.shared.parameter("normals", "vector", "vertex", normals!)
            } else {
                API.shared.parameter("normals", "vector", "facevarying", normals!)
            }
        }

        if uvs != nil {
            if !faceVaryingTextures! {
                API.shared.parameter("uvs", "texcoord", "vertex", uvs!)
            } else {
                API.shared.parameter("uvs", "texcoord", "facevarying", uvs!)
            }
        }

        if faceShaders != nil {
            API.shared.parameter("faceshaders", faceShaders!)
        }

        API.shared.geometry(name, Self.TYPE_TRIANGLE_MESH)

        setupInstance()
    }
}
