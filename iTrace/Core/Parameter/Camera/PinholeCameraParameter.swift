//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class PinholeCameraParameter: CameraParameter {
    var aspect: Float = 0.0
    var fov: Float = 0.0
    var shiftX: Float = 0.0
    var shiftY: Float = 0.0
    
    private enum CodingKeys: String, CodingKey {
        case aspect
        case fov
        case shiftX
        case shiftY
    }

    init(_ name: String) {
        super.init()
        
        self.name = name
        
        self.type = ParameterType.TYPE_PINHOLE
        
        initializable = true
    }

    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        
        self.name = name
        
        self.type = ParameterType.TYPE_PINHOLE
        
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            aspect = try container.decode(Float.self, forKey: .aspect)
            fov = try container.decode(Float.self, forKey: .fov)
            shiftX = try container.decodeIfPresent(Float.self, forKey: .shiftX) ?? 0.0
            shiftY = try container.decodeIfPresent(Float.self, forKey: .shiftY) ?? 0.0
            
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
        
        try container.encode(aspect, forKey: .aspect)
        try container.encode(fov, forKey: .fov)
        try container.encode(shiftX, forKey: .shiftX)
        try container.encode(shiftY, forKey: .shiftY)
    }
    
    override func setup() {
        // failed decode check
        if !initializable {
            UI.printError(.SCENE, "Error setting up: \(name) of type \(type!.rawValue)")
            return
        }
        
        // applying transform to camera
        API.shared.parameter("transform", AffineTransform.lookAt(eye!, target!, up!))
        
        API.shared.parameter(Self.PARAM_SHUTTER_OPEN, shutterOpen)
        API.shared.parameter(Self.PARAM_SHUTTER_CLOSE, shutterClose)
        API.shared.parameter(Self.PARAM_FOV, fov)
        API.shared.parameter(Self.PARAM_ASPECT, aspect)
        API.shared.parameter(Self.PARAM_SHIFT_X, shiftX)
        API.shared.parameter(Self.PARAM_SHIFT_Y, shiftY)

        API.shared.camera(name, Self.TYPE_PINHOLE)

        super.setup()
    }
}
