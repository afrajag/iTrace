//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class BackgroundParameter: Parameter {
    static let TYPE_CONSTANT: String = "constant"
    static let PARAM_BACKGROUND: String = "background"
    static let PARAM_BACKGROUND_SHADER: String = "background.shader"
    static let PARAM_BACKGROUND_INSTANCE: String = "background.instance"
    static let PARAM_TYPE_BACKGROUND: String = "background"
    
    static let TYPE_BACKGROUND: String = "background"

    var color: Color?

    private enum CodingKeys: String, CodingKey {
        case color
    }
    
    override init() {
        super.init()
        
        self.name = Self.TYPE_BACKGROUND
        
        self.type = ParameterType.TYPE_BACKGROUND
        
        initializable = true
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)

        self.name = name
        
        self.type = ParameterType.TYPE_BACKGROUND
        
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            color = try container.decode(Color.self, forKey: .color)
            
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
        
        try container.encode(color, forKey: .color)
    }
    
    override func setup() {
        // failed decode check
        if !initializable {
            UI.printError(.SCENE, "Error setting up: \(name) of type \(type!.rawValue)")
            return
        }
        
        API.shared.parameter(ParameterList.PARAM_COLOR, nil, color!.getRGB())

        API.shared.shader(Self.PARAM_BACKGROUND_SHADER, ShaderParameter.TYPE_CONSTANT)

        API.shared.geometry(Self.PARAM_BACKGROUND, Self.PARAM_TYPE_BACKGROUND)

        API.shared.parameter(ParameterList.PARAM_SHADERS, Self.PARAM_BACKGROUND_SHADER)

        API.shared.instance(Self.PARAM_BACKGROUND_INSTANCE, Self.PARAM_TYPE_BACKGROUND)
    }
}
