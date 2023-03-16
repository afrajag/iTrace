//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class DiffuseShaderParameter: ShaderParameter {
    var texture: String = ""
    var diffuse: Color = Color.WHITE

    private enum CodingKeys: String, CodingKey {
        case texture
        case diffuse
    }

    init(_ name: String) {
        super.init()
        
        self.name = name
        
        self.type = ParameterType.TYPE_DIFFUSE
        
        initializable = true
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        
        self.name = name
        
        self.type = ParameterType.TYPE_DIFFUSE
        
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            texture = try container.decode(String.self, forKey: .texture)
            diffuse = try container.decode(Color.self, forKey: .diffuse)
            
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
        
        try container.encodeIfPresent(texture, forKey: .texture)
        try container.encodeIfPresent(diffuse, forKey: .diffuse)
    }
    
    override func setup() {
        // failed decode check
        if !initializable {
            UI.printError(.SCENE, "Error setting up: \(name) of type \(type!.rawValue)")
            return
        }
        
        if texture.isEmpty {
            API.shared.parameter("diffuse", nil, diffuse.getRGB())
            API.shared.shader(name, Self.TYPE_DIFFUSE)
        } else {
            API.shared.parameter("texture", texture)
            API.shared.shader(name, Self.TYPE_TEXTURED_DIFFUSE)
        }
    }
}
