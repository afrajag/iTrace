//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class BanchoffSurface: PrimitiveList {
    required init() {}
    
    func update(_ pl: ParameterList) -> Bool {
        return true
    }

    func getWorldBounds(_ o2w: AffineTransform?) -> BoundingBox? {
        var bounds: BoundingBox = BoundingBox(1.5)
        
        if o2w != nil {
            bounds = o2w!.transform(bounds)
        }
        
        return bounds
    }

    func getPrimitiveBound(_: Int32, _ i: Int32) -> Float {
        return (i & 1) == 0 ? -1.5 : 1.5
    }

    func getNumPrimitives() -> Int32 {
        return 1
    }

    func prepareShadingState(_ state: ShadingState) {
        state.initState()
        
        state.getRay()!.getPoint(state.getPoint())
        
        let parent: Instance = state.getInstance()!
        let n: Point3 = state.transformWorldToObject(state.getPoint())
        
        state.getNormal()!.set(n.x * (2 * n.x * n.x - 1), n.y * (2 * n.y * n.y - 1), n.z * (2 * n.z * n.z - 1))
        
        state.getNormal()!.normalize()
        
        state.setShader(parent.getShader(0))
        
        state.setModifier(parent.getModifier(0))
        
        //  into world space
        let worldNormal: Vector3 = state.transformNormalObjectToWorld(state.getNormal()!)
        
        state.getNormal()!.set(worldNormal)
        
        state.getNormal()!.normalize()
        
        state.getGeoNormal()!.set(state.getNormal()!)
        
        //  create basis in world space
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
        
        //  setup the quartic coefficients
        //  some common terms could probably be shared across these
        let A: Double = Double(rd2y * rd2y + rd2z * rd2z + rd2x * rd2x)
        let B: Double = Double(4 * (r.oy * rd2y * r.dy + r.oz * r.dz * rd2z + r.ox * r.dx * rd2x))
        let C: Double = Double(-rd2x - rd2y - rd2z + 6 * (ro2y * rd2y + ro2z * rd2z + ro2x * rd2x))
        let D: Double = Double(2 * (2 * ro2z * r.oz * r.dz - r.oz * r.dz + 2 * ro2x * r.ox * r.dx + 2 * ro2y * r.oy * r.dy - r.ox * r.dx - r.oy * r.dy))
        let E: Double = Double(3.0 / 8.0 + (-ro2z + ro2z * ro2z - ro2y + ro2y * ro2y - ro2x + ro2x * ro2x))
        
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
