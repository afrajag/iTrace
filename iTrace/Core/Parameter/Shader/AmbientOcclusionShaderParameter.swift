//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class AmbientOcclusionShaderParameter: ShaderParameter {
    //  Default values from AmbientOcclusionShader
    var texture: String = ""
    var bright: Color = Color.WHITE
    var dark: Color = Color.BLACK
    var samples: Int32 = 32
    var maxDist: Float = Float.infinity

    private enum CodingKeys: String, CodingKey {
        case texture
        case bright
        case dark
        case samples
        case maxDist = "maxDistance"
    }

    init(_ name: String) {
        super.init()
        
        self.name = name
        
        self.type = ParameterType.TYPE_AMBIENT_OCCLUSION
        
        initializable = true
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        
        self.name = name
        
        self.type = ParameterType.TYPE_AMBIENT_OCCLUSION
        
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            texture = try container.decode(String.self, forKey: .texture)
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
        try super.encode(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(texture, forKey: .texture)
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
        
        API.shared.parameter("dark", nil, dark.getRGB())
        API.shared.parameter("samples", samples)
        API.shared.parameter("maxdist", maxDist)

        if texture.isEmpty {
            API.shared.parameter("bright", nil, bright.getRGB())
            API.shared.shader(name, Self.TYPE_AMBIENT_OCCLUSION)
        } else {
            API.shared.parameter("texture", texture)
            API.shared.shader(name, Self.TYPE_TEXTURED_AMBIENT_OCCLUSION)
        }
    }
}
