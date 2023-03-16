//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class Torus: PrimitiveList {
    var ri2: Float = 0.0
    var ro2: Float = 0.0
    var ri: Float = 0.0
    var ro: Float = 0.0

    required init() {
        ri = 0.25
        ro = 1
        ri2 = ri * ri
        ro2 = ro * ro
    }

    func update(_ pl: ParameterList) -> Bool {
        ri = pl.getFloat("radiusInner", ri)!
        ro = pl.getFloat("radiusOuter", ro)!
        
        ri2 = ri * ri
        
        ro2 = ro * ro
        
        return true
    }

    func getWorldBounds(_ o2w: AffineTransform?) -> BoundingBox? {
        var bounds: BoundingBox? = BoundingBox(-ro - ri, -ro - ri, -ri)
        
        bounds!.include(ro + ri, ro + ri, ri)
        
        if o2w != nil {
            bounds = o2w!.transform(bounds!)
        }
        
        return bounds
    }

    func getPrimitiveBound(_: Int32, _ i: Int32) -> Float {
        switch i {
            case 0,
                 2:
                return -ro - ri
            case 1,
                 3:
                return ro + ri
            case 4:
                return -ri
            case 5:
                return ri
            default:
                return 0
        }
    }

    func getNumPrimitives() -> Int32 {
        return 1
    }

    func prepareShadingState(_ state: ShadingState) {
        state.initState()
        
        state.getRay()!.getPoint(state.getPoint())
        
        let parent: Instance? = state.getInstance()
        
        //  get local point
        let p: Point3 = state.transformWorldToObject(state.getPoint())
        
        //  compute local normal
        let deriv: Float = p.x * p.x + p.y * p.y + p.z * p.z - ri2 - ro2
        
        state.getNormal()!.set(p.x * deriv, p.y * deriv, p.z * deriv + 2 * ro2 * p.z)
        
        state.getNormal()!.normalize()
        
        let phi: Double = Double(asin((p.z / ri).clamp(-1, 1)))
        var theta: Double = Double(atan2(p.y, p.x))
        
        if theta < 0 {
            theta += 2 * Double.pi
        }
        
        state.getUV()!.x = Float(theta / (2 * Double.pi))
        state.getUV()!.y = Float((phi + Double.pi / 2) / Double.pi)
        
        state.setShader(parent!.getShader(0))
        
        state.setModifier(parent!.getModifier(0))
        
        //  into world space
        let worldNormal: Vector3 = state.transformNormalObjectToWorld(state.getNormal()!)
        
        state.getNormal()!.set(worldNormal)
        
        state.getNormal()!.normalize()
        
        state.getGeoNormal()!.set(state.getNormal()!)
        
        //  make basis in world space
        state.setBasis(OrthoNormalBasis.makeFromW(state.getNormal()!))
    }

    func intersectPrimitive(_ r: Ray, _: Int32, _ state: IntersectionState) {
        //  intersect in local space
        let rd2x: Float = r.dx * r.dx
        let rd2y: Float = r.dy * r.dy
        let rd2z: Float = r.dz * r.dz
        let ro2x: Float = r.ox * r.ox
        let ro2y: Float = r.oy * r.oy
        let ro2z: Float = r.oz * r.oz
        
        //  compute some common factors
        let alpha: Double = Double(rd2x + rd2y + rd2z)
        let beta: Double = Double(2 * (r.ox * r.dx + r.oy * r.dy + r.oz * r.dz))
        let gamma: Double = Double((ro2x + ro2y + ro2z) - ri2 - ro2)
        
        //  setup quartic coefficients
        let A: Double = alpha * alpha
        let B: Double = 2 * alpha * beta
        let C: Double = beta * beta + 2 * alpha * gamma + 4 * Double(ro2) * Double(rd2z)
        let D: Double = 2 * beta * gamma + 8 * Double(ro2) * Double(r.oz) * Double(r.dz)
        let E: Double = gamma * gamma + 4 * Double(ro2) * Double(ro2z) - 4 * Double(ro2) * Double(ri2)
        
        //  solve equation
        let t: [Double]? = Solvers.solveQuartic(A, B, C, D, E)
        
        if t != nil {
            //  early rejection
            if (t![0] >= Double(r.getMax())) || (t![t!.count - 1] <= Double(r.getMin())) {
                return
            }
            
            //  find first intersection in front of the ray
            for i in 0 ..< t!.count {
                if t![i] > Double(r.getMin()) {
                    r.setMax(Float(t![Int(i)]))
                    
                    state.setIntersection(0)
                    
                    return
                }
            }
        }
    }

    func getBakingPrimitives() -> PrimitiveList? {
        return nil
    }
}
