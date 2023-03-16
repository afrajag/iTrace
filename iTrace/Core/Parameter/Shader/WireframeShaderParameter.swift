//
//  WireframeShaderParameter.swift
//  iTrace
//
//  Created by Fabrizio Pezzola on 03/03/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class WireframeShaderParameter: ShaderParameter {
    var line: Color? = Color.BLACK
    var fill: Color? = Color.GRAY
    var width: Float? = 1

    private enum CodingKeys: String, CodingKey {
        case line
        case fill
        case width
    }

    init(_ name: String) {
        super.init()
        
        self.name = name
        
        self.type = ParameterType.TYPE_WIREFRAME
        
        initializable = true
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        
        self.name = name
        
        self.type = ParameterType.TYPE_WIREFRAME
        
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            line = try container.decodeIfPresent(Color.self, forKey: .line) ?? Color.BLACK
            fill = try container.decodeIfPresent(Color.self, forKey: .fill) ?? Color.GRAY
            width = try container.decodeIfPresent(Float.self, forKey: .width) ?? 1
            
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
        
        try container.encode(line, forKey: .line)
        try container.encode(fill, forKey: .fill)
        try container.encode(width, forKey: .width)
    }
    
    override func setup() {
        // failed decode check
        if !initializable {
            UI.printError(.SCENE, "Error setting up: \(name) of type \(type!.rawValue)")
            return
        }
        
        API.shared.parameter("line", line!)
        API.shared.parameter("fill", fill!)
        API.shared.parameter("width", width!)
        
        API.shared.shader(name, Self.TYPE_WIREFRAME)
    }
}
