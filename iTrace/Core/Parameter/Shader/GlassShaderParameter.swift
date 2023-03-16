//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class GlassShaderParameter: ShaderParameter {
    //  Default values from GlassShader
    var eta: Float = 0.0
    var color: Color = Color.WHITE
    var absorptionDistance: Float = 0.0 // disabled by default
    var absorptionColor: Color = Color.GRAY // 50% absorbtion

    private enum CodingKeys: String, CodingKey {
        case eta
        case color
        case absorptionDistance
        case absorptionColor
    }

    init(_ name: String) {
        super.init()
        
        self.name = name
        
        self.type = ParameterType.TYPE_GLASS
        
        initializable = true
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        
        self.name = name
        
        self.type = ParameterType.TYPE_GLASS
        
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            eta = try container.decode(Float.self, forKey: .eta)
            color = try container.decode(Color.self, forKey: .color)
            absorptionDistance = try container.decode(Float.self, forKey: .absorptionDistance)
            absorptionColor = try container.decode(Color.self, forKey: .absorptionColor)
            
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
        
        try container.encodeIfPresent(eta, forKey: .eta)
        try container.encodeIfPresent(color, forKey: .color)
        try container.encodeIfPresent(absorptionDistance, forKey: .absorptionDistance)
        try container.encodeIfPresent(absorptionColor, forKey: .absorptionColor)
    }
    
    override func setup() {
        // failed decode check
        if !initializable {
            UI.printError(.SCENE, "Error setting up: \(name) of type \(type!.rawValue)")
            return
        }
        
        API.shared.parameter("eta", eta)
        API.shared.parameter("color", nil, color.getRGB())
        API.shared.parameter("absorption.distance", absorptionDistance)
        API.shared.parameter("absorption.color", nil, absorptionColor.getRGB())

        API.shared.shader(name, Self.TYPE_GLASS)
    }
}
