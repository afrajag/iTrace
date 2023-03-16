//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class TransformParameter: Parameter {
    static let INTERPOLATION_NONE: String = "none"

    static let TYPE_TRANSFORM: String = "transform"

    var times: [Float]?
    var transforms: [AffineTransform]? = [AffineTransform.IDENTITY]
    var interpolation: String? = "none"

    var rotateX: Float?
    var rotateY: Float?
    var rotateZ: Float?
    var scaleEq: Float?
    var scale: [Float]?
    var translate: [Float]?
    
    private enum CodingKeys: String, CodingKey {
        case times
        case transforms
        case interpolation
        case rotateX
        case rotateY
        case rotateZ
        case scaleEq = "scaleeq"
        case scale
        case translate
    }
    
    override init() {
        super.init()
        
        self.name = Self.TYPE_TRANSFORM
        
        self.type = ParameterType.TYPE_TRANSFORM
        
        initializable = true
    }

    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        
        self.name = name
        
        self.type = ParameterType.TYPE_TRANSFORM
        
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            times = try container.decodeIfPresent([Float].self, forKey: .times)
            transforms = try container.decodeIfPresent([AffineTransform].self, forKey: .transforms) ?? [AffineTransform.IDENTITY]
            interpolation = try container.decodeIfPresent(String.self, forKey: .interpolation) ?? "none"
            
            rotateX = try container.decodeIfPresent(Float.self, forKey: .rotateX)
            rotateY = try container.decodeIfPresent(Float.self, forKey: .rotateY)
            rotateZ = try container.decodeIfPresent(Float.self, forKey: .rotateZ)
            scaleEq = try container.decodeIfPresent(Float.self, forKey: .scaleEq)
            scale = try container.decodeIfPresent([Float].self, forKey: .scale)
            translate = try container.decodeIfPresent([Float].self, forKey: .translate)
            
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
        
        try container.encodeIfPresent(times, forKey: .times)
        try container.encode(transforms, forKey: .transforms)
        try container.encode(interpolation, forKey: .interpolation)
    }
    
    override func setup() {
        // failed decode check
        if !initializable {
            UI.printError(.SCENE, "Error setting up: \(name) of type \(type!.rawValue)")
            return
        }
        
        if (rotateX != nil) {
            rotateX(rotateX!)
        }
        
        if (rotateY != nil) {
            rotateY(rotateY!)
        }
        
        if (rotateZ != nil) {
            rotateZ(rotateZ!)
        }
        
        if (scaleEq != nil) {
            scale(scaleEq!)
        }
        
        if (scale != nil) {
            scale(scale![0], scale![1], scale![2])
        }
        
        if (translate != nil) {
            translate(translate![0], translate![1], translate![2])
        }
        
        if times == nil {
            API.shared.parameter("transform", transforms![0])
        } else {
            let steps: Int32 = Int32(times!.count)

            API.shared.parameter("transform.steps", steps)
            API.shared.parameter("transform.times", "float", interpolation!, times!)

            for i in 0 ..< steps {
                API.shared.parameter("transform[\(i)]", transforms![Int(i)])
            }
        }  
    }

    @discardableResult
    func rotateX(_ angle: Float) -> TransformParameter? {
        let t: AffineTransform = AffineTransform.rotateX(Float(MathUtils.toRadians(Double(angle))))

        transforms![0] = t.multiply(transforms![0])

        return self
    }

    @discardableResult
    func rotateY(_ angle: Float) -> TransformParameter? {
        let t: AffineTransform = AffineTransform.rotateY(Float(MathUtils.toRadians(Double(angle))))

        transforms![0] = t.multiply(transforms![0])

        return self
    }

    @discardableResult
    func rotateZ(_ angle: Float) -> TransformParameter? {
        let t: AffineTransform = AffineTransform.rotateZ(Float(MathUtils.toRadians(Double(angle))))

        transforms![0] = t.multiply(transforms![0])

        return self
    }

    @discardableResult
    func scale(_ scale: Float) -> TransformParameter? {
        let t: AffineTransform = AffineTransform.scale(scale)

        transforms![0] = t.multiply(transforms![0])

        return self
    }

    @discardableResult
    func scale(_ x: Float, _ y: Float, _ z: Float) -> TransformParameter? {
        let t: AffineTransform = AffineTransform.scale(x, y, z)

        transforms![0] = t.multiply(transforms![0])

        return self
    }

    @discardableResult
    func translate(_ x: Float, _ y: Float, _ z: Float) -> TransformParameter? {
        let t: AffineTransform = AffineTransform.translation(x, y, z)

        transforms![0] = t.multiply(transforms![0])

        return self
    }
}
