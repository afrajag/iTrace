//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class NormalMapModifier: Modifier {
    var normalMap: Texture?

    required init() {
        normalMap = nil
    }

    func update(_ pl: ParameterList) -> Bool {
        let filename: String? = pl.getString("texture", nil)

        if filename != nil {
            normalMap = TextureCache.getTexture(API.shared.resolveTextureFilename(filename!), true)
        }

        return normalMap != nil
    }

    func modify(_ state: ShadingState) {
        //  apply normal map
        state.getNormal()!.set(normalMap!.getNormal(state.getUV()!.x, state.getUV()!.y, state.getBasis()!))

        state.setBasis(OrthoNormalBasis.makeFromW(state.getNormal()!))
    }
}
