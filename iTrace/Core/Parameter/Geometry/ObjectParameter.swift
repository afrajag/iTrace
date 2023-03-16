//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

class ObjectParameter: Parameter {
    static let TYPE_BOX: String = "box"
    static let TYPE_BANCHOFF: String = "banchoff"
    static let TYPE_BEZIER_MESH: String = "bezier_mesh"
    static let TYPE_CYLINDER: String = "cylinder"
    static let TYPE_GUMBO: String = "gumbo"
    static let TYPE_HAIR: String = "hair"
    static let TYPE_JULIA: String = "julia"
    static let TYPE_TORUS: String = "torus"
    static let TYPE_SPHERE: String = "sphere"
    static let TYPE_SPHEREFLAKE: String = "sphereflake"
    static let TYPE_PARTICLES: String = "particles"
    static let TYPE_PLANE: String = "plane"
    static let TYPE_TEAPOT: String = "teapot"
    static let TYPE_TRIANGLE_MESH: String = "triangle_mesh"
    static let TYPE_FILE_MESH: String = "file_mesh"

    static let PARAM_ACCEL: String = "accel"

    // FIXME: controllare se clash con il nome del parametro
    //var name: String = "none"
    var accel: String = ""
    var instanceParameter: InstanceParameter?

    private enum CodingKeys: String, CodingKey {
        case name
        //case type
        case accel
        case instanceParameter = "instance"
    }
    
    override init() {
        super.init()
    }
    
    required init(from decoder: Decoder) throws {
        super.init()
        
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            name = try container.decodeIfPresent(String.self, forKey: .name) ?? generateUniqueName("object")
            //type = try container.decode(String.self, forKey: .type)
            accel = try container.decodeIfPresent(String.self, forKey: .accel) ?? ""
            instanceParameter = try container.decodeIfPresent(InstanceParameter.self, forKey: .instanceParameter)
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
        
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(accel, forKey: .accel)
        try container.encode(instanceParameter, forKey: .instanceParameter)
    }
    
    override func setup() {
        if !accel.isEmpty {
            API.shared.parameter(Self.PARAM_ACCEL, accel)
        }
    }

    func geometry(_ geometry: String) {
        if instanceParameter == nil {
            instanceParameter = InstanceParameter()
        }

        instanceParameter!.geometry(geometry)
    }

    func geometry(_ objectParameter: ObjectParameter) {
        if instanceParameter == nil {
            instanceParameter = InstanceParameter()
        }

        instanceParameter!.geometry(objectParameter.name)
    }

    func shaders(_ shaders: String...) {
        if instanceParameter == nil {
            instanceParameter = InstanceParameter()
        }

        instanceParameter!.shaders(shaders)
    }

    func shaders(_ shaders: ShaderParameter...) {
        if instanceParameter == nil {
            instanceParameter = InstanceParameter()
        }

        var names: [String] = [String]()

        shaders.forEach { names.append($0.name) }

        instanceParameter!.shaders(names)
    }

    func modifiers(_ modifiers: String...) {
        if instanceParameter == nil {
            instanceParameter = InstanceParameter()
        }

        instanceParameter!.shaders(modifiers)
    }

    func modifiers(_ modifiers: ModifierParameter...) {
        if instanceParameter == nil {
            instanceParameter = InstanceParameter()
        }

        var names: [String] = [String]()

        modifiers.forEach { names.append($0.name) }

        instanceParameter!.modifiers(names)
    }

    func rotateX(_ angle: Float) {
        let transformParameter: TransformParameter? = getInstanceTransform()

        transformParameter!.rotateX(angle)
    }

    func rotateY(_ angle: Float) {
        let transformParameter: TransformParameter? = getInstanceTransform()

        transformParameter!.rotateY(angle)
    }

    func rotateZ(_ angle: Float) {
        let transformParameter: TransformParameter? = getInstanceTransform()

        transformParameter!.rotateZ(angle)
    }

    func scale(_ scale: Float) {
        let transformParameter: TransformParameter? = getInstanceTransform()

        transformParameter!.scale(scale)
    }

    func scale(_ x: Float, _ y: Float, _ z: Float) {
        let transformParameter: TransformParameter? = getInstanceTransform()

        transformParameter!.scale(x, y, z)
    }

    func translate(_ x: Float, _ y: Float, _ z: Float) {
        let transformParameter: TransformParameter? = getInstanceTransform()

        transformParameter!.translate(x, y, z)
    }

    func getInstanceTransform() -> TransformParameter {
        if instanceParameter == nil {
            instanceParameter = InstanceParameter()
        }

        var transformParameter: TransformParameter? = instanceParameter!.transform()

        if transformParameter == nil {
            transformParameter = TransformParameter()

            instanceParameter!.transform(transformParameter!)
        }

        return transformParameter!
    }
}
