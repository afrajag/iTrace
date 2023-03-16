//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class SphereFlakeParameter: GeometryParameter {
    //  Default values from SphereFlake
    var level: Int32 = 2
    var radius: Float = 1
    var axis: Vector3? = Vector3(0, 0, 1)

    private enum CodingKeys: String, CodingKey {
        case level
        case radius
        case axis
    }

    init(_ name: String) {
        super.init()
        
        self.name = name
        
        self.type = ParameterType.TYPE_SPHEREFLAKE
        
        initializable = true
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        
        self.name = name
        
        self.type = ParameterType.TYPE_SPHEREFLAKE
        
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            level = try container.decode(Int32.self, forKey: .level)
            radius = try container.decode(Float.self, forKey: .radius)
            axis = try container.decode(Vector3.self, forKey: .axis)
            
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
        
        try container.encode(level, forKey: .level)
        try container.encode(radius, forKey: .radius)
        try container.encode(axis, forKey: .axis)
    }
    
    override func setup() {
        // failed decode check
        if !initializable {
            UI.printError(.SCENE, "Error setting up: \(name) of type \(type!.rawValue)")
            return
        }
        
        super.setup()

        API.shared.parameter("level", level)

        if axis != nil {
            API.shared.parameter("axis", axis!)
        }

        if radius > 0 {
            API.shared.parameter("radius", radius)
        }

        API.shared.geometry(name, Self.TYPE_SPHEREFLAKE)

        setupInstance()
    }
}
