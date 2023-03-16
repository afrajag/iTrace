//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class TraceDepthsParameter: Parameter {
    static let PARAM_DEPTHS_DIFFUSE: String = "depths.diffuse"
    static let PARAM_DEPTHS_REFLECTION: String = "depths.reflection"
    static let PARAM_DEPTHS_REFRACTION: String = "depths.refraction"

    static let TYPE_TRACEDEPTHS: String = "tracedepths"
    
    var diffuse: Int32 = 0
    var reflection: Int32 = 0
    var refraction: Int32 = 0

    private enum CodingKeys: String, CodingKey {
        case diffuse
        case reflection
        case refraction
    }
    
    override init() {
        super.init()
        
        self.name = Self.TYPE_TRACEDEPTHS
        
        self.type = ParameterType.TYPE_TRACE_DEPTHS
        
        initializable = true
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        
        self.name = name
        
        self.type = ParameterType.TYPE_TRACE_DEPTHS
        
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            diffuse = try container.decode(Int32.self, forKey: .diffuse)
            reflection = try container.decode(Int32.self, forKey: .reflection)
            refraction = try container.decode(Int32.self, forKey: .refraction)
        
            initializable = true
        } catch let DecodingError.dataCorrupted(context) {
            UI.printError(.SCENE, context.debugDescription)
        } catch let DecodingError.keyNotFound(key, context) {
            UI.printError(.SCENE, "Key '\(key.stringValue)' not found:")
            UI.printError(.SCENE, "codingPath: \(context.codingPath.reduce("") { $0 + "/" + $1.stringValue })")
        } catch let DecodingError.valueNotFound(value, context) {
            UI.printError(.SCENE, "Value '\(value)' not found:")
            UI.printError(.SCENE, "codingPath: \(context.codingPath.reduce("") { $0 + "/" + $1.stringValue })")
        } catch let DecodingError.typeMismatch(type, context)  {
            UI.printError(.SCENE, "Type '\(type)' mismatch:")
            UI.printError(.SCENE, "codingPath: \(context.codingPath.reduce("") { $0 + "/" + $1.stringValue })")
        } catch {
            UI.printError(.SCENE, error.localizedDescription)
        }
    }

    override func encode(to encoder: Encoder) throws {
        // no super calling because we wont 'name' attribute to be present
        //try super.encode(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(diffuse, forKey: .diffuse)
        try container.encode(reflection, forKey: .reflection)
        try container.encode(refraction, forKey: .refraction)
    }
    
    override func setup() {
        // failed decode check
        if !initializable {
            UI.printError(.SCENE, "Error setting up: \(name) of type \(type!.rawValue)")
            return
        }
        
        if diffuse > 0 {
            API.shared.parameter(Self.PARAM_DEPTHS_DIFFUSE, diffuse)
        }

        if reflection > 0 {
            API.shared.parameter(Self.PARAM_DEPTHS_REFLECTION, reflection)
        }

        if refraction > 0 {
            API.shared.parameter(Self.PARAM_DEPTHS_REFRACTION, refraction)
        }
    }
}
