//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class ImageBasedLightParameter: LightParameter {
    static let PARAM_CENTER: String = "center"
    static let PARAM_UP: String = "up"
    static let PARAM_FIXED: String = "fixed"
    static let PARAM_TEXTURE: String = "texture"
    static let PARAM_LOW_SAMPLES: String = "lowsamples"

    var samples: Int32 = 0
    var lowSamples: Int32 = 0
    var texture: String = ""
    var center: Vector3?
    var up: Vector3?
    var fixed: Bool = false

    private enum CodingKeys: String, CodingKey {
        case samples
        case lowSamples
        case texture
        case center
        case up
        case fixed
    }
    
    init(_ name: String) {
        super.init()
        
        self.name = name
        
        self.type = ParameterType.TYPE_IMAGE_BASED_LIGHT
        
        initializable = true
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        
        self.name = name
        
        self.type = ParameterType.TYPE_IMAGE_BASED_LIGHT
        
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            samples = try container.decode(Int32.self, forKey: .samples)
            lowSamples = try container.decode(Int32.self, forKey: .lowSamples)
            texture = try container.decode(String.self, forKey: .texture)
            center = try container.decode(Vector3.self, forKey: .center)
            up = try container.decode(Vector3.self, forKey: .up)
            fixed = try container.decode(Bool.self, forKey: .fixed)
            
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
        try container.encode(lowSamples, forKey: .lowSamples)
        try container.encode(texture, forKey: .texture)
        try container.encode(center, forKey: .center)
        try container.encode(up, forKey: .up)
        try container.encode(fixed, forKey: .fixed)
    }
    
    override func setup() {
        // failed decode check
        if !initializable {
            UI.printError(.SCENE, "Error setting up: \(name) of type \(type!.rawValue)")
            return
        }
        
        API.shared.parameter(Self.PARAM_TEXTURE, texture)
        API.shared.parameter(Self.PARAM_CENTER, center!)
        API.shared.parameter(Self.PARAM_UP, up!)
        API.shared.parameter(Self.PARAM_FIXED, fixed)
        API.shared.parameter(Self.PARAM_SAMPLES, samples)

        if lowSamples == 0 {
            API.shared.parameter(Self.PARAM_LOW_SAMPLES, samples)
        }

        API.shared.light(name, Self.TYPE_IMAGE_BASED)
    }
}
