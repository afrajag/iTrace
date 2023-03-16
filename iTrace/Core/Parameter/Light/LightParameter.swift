//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

class LightParameter: Parameter {
    static let PARAM_RADIANCE: String = "radiance"
    static let PARAM_SAMPLES: String = "samples"
    static let TYPE_CORNELL_BOX: String = "cornell_box"
    static let TYPE_DIRECTIONAL: String = "directional"
    static let TYPE_IMAGE_BASED: String = "ibl"
    static let TYPE_POINTLIGHT: String = "point"
    static let TYPE_SPHERE: String = "spherical"
    static let TYPE_SUNSKY: String = "sunsky"
    static let TYPE_TRIANGLE_MESH: String = "triangle_mesh"

    override init() {
        super.init()
        
        // FIXME: controllare se per ogni luce (parametro) non ci sia bisogno di chiamare generateUniqueName
    }
    
    required init(from decoder: Decoder) throws {
        super.init()
        
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            name = try container.decodeIfPresent(String.self, forKey: .name) ?? generateUniqueName("light")
            //type = try container.decode(String.self, forKey: .type)
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
}
