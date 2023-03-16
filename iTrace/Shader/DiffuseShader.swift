//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//
import Foundation

class DiffuseShader: Shader {
    var diff: Color?

    required init() {
        diff = Color.WHITE
    }

    func update(_ pl: ParameterList) -> Bool {
        diff = pl.getColor("diffuse", diff!)

        return true
    }

    func getDiffuse(_: ShadingState) -> Color {
        return diff!
    }

    func getRadiance(_ state: ShadingState) -> Color {
        //  make sure we are on the right side of the material
        state.faceforward()

        //  setup lighting
        state.initLightSamples()
        state.initCausticSamples()

        return state.diffuse(getDiffuse(state))
    }

    func scatterPhoton(_ state: ShadingState, _ power: Color) {
        var diffuse: Color

        //  make sure we are on the right side of the material
        if Vector3.dot(state.getNormal()!, state.getRay()!.getDirection()) > 0.0 {
            state.getNormal()!.negate()

            state.getGeoNormal()!.negate()
        }

        diffuse = getDiffuse(state)

        state.storePhoton(state.getRay()!.getDirection(), power, diffuse)

        let avg: Float = diffuse.getAverage()
        let rnd: Double = state.getRandom(0, 0, 1)

        if rnd < Double(avg) {
            //  photon is scattered
            power.mul(diffuse).mul(1.0 / avg)

            let onb: OrthoNormalBasis? = state.getBasis()
            let u: Double = (2 * Double.pi * rnd) / Double(avg)
            let v: Double = state.getRandom(0, 1, 1)
            let s: Float = Float(sqrt(v))
            let s1: Float = Float(sqrt(1.0 - v))
            var w: Vector3 = Vector3(Float(cos(u)) * s, Float(sin(u)) * s, s1)

            w = onb!.transform(Vector3())

            state.traceDiffusePhoton(Ray(state.getPoint(), w), power)
        }
    }
}
