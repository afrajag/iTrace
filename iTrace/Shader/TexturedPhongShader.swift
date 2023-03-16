//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class TexturedPhongShader: PhongShader {
    var tex: Texture?

    required init() {
        tex = nil
    }

    override func update(_ pl: ParameterList) -> Bool {
        let filename: String? = pl.getString("texture", nil)
        
        if filename != nil {
            tex = TextureCache.getTexture(API.shared.resolveTextureFilename(filename!), false)
        }
        return tex != nil && super.update(pl)
    }

    override func getDiffuse(_ state: ShadingState) -> Color {
        return tex!.getPixel(state.getUV()!.x, state.getUV()!.y)
    }
}
