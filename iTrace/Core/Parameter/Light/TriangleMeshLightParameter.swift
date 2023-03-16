//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class TriangleMeshLightParameter: LightParameter {
    static let PARAM_POINTS: String = "points"
    static let PARAM_TRIANGLES: String = "triangles"

    var samples: Int32 = 0
    var radiance: Color?
    var points: [Float]?
    var triangles: [Int32]?

    private enum CodingKeys: String, CodingKey {
        case samples
        case radiance
        case points
        case triangles
    }
    
    init(_ name: String) {
        super.init()
        
        self.name = name
        
        self.type = ParameterType.TYPE_TRIANGLE_MESH
        
        initializable = true
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        
        self.name = name
        
        self.type = ParameterType.TYPE_TRIANGLE_MESH
        
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            samples = try container.decode(Int32.self, forKey: .samples)
            radiance = try container.decode(Color.self, forKey: .radiance)
            points = try container.decode([Float].self, forKey: .points)
            triangles = try container.decode([Int32].self, forKey: .triangles)
            
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
        
        try container.encode(samples, forKey: .samples)
        try container.encode(radiance, forKey: .radiance)
        try container.encode(points, forKey: .points)
        try container.encode(triangles, forKey: .triangles)
    }
    
    override func setup() {
        // failed decode check
        if !initializable {
            UI.printError(.SCENE, "Error setting up: \(name) of type \(type!.rawValue)")
            return
        }
        
        API.shared.parameter(Self.PARAM_RADIANCE, nil, radiance!.getRGB())
        API.shared.parameter(Self.PARAM_SAMPLES, samples)
        API.shared.parameter(Self.PARAM_POINTS, "point", "vertex", points!)
        API.shared.parameter(Self.PARAM_TRIANGLES, triangles!)

        API.shared.light(name, Self.TYPE_TRIANGLE_MESH)
    }
}
