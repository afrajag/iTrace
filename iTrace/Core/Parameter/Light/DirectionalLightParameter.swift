//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class DirectionalLightParameter: LightParameter {
    static let PARAM_SOURCE: String = "source"
    static let PARAM_DIRECTION: String = "dir"
    static let PARAM_RADIUS: String = "radius"

    var src: Point3?
    var dir: Vector3?
    var radiance: Color?
    var r: Float = 0.0

    private enum CodingKeys: String, CodingKey {
        case src
        case dir
        case radiance
        case r
    }

    init(_ name: String) {
        super.init()
        
        self.name = name
        
        self.type = ParameterType.TYPE_DIRECTIONAL_LIGHT
        
        initializable = true
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
  
        self.name = name
        
        self.type = ParameterType.TYPE_DIRECTIONAL_LIGHT
        
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            src = try container.decode(Point3.self, forKey: .src)
            dir = try container.decode(Vector3.self, forKey: .dir)
            radiance = try container.decode(Color.self, forKey: .radiance)
            r = try container.decode(Float.self, forKey: .r)
            
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
        
        try container.encode(src, forKey: .src)
        try container.encode(dir, forKey: .dir)
        try container.encode(radiance, forKey: .radiance)
        try container.encode(r, forKey: .r)
    }
    
    override func setup() {
        // failed decode check
        if !initializable {
            UI.printError(.SCENE, "Error setting up: \(name) of type \(type!.rawValue)")
            return
        }
        
        API.shared.parameter(Self.PARAM_SOURCE, src!)
        API.shared.parameter(Self.PARAM_DIRECTION, dir!)
        API.shared.parameter(Self.PARAM_RADIUS, r)
        API.shared.parameter(Self.PARAM_RADIANCE, nil, radiance!.getRGB())

        API.shared.light(name, Self.TYPE_DIRECTIONAL)
    }
}
