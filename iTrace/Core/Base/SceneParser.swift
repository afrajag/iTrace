//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//
import Foundation

protocol SceneParser: Initializable {
    // Parse the specified file to create a scene description into the provided
    // {@link API} object.
    //
    // @param filename filename to parse
    // @param api scene to parse the file into
    // @return true upon sucess, or false if
    //         errors have occured.
    func parse(_ filename: String) -> Bool

    func parse(_ stream: Stream) -> Bool

    func canParse(_ stream: Stream, _ filename: String) -> Bool
}

extension SceneParser {
    func parse(_ filename: String) -> Bool {
        return false
    }

    func parse(_: Stream) -> Bool {
        return false
    }

    func canParse(_: Stream, _: String) -> Bool {
        return true
    }
}
