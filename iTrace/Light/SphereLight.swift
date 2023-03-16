//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class SphereLight: LightSource, Shader {
    var radiance: Color?
    var numSamples: Int32 = 0
    var center: Point3?
    var radius: Float = 0.0
    var r2: Float = 0.0

    required init() {
        radiance = Color.WHITE
        numSamples = 4
        center = Point3()
        radius = 1
        r2 = 1
    }

    func update(_ pl: ParameterList) -> Bool {
        radiance = pl.getColor(LightParameter.PARAM_RADIANCE, radiance)
        numSamples = pl.getInt(LightParameter.PARAM_SAMPLES, numSamples)!
        radius = pl.getFloat(SphereLightParameter.PARAM_RADIUS, radius)!
        
        r2 = radius * radius
        
        center = pl.getPoint(SphereLightParameter.PARAM_CENTER, center)
        
        return true
    }

    func getNumSamples() -> Int32 {
        return numSamples
    }

    func getLowSamples() -> Int32 {
        return 1
    }

    func isVisible(_ state: ShadingState) -> Bool {
        return state.getPoint().distanceToSquared(center!) > r2
    }

    func getSamples(_ state: ShadingState) {
        if getNumSamples() <= 0 {
            return
        }
        
        let wc: Vector3 = Point3.sub(center!, state.getPoint())
        let l2: Float = wc.squaredLength
        
        if l2 <= r2 {
            return //  inside the sphere
        }

        //  top of the sphere as viewed from the current shading point
        let topX: Float = wc.x + (state.getNormal()!.x * radius)
        let topY: Float = wc.y + (state.getNormal()!.y * radius)
        let topZ: Float = wc.z + (state.getNormal()!.z * radius)
        
        if state.getNormal()!.dot(topX, topY, topZ) <= 0 {
            return //  top of the sphere is below the horizon
        }

        let cosThetaMax: Float = Float(sqrt(max(0, 1 - (r2 / Vector3.dot(wc, wc)))))
        let basis: OrthoNormalBasis = OrthoNormalBasis.makeFromW(wc)
        let samples: Int32 = (state.getDiffuseDepth() > 0 ? 1 : getNumSamples())
        let scale: Float = 2 * Float.pi * (1 - cosThetaMax)
        let c: Color = Color.mul(scale / Float(samples), radiance!)
        
        for i in 0 ..< samples {
            //  random offset on unit square
            let randX: Double = state.getRandom(i, 0, samples)
            let randY: Double = state.getRandom(i, 1, samples)
            
            //  cone sampling
            let cosTheta: Double = (1 - randX) * Double(cosThetaMax) + randX
            let sinTheta: Double = sqrt(1 - cosTheta * cosTheta)
            let phi: Double = randY * 2 * Double.pi
            let dir: Vector3 = Vector3(cos(Float(phi)) * Float(sinTheta), sin(Float(phi)) * Float(sinTheta), Float(cosTheta))
            
            basis.transform(dir)
            
            //  check that the direction of the sample is the same as the
            //  normal
            let cosNx: Float = Vector3.dot(dir, state.getNormal()!)
            
            if cosNx <= 0 {
                continue
            }
            
            let ocx: Float = state.getPoint().x - center!.x
            let ocy: Float = state.getPoint().y - center!.y
            let ocz: Float = state.getPoint().z - center!.z
            let qa: Float = Vector3.dot(dir, dir)
            let qb: Float = 2 * ((dir.x * ocx) + (dir.y * ocy) + (dir.z * ocz))
            let qc: Float = ((ocx * ocx) + (ocy * ocy) + (ocz * ocz)) - r2
            let t: [Double]? = Solvers.solveQuadric(Double(qa), Double(qb), Double(qc))
            
            if t == nil {
                continue
            }
            
            let dest: LightSample = LightSample()
            
            //  compute shadow ray to the sampled point
            dest.setShadowRay(Ray(state.getPoint(), dir))
            
            //  FIXME: arbitrary bias, should handle as in other places
            dest.getShadowRay().setMax(Float(t![0]) - 1e-3)
            
            //  prepare sample
            dest.setRadiance(c, c)
            
            dest.traceShadow(state)
            
            state.addSample(dest)
        }
    }

    func getPhoton(_ randX1: Double, _ randY1: Double, _ randX2: Double, _ randY2: Double, _ p: Point3, _ dir: Vector3, _ power: Color) {
        let z: Float = Float(1 - 2 * randX2)
        let r: Float = Float(sqrt(max(0, 1 - z * z)))
        var phi: Float = 2 * Float.pi * Float(randY2)
        let x: Float = r * Float(cos(phi))
        let y: Float = r * Float(sin(phi))
        
        p.x = center!.x + x * radius
        p.y = center!.y + y * radius
        p.z = center!.z + z * radius
        
        let basis: OrthoNormalBasis = OrthoNormalBasis.makeFromW(Vector3(x, y, z))
        
        phi = 2 * Float.pi * Float(randX1)
        
        let cosPhi: Float = Float(cos(phi))
        let sinPhi: Float = Float(sin(phi))
        let sinTheta: Float = Float(sqrt(randY1))
        let cosTheta: Float = Float(sqrt(1 - randY1))
        
        dir.x = cosPhi * sinTheta
        dir.y = sinPhi * sinTheta
        dir.z = cosTheta
        
        basis.transform(dir)
        
        power.set(radiance!)
        
        power.mul(Float.pi * Float.pi * 4 * r2)
    }

    func getPower() -> Float {
        return radiance!.copy().mul(Float.pi * Float.pi * 4 * r2).getLuminance()
    }

    func getRadiance(_ state: ShadingState) -> Color {
        if !state.includeLights {
            return Color.BLACK
        }
        
        state.faceforward()
        
        //  emit constant radiance
        return state.isBehind() ? Color.BLACK : radiance!
    }

    func scatterPhoton(_: ShadingState, _: Color) {
        //  do not scatter photons
        //
    }

    func createInstance() -> Instance? {
        return Instance.createTemporary(Sphere(), AffineTransform.translation(center!.x, center!.y, center!.z).multiply(AffineTransform.scale(radius)), self)
    }
}
