//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class PathTracingGIParameter: GlobalIlluminationParameter {
    static let PARAM_SAMPLES: String = "gi.path.samples"

    var samples: Int32 = 0

    private enum CodingKeys: String, CodingKey {
        case samples
    }
    
    override init() {
        super.init()
        
        self.name = Self.TYPE_PATH
        
        self.type = ParameterType.TYPE_PATH_TRACING_GI
        
        initializable = true
    }

    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        
        self.name = name
        
        self.type = ParameterType.TYPE_PATH_TRACING_GI
        
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            samples = try container.decode(Int32.self, forKey: .samples)
            
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
    }
    
    override func setup() {
        // failed decode check
        if !initializable {
            UI.printError(.SCENE, "Error setting up: \(name) of type \(type!.rawValue)")
            return
        }
        
        API.shared.parameter(Self.PARAM_ENGINE, Self.TYPE_PATH)
        API.shared.parameter(Self.PARAM_SAMPLES, samples)

        super.setup()
    }
}
