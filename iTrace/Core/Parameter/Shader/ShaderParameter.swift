//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

class ShaderParameter: Parameter {
    static let TYPE_AMBIENT_OCCLUSION: String = "ambient_occlusion"
    static let TYPE_TEXTURED_AMBIENT_OCCLUSION: String = "textured_ambient_occlusion"
    static let TYPE_CONSTANT: String = "constant"
    static let TYPE_DIFFUSE: String = "diffuse"
    static let TYPE_TEXTURED_DIFFUSE: String = "textured_diffuse"
    static let TYPE_GLASS: String = "glass"
    static let TYPE_MIRROR: String = "mirror"
    static let TYPE_PHONG: String = "phong"
    static let TYPE_TEXTURED_PHONG: String = "textured_phong"
    static let TYPE_SHINY_DIFFUSE: String = "shiny_diffuse"
    static let TYPE_TEXTURED_SHINY_DIFFUSE: String = "textured_shiny_diffuse"
    static let TYPE_UBER: String = "uber"
    static let TYPE_WARD: String = "ward"
    static let TYPE_WIREFRAME: String = "wireframe"
    static let TYPE_SHOW_INSTANCE_ID: String = "show_instance_id"
    static let TYPE_TEXTURED_WARD: String = "textured_ward"
    static let TYPE_VIEW_CAUSTICS: String = "view_caustics"
    static let TYPE_VIEW_IRRADIANCE: String = "view_irradiance"
    static let TYPE_VIEW_GLOBAL: String = "view_global"
    static let TYPE_NONE: String = "none"

    override init() {
        super.init()
    }
    
    required init(from decoder: Decoder) throws {
        super.init()
        
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            name = try container.decodeIfPresent(String.self, forKey: .name) ?? generateUniqueName("shader")
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
    
    override func setup() {}
}
