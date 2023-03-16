//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//
import Foundation

final class PathTracingGIEngine: GIEngine {
    var samples: Int32 = 0

    required init() {}

    func initGI(_ options: Options, _: Scene) -> Bool {
        samples = options.getInt("gi.path.samples", 16)!
        samples = max(0, samples)

        UI.printInfo(.LIGHT, "Path tracer settings:")
        UI.printInfo(.LIGHT, "  * Samples: \(samples)")

        return true
    }

    func getIrradiance(_ state: ShadingState, _: Color) -> Color {
        if samples <= 0 {
            return Color.BLACK
        }

        //  compute new sample
        var irr: Color = Color.black()
        let onb: OrthoNormalBasis? = state.getBasis()
        let w: Vector3 = Vector3()
        let n: Int32 = state.getDiffuseDepth() == 0 ? samples : 1

        for i in 0 ..< n {
            let xi: Float = Float(state.getRandom(i, 0, n))
            let xj: Float = Float(state.getRandom(i, 1, n))
            let phi: Float = xi * 2 * Float.pi

            let cosPhi: Float = cos(phi)
            let sinPhi: Float = sin(phi)

            let sinTheta: Float = sqrt(xj)
            let cosTheta: Float = sqrt(1.0 - xj)

            w.x = cosPhi * sinTheta
            w.y = sinPhi * sinTheta
            w.z = cosTheta

            onb!.transform(w)

            let temp: ShadingState? = state.traceFinalGather(Ray(state.getPoint(), w), i)

            if temp != nil {
                temp!.getInstance()!.prepareShadingState(temp!)

                if temp!.getShader() != nil {
                    irr.add(temp!.getShader()!.getRadiance(temp!))
                }
            }
        }

        irr = irr.mul(Float.pi / Float(n))

        return irr
    }

    func getGlobalRadiance(_: ShadingState) -> Color {
        return Color.BLACK
    }
}
