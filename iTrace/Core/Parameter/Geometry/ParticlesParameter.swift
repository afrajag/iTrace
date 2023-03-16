//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class ParticlesParameter: GeometryParameter {
    var num: Int32 = 0
    var radius: Float = 0.0
    var points: [Float]?

    private enum CodingKeys: String, CodingKey {
        case num
        case radius
        case points
    }
    
    init(_ name: String) {
        super.init()
        
        self.name = name
        
        self.type = ParameterType.TYPE_PARTICLES
        
        initializable = true
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        
        self.name = name
        
        self.type = ParameterType.TYPE_PARTICLES
        
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            num = try container.decode(Int32.self, forKey: .num)
            radius = try container.decode(Float.self, forKey: .radius)
            points = try container.decode([Float].self, forKey: .points)
            
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
        
        try container.encode(num, forKey: .num)
        try container.encode(radius, forKey: .radius)
        try container.encode(points, forKey: .points)
    }
    
    override func setup() {
        // failed decode check
        if !initializable {
            UI.printError(.SCENE, "Error setting up: \(name) of type \(type!.rawValue)")
            return
        }
        
        super.setup()

        API.shared.parameter("particles", "point", "vertex", points!)
        API.shared.parameter("num", num)
        API.shared.parameter("radius", radius)
        API.shared.geometry(name, Self.TYPE_PARTICLES)

        setupInstance()
    }
}
