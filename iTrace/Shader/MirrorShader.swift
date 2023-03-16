//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class MirrorShader: Shader {
    var color: Color?

    required init() {
        color = Color.WHITE
    }

    func update(_ pl: ParameterList) -> Bool {
        color = pl.getColor("color", color!)
        return true
    }

    func getRadiance(_ state: ShadingState) -> Color {
        if !state.includeSpecular {
            return Color.BLACK
        }

        state.faceforward()

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

        ret.sub(color!)

        ret.mul(cos5)

        ret.add(color!)

        return ret.mul(state.traceReflection(refRay, 0))
    }

    func scatterPhoton(_ state: ShadingState, _ power: Color) {
        let avg: Float = color!.getAverage()
        let rnd: Double = state.getRandom(0, 0, 1)

        if rnd >= Double(avg) {
            return
        }

        state.faceforward()

        let cos: Float = state.getCosND()

        power.mul(color!).mul(1.0 / avg)

        //  photon is reflected
        let dn: Float = 2 * cos
        let dir: Vector3 = Vector3()

        dir.x = (dn * state.getNormal()!.x) + state.getRay()!.getDirection().x
        dir.y = (dn * state.getNormal()!.y) + state.getRay()!.getDirection().y
        dir.z = (dn * state.getNormal()!.z) + state.getRay()!.getDirection().z

        state.traceReflectionPhoton(Ray(state.getPoint(), dir), power)
    }
}
