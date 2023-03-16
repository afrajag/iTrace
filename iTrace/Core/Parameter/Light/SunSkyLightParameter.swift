//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class SunSkyLightParameter: LightParameter {
    static let PARAM_TURBIDITY: String = "turbidity"
    static let PARAM_SUN_DIRECTION: String = "sundir"
    static let PARAM_EAST: String = "east"
    static let PARAM_UP: String = "up"
    static let PARAM_GROUND_EXTENDSKY: String = "ground.extendsky"
    static let PARAM_GROUND_COLOR: String = "ground.color"

    var up: Vector3?
    var east: Vector3?
    var sunDirection: Vector3?
    var turbidity: Float = 0.0
    var samples: Int32 = 0
    var extendSky: Bool = false
    var groundColor: Color?

    private enum CodingKeys: String, CodingKey {
        case up
        case east
        case sunDirection
        case turbidity
        case samples
        case extendSky
        case groundColor
    }
 
    init(_ name: String) {
        super.init()
        
        self.name = name
        
        self.type = ParameterType.TYPE_SUNSKY
        
        initializable = true
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)

        self.name = name
        
        self.type = ParameterType.TYPE_SUNSKY
        
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            up = try container.decode(Vector3.self, forKey: .up)
            east = try container.decode(Vector3.self, forKey: .east)
            sunDirection = try container.decode(Vector3.self, forKey: .sunDirection)
            turbidity = try container.decodeIfPresent(Float.self, forKey: .turbidity) ?? 0.0
            samples = try container.decodeIfPresent(Int32.self, forKey: .samples) ?? 0
            extendSky = try container.decodeIfPresent(Bool.self, forKey: .extendSky) ?? false
            groundColor = try container.decodeIfPresent(Color.self, forKey: .groundColor)
            
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
        
        try container.encode(up, forKey: .up)
        try container.encode(east, forKey: .east)
        try container.encode(sunDirection, forKey: .sunDirection)
        try container.encode(turbidity, forKey: .turbidity)
        try container.encode(samples , forKey: .samples)
        try container.encode(extendSky, forKey: .extendSky)
        try container.encode(groundColor, forKey: .groundColor)
    }
    
    override func setup() {
        // failed decode check
        if !initializable {
            UI.printError(.SCENE, "Error setting up: \(name) of type \(type!.rawValue)")
            return
        }
        
        API.shared.parameter(Self.PARAM_UP, up!)
        API.shared.parameter(Self.PARAM_EAST, east!)
        API.shared.parameter(Self.PARAM_SUN_DIRECTION, sunDirection!)
        API.shared.parameter(Self.PARAM_TURBIDITY, turbidity)
        API.shared.parameter(Self.PARAM_SAMPLES, samples)
        API.shared.parameter(Self.PARAM_GROUND_EXTENDSKY, extendSky)

        if groundColor != nil {
            API.shared.parameter(Self.PARAM_GROUND_COLOR, nil, groundColor!.getRGB())
        }

        API.shared.light(name, Self.TYPE_SUNSKY)
    }
}
