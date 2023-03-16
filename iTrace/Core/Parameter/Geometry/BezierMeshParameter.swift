//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class BezierMeshParameter: GeometryParameter {
    var points: [Float]?
    var subdivs: Int32 = 1
    var smooth: Bool = false
    var nu: Int32 = 0
    var nv: Int32 = 0
    var uwrap: Bool = false
    var vwrap: Bool = false

    private enum CodingKeys: String, CodingKey {
        case points
        case subdivs
        case smooth
        case nu
        case nv
        case uwrap
        case vwrap
    }
    
    init(_ name: String) {
        super.init()
        
        self.name = name
        
        self.type = ParameterType.TYPE_BEZIER_MESH
        
        initializable = true
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        
        self.name = name
        
        self.type = ParameterType.TYPE_BEZIER_MESH
        
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            points = try container.decode([Float].self, forKey: .points)
            subdivs = try container.decode(Int32.self, forKey: .subdivs)
            smooth = try container.decode(Bool.self, forKey: .smooth)
            nu = try container.decode(Int32.self, forKey: .nu)
            nv = try container.decode(Int32.self, forKey: .nv)
            uwrap = try container.decode(Bool.self, forKey: .uwrap)
            vwrap = try container.decode(Bool.self, forKey: .vwrap)
            
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
        
        try container.encode(points, forKey: .points)
        try container.encode(subdivs, forKey: .subdivs)
        try container.encode(smooth, forKey: .smooth)
        try container.encode(nu, forKey: .nu)
        try container.encode(nv , forKey: .nv)
        try container.encode(uwrap, forKey: .uwrap)
        try container.encode(vwrap, forKey: .vwrap)
    }
    
    override func setup() {
        // failed decode check
        if !initializable {
            UI.printError(.SCENE, "Error setting up: \(name) of type \(type!.rawValue)")
            return
        }
        
        super.setup()

        API.shared.parameter("nu", nu)
        API.shared.parameter("nv", nv)
        API.shared.parameter("uwrap", uwrap)
        API.shared.parameter("vwrap", vwrap)
        API.shared.parameter("points", "point", "vertex", points!)
        API.shared.parameter("subdivs", subdivs)
        API.shared.parameter("smooth", smooth)

        API.shared.geometry(name, Self.TYPE_BEZIER_MESH)

        setupInstance()
    }
}
