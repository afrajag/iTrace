//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class SphereParameter: GeometryParameter {
    var center: Point3?
    var radius: Float? = 0.0

    private enum CodingKeys: String, CodingKey {
        case center
        case radius
    }
  
    init(_ name: String) {
        super.init()
        
        self.name = name
        
        self.type = ParameterType.TYPE_SPHERE
        
        initializable = true
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        
        self.name = name
        
        self.type = ParameterType.TYPE_SPHERE
        
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            center = try container.decodeIfPresent(Point3.self, forKey: .center)
            radius = try container.decodeIfPresent(Float.self, forKey: .radius)
            
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
        
        try container.encode(center, forKey: .center)
        try container.encode(radius, forKey: .radius)
    }
    
    override func setup() {
        // failed decode check
        if !initializable {
            UI.printError(.SCENE, "Error setting up: \(name) of type \(type!.rawValue)")
            return
        }
        
        super.setup()

        API.shared.geometry(name, Self.TYPE_SPHERE)

        // Legacy instantiation
        if center != nil {
            API.shared.parameter("transform", AffineTransform.translation(center!.x, center!.y, center!.z).multiply(AffineTransform.scale(radius!)))

            if instanceParameter != nil {
                if instanceParameter!.shaders() != nil {
                    API.shared.parameter("shaders", instanceParameter!.shaders()!)
                }

                if instanceParameter!.modifiers() != nil {
                    API.shared.parameter("modifiers", instanceParameter!.modifiers()!)
                }
            }

            API.shared.instance(name + ".instance", name)
        } else {
            setupInstance()
        }
    }
}
