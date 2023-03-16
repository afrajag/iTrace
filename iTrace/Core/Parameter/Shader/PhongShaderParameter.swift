//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class PhongShaderParameter: ShaderParameter {
    var texture: String = ""
    var diffuse: Color = Color.GRAY
    var specular: Color = Color.GRAY
    var power: Float = 20.0
    var samples: Int32 = 4 //  Number of Rays

    private enum CodingKeys: String, CodingKey {
        case texture
        case diffuse
        case specular
        case power
        case samples
    }

    init(_ name: String) {
        super.init()
        
        self.name = name
        
        self.type = ParameterType.TYPE_PHONG
        
        initializable = true
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        
        self.name = name
        
        self.type = ParameterType.TYPE_PHONG
        
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            texture = try container.decode(String.self, forKey: .texture)
            diffuse = try container.decode(Color.self, forKey: .diffuse)
            specular = try container.decode(Color.self, forKey: .specular)
            power = try container.decode(Float.self, forKey: .power)
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
        try super.encode(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(texture, forKey: .texture)
        try container.encode(diffuse, forKey: .diffuse)
        try container.encode(specular, forKey: .specular)
        try container.encode(power, forKey: .power)
        try container.encode(samples , forKey: .samples)
    }
    
    override func setup() {
        // failed decode check
        if !initializable {
            UI.printError(.SCENE, "Error setting up: \(name) of type \(type!.rawValue)")
            return
        }
        
        API.shared.parameter("specular", nil, specular.getRGB())
        API.shared.parameter("power", power)
        API.shared.parameter("samples", samples)

        if texture.isEmpty {
            API.shared.parameter("diffuse", nil, diffuse.getRGB())
            API.shared.shader(name, Self.TYPE_PHONG)
        } else {
            API.shared.parameter("texture", texture)
            API.shared.shader(name, Self.TYPE_TEXTURED_PHONG)
        }
    }
}
