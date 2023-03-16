//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class DirectionalSpotlight: LightSource {
    var src: Point3?
    var dir: Vector3?
    var basis: OrthoNormalBasis?
    var radiance: Color?
    var r: Float = 0.0   // Radius
    var r2: Float = 0.0  // Radius^2

    required init() {
        src = Point3(0, 0, 0)
        dir = Vector3(0, 0, -1)
        
        dir!.normalize()
        
        basis = OrthoNormalBasis.makeFromW(dir!)
        
        r = 1
        
        r2 = r * r
        
        radiance = Color.WHITE
    }

    func update(_ pl: ParameterList) -> Bool {
        src = pl.getPoint(DirectionalLightParameter.PARAM_SOURCE, src)!
        dir = pl.getVector(DirectionalLightParameter.PARAM_DIRECTION, dir)!
        
        dir!.normalize()
        
        r = pl.getFloat(DirectionalLightParameter.PARAM_RADIUS, r)!
        
        basis = OrthoNormalBasis.makeFromW(dir!)
        
        r2 = r * r
        
        radiance = pl.getColor(LightParameter.PARAM_RADIANCE, radiance)!
        
        return true
    }

    func getNumSamples() -> Int32 {
        return 1
    }

    func getLowSamples() -> Int32 {
        return 1
    }

    func getSamples(_ state: ShadingState) {
        if (Vector3.dot(dir!, state.getGeoNormal()!) < 0) && (Vector3.dot(dir!, state.getNormal()!) < 0) {
            //  project point onto source plane
            var x: Float = state.getPoint().x - src!.x
            var y: Float = state.getPoint().y - src!.y
            var z: Float = state.getPoint().z - src!.z
            let t: Float = (x * dir!.x) + (y * dir!.y) + (z * dir!.z)
            
            if t >= 0.0 {
                x -= (t * dir!.x)
                y -= (t * dir!.y)
                z -= (t * dir!.z)
                
                if ((x * x) + (y * y) + (z * z)) <= r2 {
                    let p: Point3 = Point3()
                    
                    p.x = src!.x + x
                    p.y = src!.y + y
                    p.z = src!.z + z
                    
                    let dest: LightSample = LightSample()
                    
                    dest.setShadowRay(Ray(state.getPoint(), p))
                    
                    dest.setRadiance(radiance!, radiance!)
                    
                    dest.traceShadow(state)
                    
                    state.addSample(dest)
                }
            }
        }
    }

    func getPhoton(_ randX1: Double, _ randY1: Double, _: Double, _: Double, _ p: Point3, _ dir: Vector3, _ power: Color) {
        let phi: Float = 2 * Float.pi * Float(randX1)
        let s: Float = Float(sqrt(1.0 - randY1))
        
        dir.x = r * Float(cos(phi)) * s
        dir.y = r * Float(sin(phi)) * s
        dir.z = 0
        
        basis!.transform(dir)
        
        p.set(Point3.add(src!, dir))

        dir.set(self.dir!)
        
        power.set(radiance!).mul(Float.pi * r2)
    }

    func getPower() -> Float {
        return radiance!.copy().mul(Float.pi * r2).getLuminance()
    }

    func createInstance() -> Instance? {
        return nil
    }
}
