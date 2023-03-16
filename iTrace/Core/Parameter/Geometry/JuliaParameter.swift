//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class JuliaParameter: GeometryParameter {
    var iterations: Int32 = 1
    var epsilon: Float = 0.0

    //  Quaternion
    var cx: Float = 0.0
    var cy: Float = 0.0
    var cz: Float = 0.0
    var cw: Float = 0.0

    private enum CodingKeys: String, CodingKey {
        case iterations
        case epsilon
        case cx
        case cy
        case cz
        case cw
    }
    
    init(_ name: String) {
        super.init()
        
        self.name = name
        
        self.type = ParameterType.TYPE_JULIA
        
        initializable = true
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        
        self.name = name
        
        self.type = ParameterType.TYPE_JULIA
        
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            iterations = try container.decode(Int32.self, forKey: .iterations)
            epsilon = try container.decode(Float.self, forKey: .epsilon)
            cx = try container.decode(Float.self, forKey: .cx)
            cy = try container.decode(Float.self, forKey: .cy)
            cz = try container.decode(Float.self, forKey: .cz)
            cw = try container.decode(Float.self, forKey: .cw)
            
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
        
        try container.encode(iterations, forKey: .iterations)
        try container.encode(epsilon, forKey: .epsilon)
        try container.encode(cx, forKey: .cx)
        try container.encode(cy, forKey: .cy)
        try container.encode(cz , forKey: .cz)
        try container.encode(cw, forKey: .cw)
    }
    
    override func setup() {
        // failed decode check
        if !initializable {
            UI.printError(.SCENE, "Error setting up: \(name) of type \(type!.rawValue)")
            return
        }
        
        super.setup()

        API.shared.parameter("cw", cw)
        API.shared.parameter("cx", cx)
        API.shared.parameter("cy", cy)
        API.shared.parameter("cz", cz)
        API.shared.parameter("iterations", iterations)
        API.shared.parameter("epsilon", epsilon)

        API.shared.geometry(name, Self.TYPE_JULIA)

        setupInstance()
    }
}
