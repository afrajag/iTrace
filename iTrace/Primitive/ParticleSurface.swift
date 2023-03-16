//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class ParticleSurface: PrimitiveList {
    var particles: [Float]?
    var n: Int32 = 0
    var r: Float = 0.0
    var r2: Float = 0.0

    required init() {
        particles = nil
        r = 1
        r2 = 1
        n = 0
    }

    func getNumPrimitives() -> Int32 {
        return n
    }

    func getPrimitiveBound(_ primID: Int32, _ i: Int32) -> Float {
        let c: Float = particles![Int((primID * 3) + (i >>> 1))]
        
        return (i & 1) == 0 ? c - r : c + r
    }

    func getWorldBounds(_ o2w: AffineTransform?) -> BoundingBox? {
        let bounds: BoundingBox? = BoundingBox()
        
        var i3 = 0
        
        for _ in 0 ..< n {
            bounds!.include(particles![Int(i3)], particles![Int(i3) + 1], particles![Int(i3) + 2])
            
            i3 += 3
        }
        
        bounds!.include(bounds!.getMinimum().x - r, bounds!.getMinimum().y - r, bounds!.getMinimum().z - r)
        bounds!.include(bounds!.getMaximum().x + r, bounds!.getMaximum().y + r, bounds!.getMaximum().z + r)
        
        return o2w == nil ? bounds : o2w!.transform(bounds!)
    }

    func intersectPrimitive(_ r: Ray, _ primID: Int32, _ state: IntersectionState) {
        let i3: Int32 = primID * 3
        
        let ocx: Float = r.ox - particles![Int(i3) + 0]
        let ocy: Float = r.oy - particles![Int(i3) + 1]
        let ocz: Float = r.oz - particles![Int(i3) + 2]
        
        let qa: Float = r.dx * r.dx + r.dy * r.dy + r.dz * r.dz
        let qb: Float = 2 * ((r.dx * ocx) + (r.dy * ocy) + (r.dz * ocz))
        let qc: Float = ((ocx * ocx) + (ocy * ocy) + (ocz * ocz)) - r2
        
        let t: [Double]? = Solvers.solveQuadric(Double(qa), Double(qb), Double(qc))
        
        if t != nil {
            //  early rejection
            if (t![0] >= Double(r.getMax())) || (t![1] <= Double(r.getMin())) {
                return
            }
            
            if t![0] > Double(r.getMin()) {
                r.setMax(Float(t![0]))
            } else {
                r.setMax(Float(t![1]))
            }
            
            state.setIntersection(primID)
        }
    }

    func prepareShadingState(_ state: ShadingState) {
        state.initState()
        
        state.getRay()!.getPoint(state.getPoint())
        
        let localPoint: Point3? = state.transformWorldToObject(state.getPoint())
        
        localPoint!.x = localPoint!.x - particles![(3 * Int(state.getPrimitiveID())) + 0]
        localPoint!.y = localPoint!.y - particles![(3 * Int(state.getPrimitiveID())) + 1]
        localPoint!.z = localPoint!.z - particles![(3 * Int(state.getPrimitiveID())) + 2]
        
        state.getNormal()!.set(localPoint!.x, localPoint!.y, localPoint!.z)
        
        state.getNormal()!.normalize()
        
        state.setShader(state.getInstance()!.getShader(0))
        
        state.setModifier(state.getInstance()!.getModifier(0))
        
        //  into object space
        let worldNormal: Vector3? = state.transformNormalObjectToWorld(state.getNormal()!)
        
        state.getNormal()!.set(worldNormal!)
        
        state.getNormal()!.normalize()
        
        state.getGeoNormal()!.set(state.getNormal()!)
        
        state.setBasis(OrthoNormalBasis.makeFromW(state.getNormal()!))
    }

    func update(_ pl: ParameterList) -> Bool {
        let p: ParameterList.FloatParameter? = pl.getPointArray("particles")
        
        if p != nil {
            particles = p!.data
        }
        
        r = pl.getFloat("radius", r)!
        
        r2 = r * r
        
        n = pl.getInt("num", n)!
        
        return particles != nil && n <= (particles!.count / 3)
    }

    func getBakingPrimitives() -> PrimitiveList? {
        return nil
    }
}
