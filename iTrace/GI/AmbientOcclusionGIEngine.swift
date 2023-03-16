//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//
import Foundation

final class AmbientOcclusionGIEngine: GIEngine {
    var bright: Color?
    var dark: Color?
    var samples: Int32 = 0
    var maxDist: Float = 0.0

    required init() {}

    func getGlobalRadiance(_: ShadingState) -> Color {
        return Color.BLACK
    }

    func initGI(_ options: Options, _: Scene) -> Bool {
        bright = options.getColor("gi.ambocc.bright", Color.WHITE)!
        dark = options.getColor("gi.ambocc.dark", Color.BLACK)!
        samples = options.getInt("gi.ambocc.samples", 32)!
        maxDist = options.getFloat("gi.ambocc.maxdist", 0)!

        maxDist = (maxDist <= 0 ? Float.infinity : maxDist)

        return true
    }

    func getIrradiance(_ state: ShadingState, _: Color) -> Color {
        let onb: OrthoNormalBasis? = state.getBasis()
        let w: Vector3 = Vector3()
        let result: Color = Color.black()

        for i in 0 ..< samples {
            let xi: Float = Float(state.getRandom(i, 0, samples))
            let xj: Float = Float(state.getRandom(i, 1, samples))
            let phi: Float = Float(2 * Float.pi * xi)
            let cosPhi: Float = Float(cos(phi))
            let sinPhi: Float = Float(sin(phi))
            let sinTheta: Float = Float(sqrt(xj))
            let cosTheta: Float = Float(sqrt(1.0 - xj))

            w.x = cosPhi * sinTheta
            w.y = sinPhi * sinTheta
            w.z = cosTheta

            onb!.transform(w)

            let r: Ray = Ray(state.getPoint(), w)

            r.setMax(maxDist)

            result.add(Color.blend(bright!, dark!, state.traceShadow(r)))
        }

        return result.mul(Float.pi / Float(samples))
    }
}
