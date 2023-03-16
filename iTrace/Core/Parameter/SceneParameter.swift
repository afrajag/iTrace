//
//  SceneParameter.swift
//  iTrace
//
//  Created by Fabrizio Pezzola on 17/03/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

import Foundation
import Yams
import PathKit

final class SceneParameter: Codable {
    var name: String = "default"
    var image: ImageParameter?
    var texturePath: [String]?
    var includePath: [String]?
    var include: [String]?
    var scene: [CodableParameter]?

    private enum CodingKeys: String, CodingKey {
        case name
        case scene
        case image
        case texturePath = "texture_path"
        case includePath = "include_path"
        case include
    }
    
    init(_ name: String = "default") {
        self.name = name
        
        self.scene = [CodableParameter]()
        
        self.texturePath = [String]()
        self.includePath = [String]()
        
        self.include = [String]()
        
        ParameterRegistry.initRegistry()
    }
    
    required init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            name = try container.decode(String.self, forKey: .name)
            scene = try container.decodeIfPresent([CodableParameter].self, forKey: .scene)
            image = try container.decodeIfPresent(ImageParameter.self, forKey: .image)
            texturePath = try container.decodeIfPresent([String].self, forKey: .texturePath)
            includePath = try container.decodeIfPresent([String].self, forKey: .includePath)
            include = try container.decodeIfPresent([String].self, forKey: .include)
        } catch let DecodingError.dataCorrupted(context) {
            UI.printError(.SCENE, context.debugDescription)
        } catch let DecodingError.keyNotFound(key, context) {
            UI.printError(.SCENE, "Key '\(key.stringValue)' not found at path: \(context.codingPath.reduce("") { $0 + "/" + $1.stringValue })")
        } catch let DecodingError.valueNotFound(_, context) {
            UI.printError(.SCENE, "Value not found at path: \(context.codingPath.reduce("") { $0 + "/" + $1.stringValue })")
        } catch let DecodingError.typeMismatch(typeMismatch, context)  {
            UI.printError(.SCENE, "Type '\(typeMismatch)' mismatch at path: \(context.codingPath.reduce("") { $0 + "/" + $1.stringValue })")
        } catch {
            UI.printError(.SCENE, error.localizedDescription)
        }
    }
    
    func setup() {
        if (image != nil) {
            image!.setup()

            scene!.append(CodableParameter(.TYPE_IMAGE, image!))
        }
        
        if (texturePath != nil) {
            for path in texturePath! {
                API.shared.searchpath("texture", Path(path).isAbsolute ? path : Path(components: [Path.current.string, path]).string)
            }
        }
        
        if (includePath != nil) {
            for path in includePath! {
                API.shared.searchpath("include", Path(path).isAbsolute ? path : Path(components: [Path.current.string, path]).string)
            }
        }
        
        if (include != nil) {
            for path in include! {
                API.shared.include(path)
            }
        }
    }
    
    func add(_ param: Parameter) {
        param.setup()

        let a = CodableParameter(param.type!, param)
        
        scene!.append(a)
    }
}
