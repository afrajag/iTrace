//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class Cylinder: PrimitiveList {
    required init() {}
    
    func update(_ pl: ParameterList) -> Bool {
        return true
    }

    func getWorldBounds(_ o2w: AffineTransform?) -> BoundingBox? {
        var bounds: BoundingBox = BoundingBox(1)

        if o2w != nil {
            bounds = o2w!.transform(bounds)
        }

        return bounds
    }

    func getPrimitiveBound(_: Int32, _ i: Int32) -> Float {
        return (i & 1) == 0 ? -1 : 1
    }

    func getNumPrimitives() -> Int32 {
        return 1
    }

    func prepareShadingState(_ state: ShadingState) {
        state.initState()
        
        state.getRay()!.getPoint(state.getPoint())
        
        let parent: Instance = state.getInstance()!
        let localPoint: Point3 = state.transformWorldToObject(state.getPoint())
        
        state.getNormal()!.set(localPoint.x, localPoint.y, 0)
        
        state.getNormal()!.normalize()
        
        var phi: Float = atan2(state.getNormal()!.y, state.getNormal()!.x)
        
        if phi < 0 {
            phi += (2.0 * Float.pi)
        }
        
        state.getUV()!.x = phi / (2 * Float.pi)
        state.getUV()!.y = (localPoint.z + 1) * 0.5
        
        state.setShader(parent.getShader(0))
        
        state.setModifier(parent.getModifier(0))
        
        //  into world space
        let worldNormal: Vector3 = state.transformNormalObjectToWorld(state.getNormal()!)
        let v: Vector3 = state.transformVectorObjectToWorld(Vector3(0, 0, 1))
        
        state.getNormal()!.set(worldNormal)
        
        state.getNormal()!.normalize()
        
        state.getGeoNormal()!.set(state.getNormal()!)
        
        //  compute basis in world space
        state.setBasis(OrthoNormalBasis.makeFromWV(state.getNormal()!, v))
    }

    func intersectPrimitive(_ r: Ray, _: Int32, _ state: IntersectionState) {
        //  intersect in local space
        let qa: Float = r.dx * r.dx + r.dy * r.dy
        let qb: Float = 2 * ((r.dx * r.ox) + (r.dy * r.oy))
        let qc: Float = ((r.ox * r.ox) + (r.oy * r.oy)) - 1
        let t: [Double]? = Solvers.solveQuadric(Double(qa), Double(qb), Double(qc))
        
        if t != nil {
            //  early rejection
            if (t![0] >= Double(r.getMax())) || (t![1] <= Double(r.getMin())) {
                return
            }
            
            if t![0] > Double(r.getMin()) {
                let z: Float = r.oz + Float(t![0]) * r.dz
                
                if (z >= -1) && (z <= 1) {
                    r.setMax(Float(t![0]))
                    
                    state.setIntersection(0)
                    
                    return
                }
            }
            
            if t![1] < Double(r.getMax()) {
                let z: Float = r.oz + Float(t![1]) * r.dz
                
                if (z >= -1) && (z <= 1) {
                    r.setMax(Float(t![1]))
                    
                    state.setIntersection(0)
                }
            }
        }
    }

    func getBakingPrimitives() -> PrimitiveList? {
        return nil
    }
}
