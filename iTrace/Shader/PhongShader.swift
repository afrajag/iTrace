//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

class PhongShader: Shader {
    var diff: Color?
    var spec: Color?
    var power: Float = 0.0
    var numRays: Int32 = 0

    required init() {
        diff = Color.GRAY
        spec = Color.GRAY
        power = 20
        numRays = 4
    }

    func update(_ pl: ParameterList) -> Bool {
        diff = pl.getColor("diffuse", diff)!
        spec = pl.getColor("specular", spec)!
        power = pl.getFloat("power", power)!
        numRays = pl.getInt("samples", numRays)!
        
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
        
        //  execute shader
        return state.diffuse(getDiffuse(state)).add(state.specularPhong(spec!, power, numRays))
    }

    func scatterPhoton(_ state: ShadingState, _ power: Color) {
        //  make sure we are on the right side of the material
        state.faceforward()
        
        let d: Color = getDiffuse(state)
        
        state.storePhoton(state.getRay()!.getDirection(), power, d)
        
        let avgD: Float = d.getAverage()
        let avgS: Float = spec!.getAverage()
        let rnd: Double = state.getRandom(0, 0, 1)
        
        if rnd < Double(avgD) {
            //  photon is scattered diffusely
            power.mul(d).mul(1.0 / avgD)
            
            let onb: OrthoNormalBasis = state.getBasis()!
            let u: Double = 2 * Double.pi * rnd / Double(avgD)
            let v: Double = state.getRandom(0, 1, 1)
            let s: Float = Float(sqrt(v))
            let s1: Float = Float(sqrt(1.0 - v))
            var w: Vector3 = Vector3(Float(cos(u)) * s, Float(sin(u)) * s, s1)
            
            w = onb.transform(w, Vector3())
            
            state.traceDiffusePhoton(Ray(state.getPoint(), w), power)
        } else if rnd < Double(avgD + avgS) {
            //  photon is scattered specularly
            let dn: Float = 2.0 * state.getCosND()
            
            //  reflected direction
            let refDir: Vector3 = Vector3()
            
            refDir.x = (dn * state.getNormal()!.x) + state.getRay()!.dx
            refDir.y = (dn * state.getNormal()!.y) + state.getRay()!.dy
            refDir.z = (dn * state.getNormal()!.z) + state.getRay()!.dz
            
            power.mul(spec!).mul(1.0 / avgS)
            
            let onb: OrthoNormalBasis = state.getBasis()!
            let u: Double = 2 * Double.pi * (rnd - Double(avgD)) / Double(avgS)
            let v: Double = state.getRandom(0, 1, 1)
            let s: Float = pow(Float(v), 1 / (self.power + 1))
            let s1: Float = sqrt(1 - s * s)
            var w: Vector3 = Vector3(Float(cos(u)) * s1, Float(sin(u)) * s1, s)
            
            w = onb.transform(w, Vector3())
            
            state.traceReflectionPhoton(Ray(state.getPoint(), w), power)
        }
    }
}
