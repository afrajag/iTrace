//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class JuliaFractal: PrimitiveList {
    static var BOUNDING_RADIUS: Float = sqrt(3)
    static var BOUNDING_RADIUS2: Float = 3
    static var ESCAPE_THRESHOLD: Float = 1e1
    static var DELTA: Float = 1e-4
    
    var cx: Float = 0.0
    var cy: Float = 0.0
    var cz: Float = 0.0
    var cw: Float = 0.0
    var maxIterations: Int32 = 0
    var epsilon: Float = 0.0

    required init() {
        //  good defaults
        cw = -0.4
        cx = 0.2
        cy = 0.3
        cz = -0.2
        
        maxIterations = 15
        epsilon = 0.00001
    }

    func getNumPrimitives() -> Int32 {
        return 1
    }

    func getPrimitiveBound(_: Int32, _ i: Int32) -> Float {
        return (i & 1) == 0 ? -Self.BOUNDING_RADIUS : Self.BOUNDING_RADIUS
    }

    func getWorldBounds(_ o2w: AffineTransform?) -> BoundingBox? {
        var bounds: BoundingBox? = BoundingBox(Self.BOUNDING_RADIUS)
        
        if o2w != nil {
            bounds = o2w!.transform(bounds!)
        }
        
        return bounds
    }

    func intersectPrimitive(_ r: Ray, _: Int32, _ state: IntersectionState) {
        //  intersect with bounding sphere
        let qc: Float = ((r.ox * r.ox) + (r.oy * r.oy) + (r.oz * r.oz)) - Self.BOUNDING_RADIUS2
        var qt: Float = r.getMin()
        
        if qc > 0 {
            //  we are starting outside the sphere, find intersection on the
            //  sphere
            let qa: Float = r.dx * r.dx + r.dy * r.dy + r.dz * r.dz
            let qb: Float = 2 * ((r.dx * r.ox) + (r.dy * r.oy) + (r.dz * r.oz))
            let t: [Double]? = Solvers.solveQuadric(Double(qa), Double(qb), Double(qc))
            
            //  early rejection
            if (t == nil) || (t![0] >= Double(r.getMax())) || (t![1] <= Double(r.getMin())) {
                return
            }
            
            qt = Float(t![0])
        }
        
        var dist: Float = Float.infinity
        var rox: Float = r.ox + qt * r.dx
        var roy: Float = r.oy + qt * r.dy
        var roz: Float = r.oz + qt * r.dz
        let invRayLength: Float = 1 / sqrt(r.dx * r.dx + r.dy * r.dy + r.dz * r.dz)
        
        //  now we can start intersection
        while true {
            var zw: Float = rox
            var zx: Float = roy
            var zy: Float = roz
            var zz: Float = 0
            
            var zpw: Float = 1
            var zpx: Float = 0
            var zpy: Float = 0
            var zpz: Float = 0
            
            //  run several iterations
            var dotz: Float = 0
            
            for _ in 0 ..< maxIterations {
                //  zp = 2 * (z * zp)
                let nw: Float = (zw * zpw) - (zx * zpx) - (zy * zpy) - (zz * zpz)
                let nx: Float = ((zw * zpx) + (zx * zpw) + (zy * zpz)) - (zz * zpy)
                let ny: Float = ((zw * zpy) + (zy * zpw) + (zz * zpx)) - (zx * zpz)
                
                zpz = 2 * (((zw * zpz) + (zz * zpw) + (zx * zpy)) - (zy * zpx))
                zpw = 2 * nw
                zpx = 2 * nx
                zpy = 2 * ny

                //  z = z*z + c
                let _nw: Float = ((zw * zw) - (zx * zx) - (zy * zy) - (zz * zz)) + cw
                
                zx = (2 * zw * zx) + cx
                zy = (2 * zw * zy) + cy
                zz = (2 * zw * zz) + cz
                zw = _nw
                
                dotz = zw * zw + zx * zx + zy * zy + zz * zz
                
                if dotz > Self.ESCAPE_THRESHOLD {
                    break
                }
            }
            
            let normZ: Float = sqrt(dotz)
            
            dist = 0.5 * normZ * log(normZ) / Self.length(zpw, zpx, zpy, zpz)
            
            rox = rox + dist * r.dx
            roy = roy + dist * r.dy
            roz = roz + dist * r.dz
            
            qt += dist
            
            if dist * invRayLength < epsilon {
                break
            }
            
            if (rox * rox + roy * roy + roz * roz > Self.BOUNDING_RADIUS2) {
                return
            }
        }
        
        //  now test t value again
        if !r.isInside(qt) {
            return
        }
        
        if dist * invRayLength < epsilon {
            //  valid hit
            r.setMax(qt)
            
            state.setIntersection(0)
        }
    }

    func prepareShadingState(_ state: ShadingState) {
        state.initState()
        
        state.getRay()!.getPoint(state.getPoint())
        
        let parent: Instance? = state.getInstance()
        
        //  compute local normal
        let p: Point3 = state.transformWorldToObject(state.getPoint())
        
        var gx1w: Float = p.x - Self.DELTA
        var gx1x: Float = p.y
        var gx1y: Float = p.z
        var gx1z: Float = 0
        
        var gx2w: Float = p.x + Self.DELTA
        var gx2x: Float = p.y
        var gx2y: Float = p.z
        var gx2z: Float = 0
        
        var gy1w: Float = p.x
        var gy1x: Float = p.y - Self.DELTA
        var gy1y: Float = p.z
        var gy1z: Float = 0
        
        var gy2w: Float = p.x
        var gy2x: Float = p.y + Self.DELTA
        var gy2y: Float = p.z
        var gy2z: Float = 0
        
        var gz1w: Float = p.x
        var gz1x: Float = p.y
        var gz1y: Float = p.z - Self.DELTA
        var gz1z: Float = 0
        
        var gz2w: Float = p.x
        var gz2x: Float = p.y
        var gz2y: Float = p.z + Self.DELTA
        var gz2z: Float = 0
        
        for _ in 0 ..< maxIterations {
            //  z = z*z + c
            let nw0: Float = ((gx1w * gx1w) - (gx1x * gx1x) - (gx1y * gx1y) - (gx1z * gx1z)) + cw
            
            gx1x = (2 * gx1w * gx1x) + cx
            gx1y = (2 * gx1w * gx1y) + cy
            gx1z = (2 * gx1w * gx1z) + cz
            gx1w = nw0

            //  z = z*z + c
            let nw1: Float = ((gx2w * gx2w) - (gx2x * gx2x) - (gx2y * gx2y) - (gx2z * gx2z)) + cw
            
            gx2x = (2 * gx2w * gx2x) + cx
            gx2y = (2 * gx2w * gx2y) + cy
            gx2z = (2 * gx2w * gx2z) + cz
            gx2w = nw1

            //  z = z*z + c
            let nw2: Float = ((gy1w * gy1w) - (gy1x * gy1x) - (gy1y * gy1y) - (gy1z * gy1z)) + cw
            
            gy1x = (2 * gy1w * gy1x) + cx
            gy1y = (2 * gy1w * gy1y) + cy
            gy1z = (2 * gy1w * gy1z) + cz
            gy1w = nw2

            //  z = z*z + c
            let nw3: Float = ((gy2w * gy2w) - (gy2x * gy2x) - (gy2y * gy2y) - (gy2z * gy2z)) + cw
            
            gy2x = (2 * gy2w * gy2x) + cx
            gy2y = (2 * gy2w * gy2y) + cy
            gy2z = (2 * gy2w * gy2z) + cz
            gy2w = nw3

            //  z = z*z + c
            let nw4: Float = ((gz1w * gz1w) - (gz1x * gz1x) - (gz1y * gz1y) - (gz1z * gz1z)) + cw
            
            gz1x = (2 * gz1w * gz1x) + cx
            gz1y = (2 * gz1w * gz1y) + cy
            gz1z = (2 * gz1w * gz1z) + cz
            gz1w = nw4

            //  z = z*z + c
            let nw5: Float = ((gz2w * gz2w) - (gz2x * gz2x) - (gz2y * gz2y) - (gz2z * gz2z)) + cw
            
            gz2x = (2 * gz2w * gz2x) + cx
            gz2y = (2 * gz2w * gz2y) + cy
            gz2z = (2 * gz2w * gz2z) + cz
            gz2w = nw5
        }
        
        let gradX: Float = Self.length(gx2w, gx2x, gx2y, gx2z) - Self.length(gx1w, gx1x, gx1y, gx1z)
        let gradY: Float = Self.length(gy2w, gy2x, gy2y, gy2z) - Self.length(gy1w, gy1x, gy1y, gy1z)
        let gradZ: Float = Self.length(gz2w, gz2x, gz2y, gz2z) - Self.length(gz1w, gz1x, gz1y, gz1z)
        
        let n: Vector3 = Vector3(gradX, gradY, gradZ)
        
        state.getNormal()!.set(state.transformNormalObjectToWorld(n))
        
        state.getNormal()!.normalize()
        
        state.getGeoNormal()!.set(state.getNormal()!)
        
        state.setBasis(OrthoNormalBasis.makeFromW(state.getNormal()!))
        
        state.getPoint().x += state.getNormal()!.x * epsilon * 20
        
        state.getPoint().y += state.getNormal()!.y * epsilon * 20
        
        state.getPoint().z += state.getNormal()!.z * epsilon * 20
        
        state.setShader(parent!.getShader(0))
        
        state.setModifier(parent!.getModifier(0))
    }

    static func length(_ w: Float, _ x: Float, _ y: Float, _ z: Float) -> Float {
        return sqrt(w * w + x * x + y * y + z * z)
    }

    func update(_ pl: ParameterList) -> Bool {
        maxIterations = pl.getInt("iterations", maxIterations)!
        
        epsilon = pl.getFloat("epsilon", epsilon)!
        
        cw = pl.getFloat("cw", cw)!
        cx = pl.getFloat("cx", cx)!
        cy = pl.getFloat("cy", cy)!
        cz = pl.getFloat("cz", cz)!
        
        return true
    }

    func getBakingPrimitives() -> PrimitiveList? {
        return nil
    }
}
