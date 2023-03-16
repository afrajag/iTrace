//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class BumpMappingModifier: Modifier {
    var bumpTexture: Texture?
    var scale: Float = 0.0

    required init() {
        bumpTexture = nil

        scale = 1
    }

    func update(_ pl: ParameterList) -> Bool {
        let filename: String? = pl.getString("texture", nil)

        if filename != nil {
            bumpTexture = TextureCache.getTexture(API.shared.resolveTextureFilename(filename!), true)
        }

        scale = pl.getFloat("scale", scale)!

        return bumpTexture != nil
    }

    func modify(_ state: ShadingState) {
        //  apply bump
        state.getNormal()!.set(bumpTexture!.getBump(state.getUV()!.x, state.getUV()!.y, state.getBasis()!, scale))

        state.setBasis(OrthoNormalBasis.makeFromW(state.getNormal()!))
    }
}
