//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class InstantGIParameter: GlobalIlluminationParameter {
    static let PARAM_SAMPLES: String = "gi.igi.samples"
    static let PARAM_SETS: String = "gi.igi.sets"
    static let PARAM_BIAS: String = "gi.igi.bias"
    static let PARAM_BIAS_SAMPLES: String = "gi.igi.bias_samples"

    var samples: Int32 = 0
    var sets: Int32 = 0
    var bias: Float = 0.0
    var biasSamples: Int32 = 0

    private enum CodingKeys: String, CodingKey {
        case samples
        case sets
        case bias
        case biasSamples
    }
    
    override init() {
        super.init()
        
        self.name = Self.TYPE_IGI
        
        self.type = ParameterType.TYPE_INSTANT_GI
        
        initializable = true
    }

    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        
        self.name = name
        
        self.type = ParameterType.TYPE_INSTANT_GI
        
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            samples = try container.decode(Int32.self, forKey: .samples)
            sets = try container.decode(Int32.self, forKey: .sets)
            bias = try container.decode(Float.self, forKey: .bias)
            biasSamples = try container.decode(Int32.self, forKey: .biasSamples)
            
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
        try container.encode(sets, forKey: .sets)
        try container.encode(bias, forKey: .bias)
        try container.encode(biasSamples, forKey: .biasSamples)
    }
    
    override func setup() {
        // failed decode check
        if !initializable {
            UI.printError(.SCENE, "Error setting up: \(name) of type \(type!.rawValue)")
            return
        }
        
        API.shared.parameter(Self.PARAM_ENGINE, Self.TYPE_IGI)
        API.shared.parameter(Self.PARAM_SAMPLES, samples)
        API.shared.parameter(Self.PARAM_SETS, sets)
        API.shared.parameter(Self.PARAM_BIAS, bias)
        API.shared.parameter(Self.PARAM_BIAS_SAMPLES, biasSamples)

        super.setup()
    }
}
