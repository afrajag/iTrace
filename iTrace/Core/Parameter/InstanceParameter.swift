//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class InstanceParameter: Parameter {
    static let TYPE_INSTANCE: String = "instance"
    
    var _name: String?
    var _geometry: String?
    var _shaders: [String]?
    var _modifiers: [String]?
    var _transform: TransformParameter?

    private enum CodingKeys: String, CodingKey {
        case _name = "name"
        case _geometry = "geometry"
        case _shaders = "shaders"
        case _modifiers = "modifiers"
        case _transform = "transform"
    }
    
    override init() {
        super.init()
        
        self.name = Self.TYPE_INSTANCE
        
        self.type = ParameterType.TYPE_INSTANCE
        
        initializable = true
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        
        self.name = name
        
        self.type = ParameterType.TYPE_INSTANCE
        
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            _name = try container.decode(String.self, forKey: ._name)
            _geometry = try container.decode(String.self, forKey: ._geometry)
            _shaders = try container.decodeIfPresent([String].self, forKey: ._shaders)
            _modifiers = try container.decodeIfPresent([String].self, forKey: ._modifiers)
            _transform = try container.decodeIfPresent(TransformParameter.self, forKey: ._transform)
            
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
        
        try container.encodeIfPresent(_name, forKey: ._name)
        try container.encodeIfPresent(_geometry, forKey: ._geometry)
        try container.encodeIfPresent(_shaders, forKey: ._shaders)
        try container.encodeIfPresent(_modifiers, forKey: ._modifiers)
        try container.encodeIfPresent(_transform , forKey: ._transform)
    }
    
    override func setup() {
        // failed decode check
        if !initializable {
            UI.printError(.SCENE, "Error setting up: \(name) of type \(type!.rawValue)")
            return
        }
        
        if _transform != nil {
            _transform!.setup()
        }

        if _shaders != nil {
            API.shared.parameter("shaders", _shaders!)
        }

        if _modifiers != nil {
            API.shared.parameter("modifiers", _modifiers!)
        }

        if _geometry != nil {
            API.shared.instance(_name!, _geometry!)
        }
    }

    func name() -> String? {
        return _name
    }

    @discardableResult
    func name(_ name: String) -> InstanceParameter {
        _name = name

        return self
    }

    func geometry() -> String? {
        return _geometry
    }

    @discardableResult
    func geometry(_ geometry: String) -> InstanceParameter {
        _geometry = geometry

        return self
    }

    func shaders() -> [String]? {
        return _shaders
    }

    @discardableResult
    func shaders(_ shaders: [String]) -> InstanceParameter {
        _shaders = shaders

        return self
    }

    func modifiers() -> [String]? {
        return _modifiers
    }

    @discardableResult
    func modifiers(_ modifiers: [String]) -> InstanceParameter {
        _modifiers = modifiers

        return self
    }

    func transform() -> TransformParameter? {
        return _transform
    }

    @discardableResult
    func transform(_ transform: TransformParameter) -> InstanceParameter {
        _transform = transform

        return self
    }
}
