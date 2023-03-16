//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class IrrCacheGIParameter: GlobalIlluminationParameter {
    static let PARAM_TOLERANCE: String = "gi.irr-cache.tolerance"
    static let PARAM_SAMPLES: String = "gi.irr-cache.samples"
    static let PARAM_MIN_SPACING: String = "gi.irr-cache.min_spacing"
    static let PARAM_MAX_SPACING: String = "gi.irr-cache.max_spacing"
    static let PARAM_GLOBAL_EMIT: String = "gi.irr-cache.gmap.emit"
    static let PARAM_GLOBAL: String = "gi.irr-cache.gmap"
    static let PARAM_GLOBAL_GATHER: String = "gi.irr-cache.gmap.gather"
    static let PARAM_GLOBAL_RADIUS: String = "gi.irr-cache.gmap.radius"

    var samples: Int32 = 0
    var tolerance: Float = 0.0
    var minSpacing: Float = 0.0
    var maxSpacing: Float = 0.0
    var global: IlluminationParameter?

    private enum CodingKeys: String, CodingKey {
        case samples
        case tolerance
        case minSpacing
        case maxSpacing
        case global
    }
    
    override init() {
        super.init()
        
        self.name = Self.TYPE_IRR_CACHE
        
        self.type = ParameterType.TYPE_IRRADIANCE_CACHE_GI
        
        initializable = true
    }

    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        
        self.name = name
        
        self.type = ParameterType.TYPE_IRRADIANCE_CACHE_GI
        
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            samples = try container.decode(Int32.self, forKey: .samples)
            tolerance = try container.decode(Float.self, forKey: .tolerance)
            minSpacing = try container.decode(Float.self, forKey: .minSpacing)
            maxSpacing = try container.decode(Float.self, forKey: .maxSpacing)
            global = try container.decode(IlluminationParameter.self, forKey: .global)
            
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
        // no super calling because we wont 'name' attribute to be present
        //try super.encode(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(samples, forKey: .samples)
        try container.encode(tolerance, forKey: .tolerance)
        try container.encode(minSpacing, forKey: .minSpacing)
        try container.encode(maxSpacing, forKey: .maxSpacing)
        try container.encode(global, forKey: .global)
    }
    
    override func setup() {
        // failed decode check
        if !initializable {
            UI.printError(.SCENE, "Error setting up: \(name) of type \(type!.rawValue)")
            return
        }
        
        API.shared.parameter(Self.PARAM_ENGINE, Self.TYPE_IRR_CACHE)
        API.shared.parameter(Self.PARAM_SAMPLES, samples)
        API.shared.parameter(Self.PARAM_TOLERANCE, tolerance)
        API.shared.parameter(Self.PARAM_MIN_SPACING, minSpacing)
        API.shared.parameter(Self.PARAM_MAX_SPACING, maxSpacing)

        if global != nil {
            API.shared.parameter(Self.PARAM_GLOBAL_EMIT, global!.emit)
            API.shared.parameter(Self.PARAM_GLOBAL, global!.map)
            API.shared.parameter(Self.PARAM_GLOBAL_GATHER, global!.gather)
            API.shared.parameter(Self.PARAM_GLOBAL_RADIUS, global!.radius)
        }

        super.setup()
    }
}
