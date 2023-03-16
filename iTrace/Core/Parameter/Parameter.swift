//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

import Foundation

class Parameter: Codable {
    var initializable: Bool = false
    var name: String
    var type: ParameterType?

    enum CodingKeys: String, CodingKey {
        case name
        //case type
    }
    
    init() {
        self.name = "default"
    }
    
    required init(from decoder: Decoder) throws {
       self.name = "default"
        
       do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            name = try container.decodeIfPresent(String.self, forKey: .name) ?? "default"
        
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
    
    func setup() {} // base implementation
    
    func generateUniqueName(_ prefix: String) -> String {
        return "\(prefix)_\(UUID())"
    }
}
