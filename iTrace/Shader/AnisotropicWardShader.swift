//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

class AnisotropicWardShader: Shader {
    var rhoD: Color?    // diffuse reflectance
    var rhoS: Color?    // specular reflectance
    var alphaX: Float = 0.0
    var alphaY: Float = 0.0
    var numRays: Int32 = 0

    required init() {
        rhoD = Color.GRAY
        rhoS = Color.GRAY
        alphaX = 1
        alphaY = 1
        numRays = 4
    }

    func update(_ pl: ParameterList) -> Bool {
        rhoD = pl.getColor("diffuse", rhoD)
        rhoS = pl.getColor("specular", rhoS)
        
        alphaX = pl.getFloat("roughnessX", alphaX)!
        alphaY = pl.getFloat("roughnessY", alphaY)!
        
        numRays = pl.getInt("samples", numRays)!
        
        return true
    }

    func getDiffuse(_: ShadingState) -> Color {
        return rhoD!
    }

    func brdf(_ i: Vector3, _ o: Vector3, _ basis: OrthoNormalBasis) -> Float {
        var fr: Float = 4 * Float.pi * alphaX * alphaY
        let p: Float = basis.untransformZ(i) * basis.untransformZ(o)
        
        if p > 0 {
            fr *= sqrt(p)
        } else {
            fr = 0
        }
        
        let h: Vector3 = i + o
        
        basis.untransform(h)
        
        var hx: Float = h.x / alphaX
        
        hx *= hx
        
        var hy: Float = h.y / alphaY
        
        hy *= hy
        
        let hn: Float = h.z * h.z
        
        if fr > 0 {
            fr = exp(-(hx + hy) / hn) / fr
        }
        
        return fr
    }

    func getRadiance(_ state: ShadingState) -> Color {
        //  make sure we are on the right side of the material
        state.faceforward()
        
        let onb: OrthoNormalBasis = state.getBasis()!
        
        //  direct lighting and caustics
        state.initLightSamples()
        
        state.initCausticSamples()
        
        let lr: Color = Color.black()
        
        //  compute specular contribution
        if state.includeSpecular {
            let dir: Vector3 = state.getRay()!.getDirection()
            let inv: Vector3 = dir.negate()
            
            for sample in state.lightSampleList {
                let cosNL: Float = sample.dot(state.getNormal()!)
                let fr: Float = brdf(inv, sample.getShadowRay().getDirection(), onb)
                
                lr.madd(cosNL * fr, sample.getSpecularRadiance())
            }
            
            //  indirect lighting - specular
            if numRays > 0 {
                let n: Int32 = state.getDepth() == 0 ? numRays: 1
                
                for i in 0 ..< n {
                    //  specular indirect lighting
                    let r1: Double = state.getRandom(i, 0, n)
                    let r2: Double = state.getRandom(i, 1, n)
                    
                    let alphaRatio: Float = alphaY / alphaX
                    
                    var phi: Float = 0
                    
                    if r1 < 0.25 {
                        let val: Double = 4 * r1
                        
                        phi = atan(alphaRatio * tan(Float.pi / 2 * Float(val)))
                    } else if r1 < 0.5 {
                        let val: Double = 1 - 4 * (0.5 - r1)
                        
                        phi = atan(alphaRatio * tan(Float.pi / 2 * Float(val)))
                        
                        phi = Float.pi - phi
                    } else if r1 < 0.75 {
                            let val: Double = 4 * (r1 - 0.5)
                            
                            phi = atan(alphaRatio * tan(Float.pi / 2 * Float(val)))
                            
                            phi += Float.pi
                    } else {
                        let val: Double = 1 - 4 * (1 - r1)
                        
                        phi = atan(alphaRatio * tan(Float.pi / 2 * Float(val)))
                        
                        phi = 2 * Float.pi - phi
                    }
                    
                    let cosPhi: Float = cos(phi)
                    let sinPhi: Float = sin(phi)
                    
                    let denom: Float = (cosPhi * cosPhi) / (alphaX * alphaX) + (sinPhi * sinPhi) / (alphaY * alphaY)
                    let theta: Float = atan(sqrt(-log(1 - Float(r2)) / denom))
                    
                    let sinTheta: Float = sin(theta)
                    let cosTheta: Float = cos(theta)
                    
                    let h: Vector3 = Vector3()
                    
                    h.x = sinTheta * cosPhi
                    h.y = sinTheta * sinPhi
                    h.z = cosTheta
                    
                    onb.transform(h)
                    
                    let o: Vector3 = Vector3()
                    let ih: Float = Vector3.dot(h, inv)
                    
                    o.x = 2 * ih * h.x - inv.x
                    o.y = 2 * ih * h.y - inv.y
                    o.z = 2 * ih * h.z - inv.z
                    
                    let no: Float = onb.untransformZ(o)
                    let ni: Float = onb.untransformZ(inv)
                    
                    let w: Float = ih * cosTheta * cosTheta * cosTheta * sqrt(abs(no / ni))
                    
                    let r: Ray = Ray(state.getPoint(), o)
                    
                    lr.madd(w / Float(n), state.traceGlossy(r, i))
                }
            }
            
            lr.mul(rhoS!)
        }
        
        //  add diffuse contribution
        lr.add(state.diffuse(getDiffuse(state)))
        
        return lr
    }

    func scatterPhoton(_ state: ShadingState, _ power: Color) {
        //  make sure we are on the right side of the material
        state.faceforward()
        
        let d: Color = getDiffuse(state)
        
        state.storePhoton(state.getRay()!.getDirection(), power, d)
        
        let avgD: Float = d.getAverage()
        let avgS: Float = rhoS!.getAverage()
        
        let rnd: Double = state.getRandom(0, 0, 1)
        
        if rnd < Double(avgD) {
            //  photon is scattered diffusely
            power.mul(d).mul(1.0 / avgD)
            
            let onb: OrthoNormalBasis = state.getBasis()!
            let u: Double = 2 * Double.pi * rnd / Double(avgD)
            let v: Double = state.getRandom(0, 1, 1)
            let s: Float = sqrt(Float(v))
            let s1: Float = sqrt(Float(1.0 - v))
            var w: Vector3 = Vector3(cos(Float(u)) * s, sin(Float(u)) * s, s1)
            
            w = onb.transform(w, Vector3())
            
            state.traceDiffusePhoton(Ray(state.getPoint(), w), power)
        } else {
            if rnd < Double((avgD + avgS)) {
                //  photon is scattered specularly
                power.mul(rhoS!).mul(1 / avgS)
                
                let basis: OrthoNormalBasis = state.getBasis()!
                let dir: Vector3 = state.getRay()!.getDirection()
                let inv: Vector3 = dir.negate()
                let r1: Double = rnd / Double(avgS)
                let r2: Double = state.getRandom(0, 1, 1)
                
                let alphaRatio: Float = alphaY / alphaX
                var phi: Float = 0
                
                if r1 < 0.25 {
                    let val: Double = 4 * r1
                    
                    phi = atan(alphaRatio * tan(Float.pi / 2 * Float(val)))
                } else if r1 < 0.5 {
                    let val: Double = 1 - 4 * (0.5 - r1)
                    
                    phi = atan(alphaRatio * tan(Float.pi / 2 * Float(val)))
                    
                    phi = Float.pi - phi
                } else if r1 < 0.75 {
                    let val: Double = 4 * (r1 - 0.5)
                    
                    phi = atan(alphaRatio * tan(Float.pi / 2 * Float(val)))
                    
                    phi += Float.pi
                } else {
                    let val: Double = 1 - 4 * (1 - r1)
                    
                    phi = atan(alphaRatio * tan(Float.pi / 2 * Float(val)))
                    
                    phi = 2 * Float.pi - phi
                }
                
                let cosPhi: Float = cos(phi)
                let sinPhi: Float = sin(phi)
                
                let denom: Float = (cosPhi * cosPhi) / (alphaX * alphaX) + (sinPhi * sinPhi) / (alphaY * alphaY)
                let theta: Float = atan(sqrt(-log(1 - Float(r2)) / denom))
                
                let sinTheta: Float = sin(theta)
                let cosTheta: Float = cos(theta)
                
                let h: Vector3 = Vector3()
                
                h.x = sinTheta * cosPhi
                h.y = sinTheta * sinPhi
                h.z = cosTheta
                
                basis.transform(h)
                
                let o: Vector3 = Vector3()
                let ih: Float = Vector3.dot(h, inv)
                
                o.x = 2 * ih * h.x - inv.x
                o.y = 2 * ih * h.y - inv.y
                o.z = 2 * ih * h.z - inv.z
                
                let r: Ray = Ray(state.getPoint(), o)
                
                state.traceReflectionPhoton(r, power)
            }
        }
    }
}
