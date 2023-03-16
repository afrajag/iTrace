//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class TeapotParameter: GeometryParameter {
    var subdivs: Int32 = 1
    var smooth: Bool = false

    private enum CodingKeys: String, CodingKey {
        case subdivs
        case smooth
    }
    
    init(_ name: String) {
        super.init()
        
        self.name = name
        
        self.type = ParameterType.TYPE_TEAPOT
        
        initializable = true
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)

        self.name = name
        
        self.type = ParameterType.TYPE_TEAPOT
        
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            subdivs = try container.decodeIfPresent(Int32.self, forKey: .subdivs) ?? 1
            smooth = try container.decodeIfPresent(Bool.self, forKey: .smooth) ?? false
            
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
        
        try container.encode(subdivs, forKey: .subdivs)
        try container.encode(smooth, forKey: .smooth)
    }
    
    override func setup() {
        // failed decode check
        if !initializable {
            UI.printError(.SCENE, "Error setting up: \(name) of type \(type!.rawValue)")
            return
        }
        
        super.setup()

        API.shared.parameter("subdivs", subdivs)
        API.shared.parameter("smooth", smooth)

        // FIXME: check this control
        //if instanceParameter == nil || instanceParameter!.geometry() == nil {
            API.shared.geometry(name, Self.TYPE_TEAPOT)
        //}

        setupInstance()
    }
}
