//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class PhotonParameter: Parameter {
    static let PARAM_CAUSTICS: String = "caustics"
    static let PARAM_CAUSTICS_EMIT: String = "caustics.emit"
    static let PARAM_CAUSTICS_GATHER: String = "caustics.gather"
    static let PARAM_CAUSTICS_RADIUS: String = "caustics.radius"
    
    static let TYPE_PHOTON: String = "photon"
    
    var shader: String = ""
    var photons: Bool = false
    var caustics: IlluminationParameter?

    private enum CodingKeys: String, CodingKey {
        case shader
        case photons
        case caustics
    }
    
    override init() {
        super.init()
        
        self.name = Self.TYPE_PHOTON
        
        self.type = ParameterType.TYPE_PHOTON
        
        initializable = true
        
        caustics = IlluminationParameter()
    }

    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        
        self.name = name
        
        self.type = ParameterType.TYPE_PHOTON
        
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            shader = try container.decode(String.self, forKey: .shader)
            photons = try container.decode(Bool.self, forKey: .photons)
            caustics = try container.decode(IlluminationParameter.self, forKey: .caustics)
            
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
        try container.encode(caustics, forKey: .caustics)
    }
    
    override func setup() {
        // failed decode check
        if !initializable {
            UI.printError(.SCENE, "Error setting up: \(name) of type \(type!.rawValue)")
            return
        }
        
        API.shared.parameter(Self.PARAM_CAUSTICS, caustics!.map)
        API.shared.parameter(Self.PARAM_CAUSTICS_EMIT, caustics!.emit)
        API.shared.parameter(Self.PARAM_CAUSTICS_GATHER, caustics!.gather)
        API.shared.parameter(Self.PARAM_CAUSTICS_RADIUS, caustics!.radius)

        API.shared.options(API.DEFAULT_OPTIONS)
    }
}
