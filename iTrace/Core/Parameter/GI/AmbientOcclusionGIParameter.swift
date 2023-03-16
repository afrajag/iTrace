//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class AmbientOcclusionGIParameter: GlobalIlluminationParameter {
    static let PARAM_BRIGHT: String = "gi.ambocc.bright"
    static let PARAM_DARK: String = "gi.ambocc.dark"
    static let PARAM_SAMPLES: String = "gi.ambocc.samples"
    static let PARAM_MAXDIST: String = "gi.ambocc.maxdist"

    var bright: Color?
    var dark: Color?
    var samples: Int32 = 0
    var maxDist: Float = 0

    private enum CodingKeys: String, CodingKey {
        case bright
        case dark
        case samples
        case maxDist
    }
    
    override init() {
        super.init()
        
        self.name = Self.TYPE_AMBOCC
        
        self.type = ParameterType.TYPE_AMBIENT_OCCLUSION_GI
        
        initializable = true
    }

    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        
        self.name = name
        
        self.type = ParameterType.TYPE_AMBIENT_OCCLUSION_GI
        
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            bright = try container.decode(Color.self, forKey: .bright)
            dark = try container.decode(Color.self, forKey: .dark)
            samples = try container.decode(Int32.self, forKey: .samples)
            maxDist = try container.decode(Float.self, forKey: .maxDist)
            
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
        
        try container.encode(bright, forKey: .bright)
        try container.encode(dark, forKey: .dark)
        try container.encode(samples, forKey: .samples)
        try container.encode(maxDist, forKey: .maxDist)
    }
    
    override func setup() {
        // failed decode check
        if !initializable {
            UI.printError(.SCENE, "Error setting up: \(name) of type \(type!.rawValue)")
            return
        }
        
        API.shared.parameter(Self.PARAM_ENGINE, Self.TYPE_AMBOCC)
        API.shared.parameter(Self.PARAM_BRIGHT, nil, bright!.getRGB())
        API.shared.parameter(Self.PARAM_DARK, nil, dark!.getRGB())
        API.shared.parameter(Self.PARAM_SAMPLES, samples)

        if maxDist > 0 {
            API.shared.parameter(Self.PARAM_MAXDIST, maxDist)
        }

        super.setup()
    }
}
