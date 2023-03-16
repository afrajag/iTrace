//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class PointLightParameter: LightParameter {
    static let PARAM_CENTER: String = "center"
    static let PARAM_POWER: String = "power"

    var lightPoint: Point3?
    var power: Color?

    private enum CodingKeys: String, CodingKey {
        case lightPoint = "center"
        case power
    }

    init(_ name: String) {
        super.init()
        
        self.name = name
        
        self.type = ParameterType.TYPE_POINT_LIGHT
        
        initializable = true
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        
        self.name = name
        
        self.type = ParameterType.TYPE_POINT_LIGHT
        
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            lightPoint = try container.decode(Point3.self, forKey: .lightPoint)
            power = try container.decode(Color.self, forKey: .power)
            
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
        
        try container.encode(lightPoint, forKey: .lightPoint)
        try container.encode(power, forKey: .power)
    }
    
    override func setup() {
        // failed decode check
        if !initializable {
            UI.printError(.SCENE, "")
            return
        }
        
        API.shared.parameter(Self.PARAM_CENTER, lightPoint!)
        API.shared.parameter(Self.PARAM_POWER, nil, power!.getRGB())

        API.shared.light(name, Self.TYPE_POINTLIGHT)
    }
}
