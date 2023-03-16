//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//
import Foundation

final class GlassShader: Shader {
    var eta: Float = 0.0
    var f0: Float = 0.0
    var color: Color?
    var absorptionDistance: Float = 0.0
    var absorptionColor: Color?

    required init() {
        eta = 1.3

        color = Color.WHITE

        absorptionDistance = 0 //  disabled by default

        absorptionColor = Color.GRAY //  50% absorption
    }

    func update(_ pl: ParameterList) -> Bool {
        color = pl.getColor("color", color)

        eta = pl.getFloat("eta", eta)!

        f0 = (1 - eta) / (1 + eta)
        f0 = f0 * f0

        absorptionDistance = pl.getFloat("absorption.distance", absorptionDistance)!

        absorptionColor = pl.getColor("absorption.color", absorptionColor)

        return true
    }

    func getRadiance(_ state: ShadingState) -> Color {
        if !state.includeSpecular {
            return Color.BLACK
        }

        let reflDir: Vector3 = Vector3()
        let refrDir: Vector3 = Vector3()

        state.faceforward()

        let cos: Float = state.getCosND()
        let inside: Bool = state.isBehind()
        let neta: Float = (inside ? eta : 1.0 / eta)
        let dn: Float = 2 * cos

        reflDir.x = (dn * state.getNormal()!.x) + state.getRay()!.getDirection().x
        reflDir.y = (dn * state.getNormal()!.y) + state.getRay()!.getDirection().y
        reflDir.z = (dn * state.getNormal()!.z) + state.getRay()!.getDirection().z

        //  refracted ray
        let arg: Float = 1 - (neta * neta * (1 - (cos * cos)))
        let tir: Bool = arg < 0

        if tir {
            refrDir.x = 0
            refrDir.y = 0
            refrDir.z = 0
        } else {
            let nK: Float = (neta * cos) - Float(sqrt(arg))

            refrDir.x = (neta * state.getRay()!.dx) + (nK * state.getNormal()!.x)
            refrDir.y = (neta * state.getRay()!.dy) + (nK * state.getNormal()!.y)
            refrDir.z = (neta * state.getRay()!.dz) + (nK * state.getNormal()!.z)
        }

        //  compute Fresnel terms
        let cosTheta1: Float = Vector3.dot(state.getNormal()!, reflDir)
        let cosTheta2: Float = -Vector3.dot(state.getNormal()!, refrDir)

        let pPara: Float = (cosTheta1 - (eta * cosTheta2)) / (cosTheta1 + (eta * cosTheta2))
        let pPerp: Float = ((eta * cosTheta1) - cosTheta2) / ((eta * cosTheta1) + cosTheta2)
        let kr: Float = 0.5 * ((pPara * pPara) + (pPerp * pPerp))
        let kt: Float = 1 - kr

        var absorption: Color?

        if inside && (absorptionDistance > 0) {
            //  this ray is inside the object and leaving it
            //  compute attenuation that occured along the ray
            absorption = Color.mul(-state.getRay()!.getMax() / absorptionDistance, absorptionColor!.copy().opposite()).cExp()

            if absorption!.isBlack() {
                return Color.BLACK //  nothing goes through
            }
        }

        //  refracted ray
        let ret: Color = Color.black()

        if !tir {
            ret.madd(kt, state.traceRefraction(Ray(state.getPoint(), refrDir), 0)).mul(color!)
        }

        if !inside || tir {
            ret.add(Color.mul(kr, state.traceReflection(Ray(state.getPoint(), reflDir), 0)).mul(color!))
        }

        return (absorption != nil ? ret.mul(absorption!) : ret)
    }

    func scatterPhoton(_ state: ShadingState, _ power: Color) {
        let refr: Color = Color.mul(1 - f0, color!)
        let refl: Color = Color.mul(f0, color!)

        let avgR: Float = refl.getAverage()
        let avgT: Float = refr.getAverage()

        let rnd: Double = state.getRandom(0, 0, 1)

        if rnd < Double(avgR) {
            state.faceforward()

            //  don't reflect internally
            if state.isBehind() {
                return
            }

            //  photon is reflected
            let cos: Float = state.getCosND()

            power.mul(refl).mul(1.0 / avgR)

            let dn: Float = 2 * cos
            let dir: Vector3 = Vector3()

            dir.x = (dn * state.getNormal()!.x) + state.getRay()!.getDirection().x
            dir.y = (dn * state.getNormal()!.y) + state.getRay()!.getDirection().y
            dir.z = (dn * state.getNormal()!.z) + state.getRay()!.getDirection().z

            state.traceReflectionPhoton(Ray(state.getPoint(), dir), power)
        } else if rnd < Double(avgR + avgT) {
            state.faceforward()

            //  photon is refracted
            let cos: Float = state.getCosND()
            let neta: Float = (state.isBehind() ? eta : 1.0 / eta)

            power.mul(refr).mul(1.0 / avgT)

            let wK: Float = -neta
            let arg: Float = 1 - (neta * neta * (1 - (cos * cos)))
            let dir: Vector3 = Vector3()

            if state.isBehind(), absorptionDistance > 0 {
                //  this ray is inside the object and leaving it
                //  compute attenuation that occured along the ray
                power.mul(Color.mul(-state.getRay()!.getMax() / absorptionDistance, absorptionColor!.copy().opposite()).cExp())
            }

            if arg < 0 {
                //  TIR
                let dn: Float = 2 * cos

                dir.x = (dn * state.getNormal()!.x) + state.getRay()!.getDirection().x
                dir.y = (dn * state.getNormal()!.y) + state.getRay()!.getDirection().y
                dir.z = (dn * state.getNormal()!.z) + state.getRay()!.getDirection().z

                state.traceReflectionPhoton(Ray(state.getPoint(), dir), power)
            } else {
                let nK: Float = (neta * cos) - sqrt(arg)

                dir.x = (-wK * state.getRay()!.dx) + (nK * state.getNormal()!.x)
                dir.y = (-wK * state.getRay()!.dy) + (nK * state.getNormal()!.y)
                dir.z = (-wK * state.getRay()!.dz) + (nK * state.getNormal()!.z)

                state.traceRefractionPhoton(Ray(state.getPoint(), dir), power)
            }
        }
    }
}
