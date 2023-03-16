//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

class AmbientOcclusionShader: Shader {
    var bright: Color?
    var dark: Color?
    var samples: Int32 = 0
    var maxDist: Float = 0.0

    required init() {
        bright = Color.WHITE
        dark = Color.BLACK
        samples = 32
        maxDist = Float.infinity
    }

    convenience init(_ c: Color, _ d: Float) {
        self.init()
        bright = c
        maxDist = d
    }

    func update(_ pl: ParameterList) -> Bool {
        bright = pl.getColor("bright", bright)
        dark = pl.getColor("dark", dark)
        samples = pl.getInt("samples", samples)!
        maxDist = pl.getFloat("maxdist", maxDist)!

        if maxDist <= 0 {
            maxDist = Float.infinity
        }

        return true
    }

    func getBrightColor(_: ShadingState) -> Color {
        return bright!
    }

    func getRadiance(_ state: ShadingState) -> Color {
        return state.occlusion(samples, maxDist, getBrightColor(state), dark!)
    }

    func scatterPhoton(_: ShadingState, _: Color) {}
}
