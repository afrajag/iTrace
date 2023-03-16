//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class IlluminationParameter: Parameter {
    static let TYPE_ILLUMINATION = "illumination"
    
    var emit: Int32 = 0
    var map: String = ""
    var gather: Int32 = 0
    var radius: Float = 0

    private enum CodingKeys: String, CodingKey {
        case emit
        case map
        case gather
        case radius
    }
    
    override init() {
        super.init()
        
        self.name = Self.TYPE_ILLUMINATION
        
        self.type = ParameterType.TYPE_ILLUMINATION
        
        initializable = true
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)

        self.name = name
        
        self.type = ParameterType.TYPE_ILLUMINATION
        
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            emit = try container.decode(Int32.self, forKey: .emit)
            map = try container.decode(String.self, forKey: .map)
            gather = try container.decode(Int32.self, forKey: .gather)
            radius = try container.decode(Float.self, forKey: .radius)
            
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
        // no super calling because we wont 'name' attribute to be present
        //try super.encode(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(emit, forKey: .emit)
        try container.encode(map, forKey: .map)
        try container.encode(gather, forKey: .gather)
        try container.encode(radius, forKey: .radius)
    }

    override func setup() {
        // FIXME: why no setup for illumination ? double check this
    }
}
