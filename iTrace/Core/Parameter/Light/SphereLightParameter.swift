//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class SphereLightParameter: LightParameter {
    static let PARAM_CENTER: String = "center"
    static let PARAM_RADIUS: String = "radius"

    var radiance: Color?
    var numSamples: Int32 = 0
    var center: Point3?
    var radius: Float = 0.0

    private enum CodingKeys: String, CodingKey {
        case radiance
        case numSamples
        case center
        case radius
    }

    init(_ name: String) {
        super.init()
        
        self.name = name
        
        self.type = ParameterType.TYPE_SPHERE_LIGHT
        
        initializable = true
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        
        self.name = name
        
        self.type = ParameterType.TYPE_SPHERE_LIGHT
        
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            radiance = try container.decode(Color.self, forKey: .radiance)
            numSamples = try container.decode(Int32.self, forKey: .numSamples)
            center = try container.decode(Point3.self, forKey: .center)
            radius = try container.decode(Float.self, forKey: .radius)
            
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
        
        try container.encode(radiance, forKey: .radiance)
        try container.encode(numSamples, forKey: .numSamples)
        try container.encode(center, forKey: .center)
        try container.encode(radius, forKey: .radius)
    }
    
    override func setup() {
        // failed decode check
        if !initializable {
            UI.printError(.SCENE, "Error setting up: \(name) of type \(type!.rawValue)")
            return
        }
        
        API.shared.parameter(Self.PARAM_RADIANCE, nil, radiance!.getRGB())
        API.shared.parameter(Self.PARAM_CENTER, center!)
        API.shared.parameter(Self.PARAM_RADIUS, radius)
        API.shared.parameter(Self.PARAM_SAMPLES, numSamples)

        API.shared.light(name, Self.TYPE_SPHERE)
    }
}
