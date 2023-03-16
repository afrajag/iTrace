//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class OverrideParameter: Parameter {
    static let PARAM_OVERRIDE_SHADER: String = "override.shader"
    static let PARAM_OVERRIDE_PHOTONS: String = "override.photons"

    static let TYPE_OVERRIDE: String = "override"
    
    var shader: String = ""
    var photons: Bool = false

    private enum CodingKeys: String, CodingKey {
        case shader
        case photons
    }
    
    override init() {
        super.init()
        
        self.name = Self.TYPE_OVERRIDE
        
        self.type = ParameterType.TYPE_OVERRIDE
        
        initializable = true
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        
        self.name = name
        
        self.type = ParameterType.TYPE_OVERRIDE
        
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            shader = try container.decode(String.self, forKey: .shader)
            photons = try container.decode(Bool.self, forKey: .photons)
            
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
        
        try container.encode(shader, forKey: .shader)
        try container.encode(photons, forKey: .photons)
    }
    
    override func setup() {
        // failed decode check
        if !initializable {
            UI.printError(.SCENE, "Error setting up: \(name) of type \(type!.rawValue)")
            return
        }
        
        if !shader.isEmpty {
            API.shared.parameter(Self.PARAM_OVERRIDE_SHADER, shader)
        }

        API.shared.parameter(Self.PARAM_OVERRIDE_PHOTONS, photons)

        API.shared.options(API.DEFAULT_OPTIONS)
    }
}
