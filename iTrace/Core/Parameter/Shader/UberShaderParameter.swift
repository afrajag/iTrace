//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class UberShaderParameter: ShaderParameter {
    var diffuse = Color.GRAY
    var diffuseBlend: Float = 1.0
    var diffuseTexture: String = ""
    var specular = Color.GRAY
    var specularBlend: Float = 1.0
    var specularTexture: String = ""
    var samples: Int32 = 4
    var glossyness: Float = 0.0

    private enum CodingKeys: String, CodingKey {
        case diffuse
        case diffuseBlend
        case diffuseTexture
        case specular
        case specularBlend
        case specularTexture
        case samples
        case glossyness
    }

    init(_ name: String) {
        super.init()
        
        self.name = name
        
        self.type = ParameterType.TYPE_UBER
        
        initializable = true
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        
        self.name = name
        
        self.type = ParameterType.TYPE_UBER
        
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            diffuse = try container.decode(Color.self, forKey: .diffuse)
            diffuseBlend = try container.decode(Float.self, forKey: .diffuseBlend)
            diffuseTexture = try container.decode(String.self, forKey: .diffuseTexture)
            specular = try container.decode(Color.self, forKey: .specular)
            specularBlend = try container.decode(Float.self, forKey: .specularBlend)
            specularTexture = try container.decode(String.self, forKey: .specularTexture)
            samples = try container.decode(Int32.self, forKey: .samples)
            glossyness = try container.decode(Float.self, forKey: .glossyness)
            
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
        
        try container.encode(diffuse, forKey: .diffuse)
        try container.encode(diffuseBlend, forKey: .diffuseBlend)
        try container.encode(diffuseTexture, forKey: .diffuseTexture)
        try container.encode(specular, forKey: .specular)
        try container.encode(specularBlend , forKey: .specularBlend)
        try container.encode(specularTexture, forKey: .specularTexture)
        try container.encode(samples, forKey: .samples)
        try container.encode(glossyness, forKey: .glossyness)
    }
    
    override func setup() {
        // failed decode check
        if !initializable {
            UI.printError(.SCENE, "Error setting up: \(name) of type \(type!.rawValue)")
            return
        }
        
        API.shared.parameter("diffuse", nil, diffuse.getRGB())

        if !diffuseTexture.isEmpty {
            API.shared.parameter("diffuse.texture", diffuseTexture)
        }

        API.shared.parameter("diffuse.blend", diffuseBlend)
        
        API.shared.parameter("specular", nil, specular.getRGB())

        if !specularTexture.isEmpty {
            API.shared.parameter("specular.texture", specularTexture)
        }

        API.shared.parameter("specular.blend", specularBlend)
        API.shared.parameter("glossyness", glossyness)
        
        API.shared.parameter("samples", samples)

        API.shared.shader(name, Self.TYPE_UBER)
    }
}
