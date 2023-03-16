//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class QuickGrayShader: Shader {
    required init() {}

    func update(_ pl: ParameterList) -> Bool {
        return true
    }

    func getRadiance(_ state: ShadingState) -> Color {
        if state.getNormal() == nil {
            //  if this shader has been applied to an infinite instance because of shader overrides
            //  run the default shader, otherwise, just shade black
            // FIXME: controllare se description va bene o serve per forza Equatable
            return state.getShader()!.description != self.description ? state.getShader()!.getRadiance(state) : Color.BLACK
        }
        
        //  make sure we are on the right side of the material
        state.faceforward()
        
        //  setup lighting
        state.initLightSamples()
        
        state.initCausticSamples()
        
        return state.diffuse(Color.GRAY)
    }

    func scatterPhoton(_ state: ShadingState, _ power: Color) {
        var diffuse: Color
        
        //  make sure we are on the right side of the material
        if Vector3.dot(state.getNormal()!, state.getRay()!.getDirection()) > 0.0 {
            state.getNormal()!.negate()
            
            state.getGeoNormal()!.negate()
        }
        
        diffuse = Color.GRAY
        
        state.storePhoton(state.getRay()!.getDirection(), power, diffuse)
        
        let avg: Float = diffuse.getAverage()
        let rnd: Double = state.getRandom(0, 0, 1)
        
        if rnd < Double(avg) {
            //  photon is scattered
            power.mul(diffuse).mul(1.0 / avg)
            
            let onb: OrthoNormalBasis = state.getBasis()!
            let u: Double = (2 * Double.pi * rnd) / Double(avg)
            let v: Double = state.getRandom(0, 1, 1)
            let s: Float = sqrt(Float(v))
            let s1: Float = sqrt(1.0 - Float(v))
            var w: Vector3 = Vector3(cos(Float(u)) * s, sin(Float(u)) * s, s1)
            
            w = onb.transform(w, Vector3())
            
            state.traceDiffusePhoton(Ray(state.getPoint(), w), power)
        }
    }
}
