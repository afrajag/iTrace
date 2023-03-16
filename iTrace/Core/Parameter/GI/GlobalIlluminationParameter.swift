//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

class GlobalIlluminationParameter: Parameter {
    static let PARAM_ENGINE: String = "gi.engine"
    static let TYPE_AMBOCC: String = "ambocc"
    static let TYPE_FAKE: String = "fake"
    static let TYPE_IGI: String = "igi"
    static let TYPE_IRR_CACHE: String = "irr-cache"
    static let TYPE_PATH: String = "path"
    static let TYPE_NONE: String = "none"

    override init() {
        super.init()
    }
    
    required init(from decoder: Decoder) throws {
        super.init()
        
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            name = try container.decodeIfPresent(String.self, forKey: .name) ?? generateUniqueName("gi")
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
    
    override func setup() {
        API.shared.options(API.DEFAULT_OPTIONS)
    }
}
