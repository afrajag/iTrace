//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//


final class ThinLensCameraParameter: CameraParameter {
    static let PARAM_FOCUS_DISTANCE: String = "focus.distance"
    static let PARAM_LENS_RADIUS: String = "lens.radius"
    static let PARAM_LENS_SIDES: String = "lens.sides"
    static let PARAM_LENS_ROTATION: String = "lens.rotation"

    var focusDistance: Float = 0.0
    var lensRadius: Float = 0.0
    var lensSides: Int32 = 0
    var lensRotation: Float = 0.0
    var lensRotationRadians: Float = 0.0 // FIXME: controllare
    var aspect: Float = 0.0
    var fov: Float = 0.0
    var shiftX: Float = 0.0
    var shiftY: Float = 0.0

    //var lensRotationRadians: Float { get { lens.getLensRotationRadians() } set { lens.setLensRotationRadians(lensRotationRadians) } }
    
    private enum CodingKeys: String, CodingKey {
        case focusDistance
        case lensRadius
        case lensSides
        case lensRotation
        case aspect
        case fov
        case shiftX
        case shiftY
    }
    
    init(_ name: String) {
        super.init()
        
        self.name = name
        
        self.type = ParameterType.TYPE_THINLENS
        
        initializable = true
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        
        self.name = name
        
        self.type = ParameterType.TYPE_THINLENS
        
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            focusDistance = try container.decode(Float.self, forKey: .focusDistance)
            lensRadius = try container.decode(Float.self, forKey: .lensRadius)
            lensSides = try container.decode(Int32.self, forKey: .lensSides)
            lensRotation = try container.decode(Float.self, forKey: .lensRotation)
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
        
        try container.encode(focusDistance, forKey: .focusDistance)
        try container.encode(lensRadius, forKey: .lensRadius)
        try container.encode(lensSides, forKey: .lensSides)
        try container.encode(lensRotation, forKey: .lensRotation)
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
        API.shared.parameter(Self.PARAM_FOCUS_DISTANCE, focusDistance)
        API.shared.parameter(Self.PARAM_LENS_RADIUS, lensRadius)
        API.shared.parameter(Self.PARAM_LENS_SIDES, lensSides)
        API.shared.parameter(Self.PARAM_LENS_ROTATION, lensRotation)
        
        API.shared.camera(name, Self.TYPE_THINLENS)

        super.setup()
    }
}

