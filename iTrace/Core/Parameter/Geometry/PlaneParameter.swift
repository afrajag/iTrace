//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class PlaneParameter: GeometryParameter {
    var center: Point3?
    var point1: Point3?
    var point2: Point3?
    var normal: Vector3?

    private enum CodingKeys: String, CodingKey {
        case center
        case point1
        case point2
        case normal
    }
    
    init(_ name: String) {
        super.init()
        
        self.name = name
        
        self.type = ParameterType.TYPE_PLANE
        
        initializable = true
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        
        self.name = name
        
        self.type = ParameterType.TYPE_PLANE
        
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            center = try container.decode(Point3.self, forKey: .center)
            point1 = try container.decodeIfPresent(Point3.self, forKey: .point1)
            point2 = try container.decodeIfPresent(Point3.self, forKey: .point2)
            normal = try container.decodeIfPresent(Vector3.self, forKey: .normal)
            
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
        try container.encode(point1, forKey: .point1)
        try container.encode(point2, forKey: .point2)
        try container.encode(normal, forKey: .normal)
    }
    
    override func setup() {
        // failed decode check
        if !initializable {
            UI.printError(.SCENE, "Error setting up: \(name) of type \(type!.rawValue)")
            return
        }
        
        super.setup()

        API.shared.parameter("center", center!)

        if normal != nil {
            API.shared.parameter("normal", normal!)
        } else {
            API.shared.parameter("point1", point1!)
            API.shared.parameter("point2", point2!)
        }

        API.shared.geometry(name, Self.TYPE_PLANE)

        setupInstance()
    }
}
