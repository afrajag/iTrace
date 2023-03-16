//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//
import Foundation

class ShinyDiffuseShader: Shader {
    var diff: Color?
    var refl: Float = 0.0

    required init() {
        diff = Color.GRAY

        refl = 0.5
    }

    func update(_ pl: ParameterList) -> Bool {
        diff = pl.getColor("diffuse", diff)
        refl = pl.getFloat("shiny", refl)!

        return true
    }

    func getDiffuse(_: ShadingState) -> Color {
        return diff!
    }

    func getRadiance(_ state: ShadingState) -> Color {
        //  make sure we are on the right side of the material
        state.faceforward()

        //  direct lighting
        state.initLightSamples()

        state.initCausticSamples()

        let d: Color = getDiffuse(state)
        let lr: Color = state.diffuse(d)

        if !state.includeSpecular {
            return lr
        }

        var cos: Float = state.getCosND()
        let dn: Float = 2 * cos
        let refDir: Vector3 = Vector3()

        refDir.x = (dn * state.getNormal()!.x) + state.getRay()!.getDirection().x
        refDir.y = (dn * state.getNormal()!.y) + state.getRay()!.getDirection().y
        refDir.z = (dn * state.getNormal()!.z) + state.getRay()!.getDirection().z

        let refRay: Ray = Ray(state.getPoint(), refDir)

        //  compute Fresnel term
        cos = 1 - cos

        let cos2: Float = cos * cos
        let cos5: Float = cos2 * cos2 * cos
        let ret: Color = Color.white()
        let r: Color = d.copy().mul(refl)

        ret.sub(r)

        ret.mul(cos5)

        ret.add(r)

        return lr.add(ret.mul(state.traceReflection(refRay, 0)))
    }

    func scatterPhoton(_ state: ShadingState, _ power: Color) {
        var diffuse: Color

        //  make sure we are on the right side of the material
        state.faceforward()

        diffuse = getDiffuse(state)

        state.storePhoton(state.getRay()!.getDirection(), power, diffuse)

        let d: Float = diffuse.getAverage()
        let r: Float = d * refl
        let rnd: Double = state.getRandom(0, 0, 1)

        if rnd < Double(d) {
            //  photon is scattered
            power.mul(diffuse).mul(1.0 / d)

            let onb: OrthoNormalBasis = state.getBasis()!
            let u: Double = 2 * Double.pi * rnd / Double(d)
            let v: Double = state.getRandom(0, 1, 1)
            let s: Float = Float(sqrt(v))
            let s1: Float = Float(sqrt(1.0 - v))
            var w: Vector3 = Vector3(Float(cos(u)) * s, Float(sin(u)) * s, s1)

            w = onb.transform(w, Vector3())

            state.traceDiffusePhoton(Ray(state.getPoint(), w), power)
        } else {
            if rnd < Double(d + r) {
                let cos: Float = -Vector3.dot(state.getNormal()!, state.getRay()!.getDirection())

                power.mul(diffuse).mul(1.0 / d)

                //  photon is reflected
                let dn: Float = 2 * cos
                let dir: Vector3 = Vector3()

                dir.x = (dn * state.getNormal()!.x) + state.getRay()!.getDirection().x
                dir.y = (dn * state.getNormal()!.y) + state.getRay()!.getDirection().y
                dir.z = (dn * state.getNormal()!.z) + state.getRay()!.getDirection().z

                state.traceReflectionPhoton(Ray(state.getPoint(), dir), power)
            }
        }
    }
}
