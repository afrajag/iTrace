//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

class ModifierParameter: Parameter {
    static let TYPE_BUMP_MAP: String = "bump_map"
    static let TYPE_NORMAL_MAP: String = "normal_map"
    static let TYPE_PERLIN: String = "perlin"

    override init() {
        super.init()
    }
    
    required init(from decoder: Decoder) throws {
        super.init()
        
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            name = try container.decodeIfPresent(String.self, forKey: .name) ?? generateUniqueName("modifier")
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
