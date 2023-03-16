//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

class CameraParameter: Parameter {
    static let TYPE_FISH_EYE: String = "fisheye"
    static let TYPE_PINHOLE: String = "pinhole"
    static let TYPE_SPHERICAL: String = "spherical"
    static let TYPE_THINLENS: String = "thinlens"
    static let PARAM_FOV: String = "fov"
    static let PARAM_ASPECT: String = "aspect"
    static let PARAM_SHIFT_X: String = "shift.x"
    static let PARAM_SHIFT_Y: String = "shift.y"
    static let PARAM_SHUTTER_OPEN: String = "shutter.open"
    static let PARAM_SHUTTER_CLOSE: String = "shutter.close"
    static let PARAM_CAMERA: String = "camera"

    static let TYPE_SUPER = "camera"
    
    // Default values from Camera
    var eye: Point3?
    var target: Point3?
    var up: Vector3?
    var shutterOpen: Float = 0
    var shutterClose: Float = 0
    
    private enum CodingKeys: String, CodingKey {
        case name
        case eye
        case target
        case up
        case shutterOpen
        case shutterClose
    }
    
    override init() {
        super.init()
    }
    
    required init(from decoder: Decoder) throws {
        super.init()
        
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            name = try container.decodeIfPresent(String.self, forKey: .name) ?? generateUniqueName("camera")
            //type = try container.decode(String.self, forKey: .type)
            eye = try container.decode(Point3.self, forKey: .eye)
            target = try container.decode(Point3.self, forKey: .target)
            up = try container.decode(Vector3.self, forKey: .up)
            shutterOpen = try container.decode(Float.self, forKey: .shutterOpen)
            shutterClose = try container.decode(Float.self, forKey: .shutterClose)
            
            initializable = true
        } catch let DecodingError.dataCorrupted(context) {
            UI.printError(.SCENE, context.debugDescription)
        } catch let DecodingError.keyNotFound(key, context) {
            UI.printError(.SCENE, "Key '\(key.stringValue)' not found at path: \(context.codingPath.reduce("") { $0 + "/" + $1.stringValue })")
        } catch let DecodingError.valueNotFound(value, context) {
            UI.printError(.SCENE, "Value '\(value)' not found at path: \(context.codingPath.reduce("") { $0 + "/" + $1.stringValue })")
        } catch let DecodingError.typeMismatch(type, context) {
            UI.printError(.SCENE, "Type '\(type)' mismatch at path: \(context.codingPath.reduce("") { $0 + "/" + $1.stringValue })")
        } catch {
            UI.printError(.SCENE, error.localizedDescription)
        }
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(eye, forKey: .eye)
        try container.encode(target, forKey: .target)
        try container.encode(up, forKey: .up)
        try container.encode(shutterOpen, forKey: .shutterOpen)
        try container.encode(shutterClose, forKey: .shutterClose)
    }
    
    override func setup() {
        // failed decode check
        if !initializable {
            UI.printError(.SCENE, "Error setting up: \(name) of type \(type!.rawValue)")
            return
        }
        
        API.shared.parameter(Self.PARAM_CAMERA, name)
        
        API.shared.options(API.DEFAULT_OPTIONS)
    }
}
