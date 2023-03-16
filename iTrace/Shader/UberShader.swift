//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class UberShader: Shader {
    var diff: Color?
    var spec: Color?
    var diffmap: Texture?
    var specmap: Texture?
    var diffBlend: Float = 0.0
    var specBlend: Float = 0.0
    var glossyness: Float = 0.0
    var numSamples: Int32 = 0

    required init() {
        diff = Color.GRAY
        spec = Color.GRAY
        diffmap = nil
        specmap = nil
        diffBlend = 1
        specBlend = 1
        glossyness = 0
        numSamples = 4
    }

    func update(_ pl: ParameterList) -> Bool {
        diff = pl.getColor("diffuse", diff)!
        spec = pl.getColor("specular", spec)!
        
        var filename = pl.getString("diffuse.texture", nil)
        
        if filename != nil {
            diffmap = TextureCache.getTexture(API.shared.resolveTextureFilename(filename!), false)
        }
        
        filename = pl.getString("specular.texture", nil)
        
        if filename != nil {
            specmap = TextureCache.getTexture(API.shared.resolveTextureFilename(filename!), false)
        }
        
        diffBlend = pl.getFloat("diffuse.blend", diffBlend)!.clamp(0, 1)
        specBlend = pl.getFloat("specular.blend", diffBlend)!.clamp(0, 1)
        
        glossyness = pl.getFloat("glossyness", glossyness)!.clamp(0, 1)
        numSamples = pl.getInt("samples", numSamples)!
        
        return true
    }

    func getDiffuse(_ state: ShadingState) -> Color {
        return ((diffmap == nil ? diff : Color.blend(diff!, diffmap!.getPixel(state.getUV()!.x, state.getUV()!.y), diffBlend))!)
    }

    func getSpecular(_ state: ShadingState) -> Color {
        return ((specmap == nil ? spec : Color.blend(spec!, specmap!.getPixel(state.getUV()!.x, state.getUV()!.y), specBlend))!)
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
        
        if glossyness == 0 {
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
            let spec: Color = getSpecular(state)
            let ret: Color = Color.white()
            
            ret.sub(spec)
            ret.mul(cos5)
            ret.add(spec)
            
            return lr.add(ret.mul(state.traceReflection(refRay, 0)))
        } else {
            return lr.add(state.specularPhong(getSpecular(state), 2 / glossyness, numSamples))
        }
    }

    func scatterPhoton(_ state: ShadingState, _ power: Color) {
        var diffuse: Color
        var specular: Color
        
        //  make sure we are on the right side of the material
        state.faceforward()
        
        diffuse = getDiffuse(state)
        
        specular = getSpecular(state)
        
        state.storePhoton(state.getRay()!.getDirection(), power, diffuse)
        
        let d: Float = diffuse.getAverage()
        let r: Float = specular.getAverage()
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
        } else if rnd < Double(d + r) {
            if glossyness == 0 {
                let cos: Float = -Vector3.dot(state.getNormal()!, state.getRay()!.getDirection())
                
                power.mul(diffuse).mul(1.0 / d)
                
                //  photon is reflected
                let dn: Float = 2 * cos
                let dir: Vector3 = Vector3()
                
                dir.x = (dn * state.getNormal()!.x) + state.getRay()!.getDirection().x
                dir.y = (dn * state.getNormal()!.y) + state.getRay()!.getDirection().y
                dir.z = (dn * state.getNormal()!.z) + state.getRay()!.getDirection().z
                
                state.traceReflectionPhoton(Ray(state.getPoint(), dir), power)
            } else {
                let dn: Float = 2.0 * state.getCosND()
                
                //  reflected direction
                let refDir: Vector3 = Vector3()
                
                refDir.x = (dn * state.getNormal()!.x) + state.getRay()!.dx
                refDir.y = (dn * state.getNormal()!.y) + state.getRay()!.dy
                refDir.z = (dn * state.getNormal()!.z) + state.getRay()!.dz
                
                power.mul(spec!).mul(1.0 / r)
                
                let onb: OrthoNormalBasis = state.getBasis()!
                let u: Double = 2 * Double.pi * (rnd - Double(r)) / Double(r)
                let v: Double = state.getRandom(0, 1, 1)
                let s: Float = pow(Float(v), 1 / ((1.0 / glossyness) + 1))
                let s1: Float = sqrt(1 - s * s)
                var w: Vector3 = Vector3(Float(cos(u)) * s1, Float(sin(u)) * s1, s)
                
                w = onb.transform(w, Vector3())
                
                state.traceReflectionPhoton(Ray(state.getPoint(), w), power)
            }
        }
    }
}
