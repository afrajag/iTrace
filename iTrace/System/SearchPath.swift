//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//
import Foundation
import PathKit

final class SearchPath {
    var searchPath: [String]
    var type: String

    init(_ type: String) {
        self.type = type
        searchPath = [String]()
    }

    func resetSearchPath() {
        searchPath.removeAll()
    }

    func addSearchPath(_ path: String) {
        let path = Path(path)
        
        if path.exists && path.isDirectory {
            let absPath = path.absolute()

            for prefix in searchPath {
                if prefix == absPath.string {
                    return
                }
            }

            UI.printInfo(.SYS, "Adding \(type) search path: \"\(absPath)\"")

            searchPath.append(absPath.string)

            // FIXME: gestire errori
            // UI.printError(.SYS, "Invalid \(xxx) search path specification: \"\(xxx)\" - \(xxx)", type, path, e)
        } else {
            UI.printError(.SYS, "Invalid \(type) search path specification: \"\(path)\" - invalid directory")
        }
    }

    func resolvePath(_ filename: String) -> String {
        var _filename: String = filename

        //  account for relative naming schemes from 3rd party softwares
        if _filename.starts(with: "//") {
            _filename = filename.substring(to: 2)
        }

        UI.printDetailed(.SYS, "Resolving \(type) path \"\(_filename)\" ...")

        // FIXME: check to see if this is relevant
        var f = Path(filename)

        if !f.isAbsolute {
            for prefix in searchPath {
                UI.printDetailed(.SYS, "  * searching: \(prefix) ...")

                if prefix.hasSuffix(Path.separator) || filename.hasPrefix(Path.separator) {
                    f = Path(prefix + filename)
                } else {
                    f = Path(prefix + Path.separator + filename)
                }

                if f.exists {
                    // suggested path exists - try it
                    return f.absolute().string
                }
            }
        }

        // file was not found in the search paths - return the filename itself
        return _filename
    }
}
