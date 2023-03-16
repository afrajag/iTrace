//
//  JTRParser.swift
//  iTrace
//
//  Created by Fabrizio Pezzola on 29/03/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

import Foundation
import PathKit

final class JTRParser: SceneParser {
    required init() {}
    
    // Parse the specified file to create a scene description into the provided
    // {@link API} object.
    //
    // @param filename filename to parse
    // @param api scene to parse the file into
    // @return true upon sucess, or false if
    //         errors have occured.
    func parse(_ filename: String, _ api: API) -> Bool {
        let t: TraceTimer = TraceTimer()

        t.start()

        UI.printInfo(.API, "Parsing \"\(filename)\" ...")
        
        let scene = SceneParameter()
        
        do {
            try decode(scene, Path(filename).read())
        } catch {
            UI.printError(.API, "Error decoding file: \(filename)")
            
            return false
        }
        
        t.end()
        
        UI.printInfo(.API, "Done parsing.")
        UI.printInfo(.API, "Parsing time: \(t.toString())")
        
        return true
    }
    
    func encode(_ scene: SceneParameter) -> String {
        let encoder = JSONEncoder()
        
        let jsonData = try! encoder.encode(scene)
        
        return String(data: jsonData, encoding: .utf8)!
    }
    
    func decode(_ scene: SceneParameter, _ data: String) throws {
        let decoder = JSONDecoder()
        
        let _scene = try decoder.decode(SceneParameter.self, from: data.data(using: .utf8)!)
        
        scene.name = _scene.name
        
        if (_scene.image != nil) {
            scene.image = _scene.image
        }
        
        if (_scene.texturePath != nil) {
            scene.texturePath?.append(contentsOf: _scene.texturePath!)
        }
        
        if (_scene.includePath != nil) {
            scene.includePath?.append(contentsOf: _scene.includePath!)
        }
        
        if (_scene.include != nil) {
            scene.include?.append(contentsOf: _scene.include!)
        }
        
        scene.setup()
        
        for parameter in _scene.scene! {
            UI.printDetailed(.SCENE, "Found type: \(parameter.type.rawValue)")
            
            if let param = ParameterRegistry.getParameter(parameter) {
                scene.add(param as! Parameter)
            }
        }
    }
}
