//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class FakeGIParameter: GlobalIlluminationParameter {
    static let PARAM_SKY: String = "gi.fake.sky"
    static let PARAM_GROUND: String = "gi.fake.ground"
    static let PARAM_UP: String = "gi.fake.up"

    var ground: Color?
    var sky: Color?
    var up: Vector3?

    private enum CodingKeys: String, CodingKey {
        case ground
        case sky
        case up
    }
    
    override init() {
        super.init()
        
        self.name = Self.TYPE_FAKE
        
        self.type = ParameterType.TYPE_FAKE_GI
        
        initializable = true
    }

    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        
        self.name = name
        
        self.type = ParameterType.TYPE_FAKE_GI
        
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            ground = try container.decode(Color.self, forKey: .ground)
            sky = try container.decode(Color.self, forKey: .sky)
            up = try container.decode(Vector3.self, forKey: .up)
            
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
        
        try container.encode(ground, forKey: .ground)
        try container.encode(sky, forKey: .sky)
        try container.encode(up, forKey: .up)
    }
    
    override func setup() {
        // failed decode check
        if !initializable {
            UI.printError(.SCENE, "Error setting up: \(name) of type \(type!.rawValue)")
            return
        }
        
        API.shared.parameter(Self.PARAM_ENGINE, Self.TYPE_FAKE)
        API.shared.parameter(Self.PARAM_SKY, nil, sky!.getRGB())
        API.shared.parameter(Self.PARAM_GROUND, nil, ground!.getRGB())
        API.shared.parameter(Self.PARAM_UP, up!)

        super.setup()
    }
}
