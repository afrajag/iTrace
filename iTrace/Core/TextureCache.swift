//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//
import Foundation

final class TextureCache {
    static var textures: [String: Texture] = [String: Texture]()

    static let lockQueue = DispatchQueue(label: "texturecache.lock.serial.queue")

    init() {}

    // Gets a reference to the texture specified by the given filename. If the
    // texture has already been loaded the previous reference is returned,
    // otherwise, a new texture is created.
    //
    // @param filename image file to load
    // @param isLinear is the texture gamma corrected
    // @return texture object
    // @see Texture
    static func getTexture(_ filename: String, _ isLinear: Bool) -> Texture {
        lockQueue.sync { // synchronized block
            if textures[filename] != nil {
                UI.printInfo(.TEX, "Using cached copy for file \"\(filename)\" ...")

                return textures[filename]!
            }

            UI.printInfo(.TEX, "Using file \"\(filename)\" ...")

            let t: Texture = Texture(filename, isLinear)

            textures[filename] = t

            return t
        }
    }

    // Flush all textures from the cache, this will cause them to be reloaded
    // anew the next time they are accessed.
    static func flush() {
        lockQueue.sync { // synchronized block
            UI.printInfo(.TEX, "Flushing texture cache")

            textures.removeAll()
        }
    }
}
