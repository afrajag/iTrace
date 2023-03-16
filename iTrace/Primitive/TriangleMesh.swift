//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

import Foundation

class TriangleMesh: PrimitiveList {
    static var smallTriangles: Bool = false

    var points: [Float]?
    var triangles: [Int32]?
    var triaccel: [WaldTriangle]?
    var normals: ParameterList.FloatParameter?
    var uvs: ParameterList.FloatParameter?
    var faceShaders: [Int32]?
    var faceModifiers: [Int32]?
    var objShaders: [String]?
    var objModifiers: [String]?
    var backfaceCull: Bool? = false
    var faceShadersEnabled = false
    
    let lockQueue = DispatchQueue(label: "trianglemesh.lock.serial.queue")
    
    static func setSmallTriangles(_ smallTriangles: Bool) {
        if smallTriangles {
            UI.printInfo(.GEOM, "Small trimesh mode: enabled")
        } else {
            UI.printInfo(.GEOM, "Small trimesh mode: disabled")
        }

        Self.smallTriangles = smallTriangles
    }

    required init() {
        triangles = nil
        points = nil
        normals = ParameterList.FloatParameter()
        uvs = ParameterList.FloatParameter()
        faceShaders = nil
        faceModifiers = nil
    }

    func initTriangleMesh() {
        triaccel = nil

        let nt: Int32 = getNumPrimitives()

        if !Self.smallTriangles {
            //  too many triangles -- don't generate triaccel to save memory
            if nt > 2_000_000 {
                UI.printWarning(.GEOM, "TRI - Too many triangles -- triaccel generation skipped")
                return
            }

            triaccel = [WaldTriangle]()

            for i in 0 ..< nt {
                triaccel!.append(WaldTriangle(self, i))
            }
        }
    }

    func writeObj(_ filename: String) throws {
        // FIXME: controllare eccezioni
        try "o object".write(toFile: filename, atomically: true, encoding: .ascii)

        var i: Int32 = 0

        while i < points!.count {
            try "v \(points![Int(i)]) \(points![Int(i) + 1]) \(points![Int(i) + 2])".write(toFile: filename, atomically: true, encoding: .ascii)
        }

        try "s off".write(toFile: filename, atomically: true, encoding: .ascii)

        i = 0

        while i < triangles!.count {
            try "f \(triangles![Int(i)] + 1) \(triangles![Int(i) + 1] + 1) \(triangles![Int(i) + 2] + 1)".write(toFile: filename, atomically: true, encoding: .ascii)
        }
    }

    func update(_ pl: ParameterList) -> Bool {
        backfaceCull = pl.getBool("backfaceCull", false)

        var updatedTopology: Bool = false

        let triangles: [Int32]? = pl.getIntArray("triangles")

        if triangles != nil {
            self.triangles = triangles

            updatedTopology = true
        } else {
            UI.printError(.GEOM, "Unable to update mesh - triangle indices are missing")

            return false
        }

        if (triangles!.count % 3) != 0 {
            UI.printWarning(.GEOM, "Triangle index data is not a multiple of 3 - triangles may be missing")
        }

        pl.setFaceCount(Int32(triangles!.count / 3))

        let pointsP: ParameterList.FloatParameter? = pl.getPointArray("points")

        if pointsP != nil {
            if pointsP!.interp != .VERTEX {
                UI.printError(.GEOM, "Point interpolation type must be set to \"vertex\" - was \"\(pointsP!.interp)\"")
            } else {
                points = pointsP!.data

                updatedTopology = true
            }
        } else {
            UI.printError(.GEOM, "Unable to update mesh - vertices are missing")

            return false
        }

        pl.setVertexCount(Int32(points!.count / 3))

        pl.setFaceVertexCount(Int32(3 * (triangles!.count / 3)))

        let normals: ParameterList.FloatParameter? = pl.getVectorArray("normals")

        if normals != nil {
            self.normals = normals!
        }

        let uvs: ParameterList.FloatParameter? = pl.getTexCoordArray("uvs")

        if uvs != nil {
            self.uvs = uvs
        }

        // FIXME: changed basic implementation to support more than 255 shades for very complex scenes
        /*
        let faceShaders: [Int32]? = pl.getIntArray("faceshaders")

        if faceShaders != nil { // && faceShaders!.count == (triangles!.count / 3) {
            self.faceShaders = [UInt8](repeating: 0, count: faceShaders!.count)

            for i in 0 ..< faceShaders!.count {
                let v: Int32 = faceShaders![i]

                if v > 255 {
                    UI.printWarning(.GEOM, "Shader index too large on triangle \(i): \(v)")
                }

                self.faceShaders![i] = UInt8(v & 0xFF)
            }
        }
        */
        self.faceShaders = pl.getIntArray("faceshaders")
        
        if faceShaders != nil && faceShaders!.count != (triangles!.count / 3) {
            UI.printWarning(.GEOM, "Wrong faceshaders count: expected \(triangles!.count / 3) found \(faceShaders!.count)")
        }
        
        self.faceModifiers = pl.getIntArray("facemodifiers")
        
        self.objShaders = pl.getStringArray("objshaders", nil)
        
        self.objModifiers = pl.getStringArray("objmodifiers", nil)
        
        if updatedTopology {
            //  create triangle acceleration structure
            initTriangleMesh()
        }

        return true
    }

    func getPrimitiveBound(_ primID: Int32, _ i: Int32) -> Float {
        let tri: Int32 = 3 * primID
        let a: Int32 = 3 * triangles![Int(tri) + 0]
        let b: Int32 = 3 * triangles![Int(tri) + 1]
        let c: Int32 = 3 * triangles![Int(tri) + 2]
        let axis: Int32 = Int32(i >>> 1)

        if (i & 1) == 0 {
            return min(points![Int(a + axis)], points![Int(b + axis)], points![Int(c + axis)])
        } else {
            return max(points![Int(a + axis)], points![Int(b + axis)], points![Int(c + axis)])
        }
    }

    func getWorldBounds(_ o2w: AffineTransform?) -> BoundingBox? {
        let bounds: BoundingBox = BoundingBox()

        if o2w == nil {
            var i: Int32 = 0

            while i < points!.count {
                bounds.include(points![Int(i)], points![Int(i) + 1], points![Int(i) + 2])

                i += 3
            }
        } else {
            var i: Int32 = 0

            while i < points!.count {
                let x: Float = points![Int(i)]
                let y: Float = points![Int(i) + 1]
                let z: Float = points![Int(i) + 2]
                let wx: Float = o2w!.transformPX(x, y, z)
                let wy: Float = o2w!.transformPY(x, y, z)
                let wz: Float = o2w!.transformPZ(x, y, z)

                bounds.include(wx, wy, wz)

                i += 3
            }
        }

        return bounds
    }

    func intersectTriangleKensler(_ r: Ray, _ primID: Int32, _ state: IntersectionState) {
        let tri: Int32 = 3 * primID
        let a: Int32 = 3 * triangles![Int(tri) + 0]
        let b: Int32 = 3 * triangles![Int(tri) + 1]
        let c: Int32 = 3 * triangles![Int(tri) + 2]
        let edge0x: Float = points![Int(b) + 0] - points![Int(a) + 0]
        let edge0y: Float = points![Int(b) + 1] - points![Int(a) + 1]
        let edge0z: Float = points![Int(b) + 2] - points![Int(a) + 2]
        let edge1x: Float = points![Int(a) + 0] - points![Int(c) + 0]
        let edge1y: Float = points![Int(a) + 1] - points![Int(c) + 1]
        let edge1z: Float = points![Int(a) + 2] - points![Int(c) + 2]
        let nx: Float = edge0y * edge1z - edge0z * edge1y
        let ny: Float = edge0z * edge1x - edge0x * edge1z
        let nz: Float = edge0x * edge1y - edge0y * edge1x
        let v: Float = r.dot(nx, ny, nz)
        let iv: Float = 1 / v
        let edge2x: Float = points![Int(a) + 0] - r.ox
        let edge2y: Float = points![Int(a) + 1] - r.oy
        let edge2z: Float = points![Int(a) + 2] - r.oz
        let va: Float = nx * edge2x + ny * edge2y + nz * edge2z
        let t: Float = iv * va

        if !r.isInside(t) {
            return
        }

        let ix: Float = edge2y * r.dz - edge2z * r.dy
        let iy: Float = edge2z * r.dx - edge2x * r.dz
        let iz: Float = edge2x * r.dy - edge2y * r.dx
        let v1: Float = ix * edge1x + iy * edge1y + iz * edge1z
        let beta: Float = iv * v1

        if beta < 0 {
            return
        }

        let v2: Float = ix * edge0x + iy * edge0y + iz * edge0z

        if (v1 + v2) * v > v * v {
            return
        }

        let gamma: Float = iv * v2

        if gamma < 0 {
            return
        }

        r.setMax(t)

        state.setIntersection(primID, beta, gamma)
    }

    func intersectPrimitive(_ r: Ray, _ primID: Int32, _ state: IntersectionState) {
        // FIXME: check below
        //  alternative test -- disabled for now
        //  intersectPrimitiveRobust(r, primID, state)
        
        if backfaceCull! && normals != nil {
            let tri: Int32 = primID * 3

            let normal: Vector3 = Vector3(normals!.data![Int(tri)], normals!.data![Int(tri) + 1], normals!.data![Int(tri) + 2])

            if Vector3.dot(normal, r.getDirection()) >= 1e-5 {
                return
            }
        }
        
        if triaccel != nil {
            //  optional fast intersection method
            triaccel![Int(primID)].intersect(r, primID, state)

            return
        }
        
        intersectTriangleKensler(r, primID, state)
    }

    func getNumPrimitives() -> Int32 {
        return Int32(triangles!.count / 3)
    }

    func prepareShadingState(_ state: ShadingState) {
        state.initState()

        let parent: Instance? = state.getInstance()
        let primID: Int32 = state.getPrimitiveID()
        let u: Float = state.getU()
        let v: Float = state.getV()
        let w: Float = 1 - u - v

        state.getRay()!.getPoint(state.getPoint())

        let tri: Int32 = 3 * primID
        let index0: Int32 = triangles![Int(tri) + 0]
        let index1: Int32 = triangles![Int(tri) + 1]
        let index2: Int32 = triangles![Int(tri) + 2]
        let v0p: Point3 = getPoint(index0)
        let v1p: Point3 = getPoint(index1)
        let v2p: Point3 = getPoint(index2)
        var ng: Vector3 = Point3.normal(v0p, v1p, v2p)

        ng = state.transformNormalObjectToWorld(ng)

        ng.normalize()

        state.getGeoNormal()!.set(ng)

        switch normals!.interp {
            case .NONE,
                 .FACE:
                state.getNormal()!.set(ng)
            case .VERTEX:
                let i30: Int32 = 3 * index0
                let i31: Int32 = 3 * index1
                let i32: Int32 = 3 * index2
                let normals1: [Float] = normals!.data!

                state.getNormal()!.x = w * normals1[Int(i30) + 0] + u * normals1[Int(i31) + 0] + v * normals1[Int(i32) + 0]
                state.getNormal()!.y = w * normals1[Int(i30) + 1] + u * normals1[Int(i31) + 1] + v * normals1[Int(i32) + 1]
                state.getNormal()!.z = w * normals1[Int(i30) + 2] + u * normals1[Int(i31) + 2] + v * normals1[Int(i32) + 2]

                state.getNormal()!.set(state.transformNormalObjectToWorld(state.getNormal()!))

                state.getNormal()!.normalize()
            case .FACEVARYING:
                let idx: Int32 = 3 * tri
                let normals1: [Float] = normals!.data!

                state.getNormal()!.x = w * normals1[Int(idx) + 0] + u * normals1[Int(idx) + 3] + v * normals1[Int(idx) + 6]
                state.getNormal()!.y = w * normals1[Int(idx) + 1] + u * normals1[Int(idx) + 4] + v * normals1[Int(idx) + 7]
                state.getNormal()!.z = w * normals1[Int(idx) + 2] + u * normals1[Int(idx) + 5] + v * normals1[Int(idx) + 8]

                state.getNormal()!.set(state.transformNormalObjectToWorld(state.getNormal()!))

                state.getNormal()!.normalize()
        }

        var uv00: Float = 0
        var uv01: Float = 0
        var uv10: Float = 0
        var uv11: Float = 0
        var uv20: Float = 0
        var uv21: Float = 0

        switch uvs!.interp {
            case .NONE,
                 .FACE:
                state.getUV()!.x = 0
                state.getUV()!.y = 0
            case .VERTEX:
                let i20: Int32 = 2 * index0
                let i21: Int32 = 2 * index1
                let i22: Int32 = 2 * index2
                let uvs1: [Float] = uvs!.data!

                uv00 = uvs1[Int(i20) + 0]
                uv01 = uvs1[Int(i20) + 1]
                uv10 = uvs1[Int(i21) + 0]
                uv11 = uvs1[Int(i21) + 1]
                uv20 = uvs1[Int(i22) + 0]
                uv21 = uvs1[Int(i22) + 1]
            case .FACEVARYING:
                let idx: Int32 = tri << 1
                let uvs1: [Float] = uvs!.data!

                uv00 = uvs1[Int(idx) + 0]
                uv01 = uvs1[Int(idx) + 1]
                uv10 = uvs1[Int(idx) + 2]
                uv11 = uvs1[Int(idx) + 3]
                uv20 = uvs1[Int(idx) + 4]
                uv21 = uvs1[Int(idx) + 5]
        }

        if uvs!.interp != .NONE {
            //  get exact uv coords and compute tangent vectors
            state.getUV()!.x = (w * uv00) + (u * uv10) + (v * uv20)
            state.getUV()!.y = (w * uv01) + (u * uv11) + (v * uv21)

            let du1: Float = uv00 - uv20
            let du2: Float = uv10 - uv20
            let dv1: Float = uv01 - uv21
            let dv2: Float = uv11 - uv21
            let dp1: Vector3 = Point3.sub(v0p, v2p)
            let dp2: Vector3 = Point3.sub(v1p, v2p)
            let determinant: Float = du1 * dv2 - dv1 * du2

            if determinant == 0.0 {
                //  create basis in world space
                state.setBasis(OrthoNormalBasis.makeFromW(state.getNormal()!))
            } else {
                let invdet: Float = 1 / determinant

                //  Vector3 dpdu = new Vector3();
                //  dpdu.x = (dv2 * dp1.x - dv1 * dp2.x) * invdet;
                //  dpdu.y = (dv2 * dp1.y - dv1 * dp2.y) * invdet;
                //  dpdu.z = (dv2 * dp1.z - dv1 * dp2.z) * invdet;
                var dpdv: Vector3 = Vector3()

                dpdv.x = (-du2 * dp1.x + du1 * dp2.x) * invdet
                dpdv.y = (-du2 * dp1.y + du1 * dp2.y) * invdet
                dpdv.z = (-du2 * dp1.z + du1 * dp2.z) * invdet

                dpdv = state.transformVectorObjectToWorld(dpdv)

                //  create basis in world space
                state.setBasis(OrthoNormalBasis.makeFromWV(state.getNormal()!, dpdv))
            }
        } else {
            state.setBasis(OrthoNormalBasis.makeFromW(state.getNormal()!))
        }

        lockQueue.sync { // synchronized block
            if !faceShadersEnabled && objShaders != nil  {
                UI.printDetailed(.GEOM, "Overriding instance shaders from file (shaders count: \(objShaders!.count))")
                
                // attach face materials to instance
                let pl: ParameterList = ParameterList()
                
                pl.addStringArray("shaders", objShaders)
                
                if objModifiers != nil {
                    pl.addStringArray("modifiers", objModifiers)
                }
                
                parent!.update(pl)
                
                faceShadersEnabled = true
            }
        }
        
        // FIXME: changed basic implementation to support more than 255 shades for very complex scenes
        //let shaderIndex: Int32 = Int32(faceShaders == nil ? 0 : faceShaders![Int(primID)] & 0xFF)
        
        let shaderIndex: Int32 = faceShaders == nil ? 0 : faceShaders![Int(primID)]
        
        if (shaderIndex == -1) {
            UI.printError(.GEOM, "Shader error: found index -1")
        }
        
        state.setShader(parent!.getShader(shaderIndex))

        let modifierIndex: Int32 = faceModifiers == nil ? 0 : faceModifiers![Int(shaderIndex)]
        
        state.setModifier(parent!.getModifier(modifierIndex))
    }

    func getPoint(_ i: Int32) -> Point3 {
        let _i = i * 3

        return Point3(points![Int(_i)], points![Int(_i) + 1], points![Int(_i) + 2])
    }

    func getPoint(_ tri: Int32, _ i: Int32, _ p: Point3) {
        let index: Int32 = 3 * triangles![Int(3 * tri + i)]

        p.set(points![Int(index)], points![Int(index) + 1], points![Int(index) + 2])
    }

    func getBakingPrimitives() -> PrimitiveList? {
        switch uvs!.interp {
            case .NONE,
                 .FACE:
                UI.printError(.GEOM, "Cannot generate baking surface without texture coordinate data")

                return nil
            default:
                return BakingSurface(self)
        }
    }

    struct WaldTriangle {
        var k: Int32 = 0
        var nu: Float = 0.0
        var nv: Float = 0.0
        var nd: Float = 0.0
        var bnu: Float = 0.0
        var bnv: Float = 0.0
        var bnd: Float = 0.0
        var cnu: Float = 0.0
        var cnv: Float = 0.0
        var cnd: Float = 0.0

        init(_ mesh: TriangleMesh, _ tri: Int32) {
            k = 0

            let _tri = tri * 3

            let index0: Int32 = mesh.triangles![Int(_tri) + 0]
            let index1: Int32 = mesh.triangles![Int(_tri) + 1]
            let index2: Int32 = mesh.triangles![Int(_tri) + 2]
            let v0p: Point3 = mesh.getPoint(index0)
            let v1p: Point3 = mesh.getPoint(index1)
            let v2p: Point3 = mesh.getPoint(index2)
            let ng: Vector3 = Point3.normal(v0p, v1p, v2p)

            if abs(ng.x) > abs(ng.y), abs(ng.x) > abs(ng.z) {
                k = 0
            } else {
                if abs(ng.y) > abs(ng.z) {
                    k = 1
                } else {
                    k = 2
                }
            }

            var ax: Float
            var ay: Float
            var bx: Float
            var by: Float
            var cx: Float
            var cy: Float

            switch k {
            case 0:
                nu = ng.y / ng.x
                nv = ng.z / ng.x
                nd = v0p.x + (nu * v0p.y) + (nv * v0p.z)
                ax = v0p.y
                ay = v0p.z
                bx = v2p.y - ax
                by = v2p.z - ay
                cx = v1p.y - ax
                cy = v1p.z - ay
            case 1:
                nu = ng.z / ng.y
                nv = ng.x / ng.y
                nd = (nv * v0p.x) + v0p.y + (nu * v0p.z)
                ax = v0p.z
                ay = v0p.x
                bx = v2p.z - ax
                by = v2p.x - ay
                cx = v1p.z - ax
                cy = v1p.x - ay
            default:
                nu = ng.x / ng.z
                nv = ng.y / ng.z
                nd = (nu * v0p.x) + (nv * v0p.y) + v0p.z
                ax = v0p.x
                ay = v0p.y
                bx = v2p.x - ax
                by = v2p.y - ay
                cx = v1p.x - ax
                cy = v1p.y - ay
            }

            let det: Float = bx * cy - by * cx

            bnu = -by / det
            bnv = bx / det
            bnd = (by * ax - bx * ay) / det

            cnu = cy / det
            cnv = -cx / det
            cnd = (cx * ay - cy * ax) / det
        }

        func intersect(_ r: Ray, _ primID: Int32, _ state: IntersectionState) {
            switch k {
            case 0:
                let det: Float = 1.0 / (r.dx + nu * r.dy + nv * r.dz)
                let t: Float = (nd - r.ox - nu * r.oy - nv * r.oz) * det

                if !r.isInside(t) {
                    return
                }

                let hu: Float = r.oy + (t * r.dy)
                let hv: Float = r.oz + (t * r.dz)
                let u: Float = hu * bnu + hv * bnv + bnd

                if u < 0.0 {
                    return
                }

                let v: Float = hu * cnu + hv * cnv + cnd

                if v < 0.0 {
                    return
                }

                if (u + v) > 1.0 {
                    return
                }

                r.setMax(t)

                state.setIntersection(primID, u, v)

                return
            case 1:
                let det: Float = 1.0 / (r.dy + nu * r.dz + nv * r.dx)
                let t: Float = (nd - r.oy - nu * r.oz - nv * r.ox) * det

                if !r.isInside(t) {
                    return
                }

                let hu: Float = r.oz + t * r.dz
                let hv: Float = r.ox + t * r.dx
                let u: Float = hu * bnu + hv * bnv + bnd

                if u < 0.0 {
                    return
                }

                let v: Float = hu * cnu + hv * cnv + cnd

                if v < 0.0 {
                    return
                }

                if (u + v) > 1.0 {
                    return
                }

                r.setMax(t)

                state.setIntersection(primID, u, v)

                return
            case 2:
                let det: Float = 1.0 / (r.dz + nu * r.dx + nv * r.dy)
                let t: Float = (nd - r.oz - nu * r.ox - nv * r.oy) * det

                if !r.isInside(t) {
                    return
                }

                let hu: Float = r.ox + t * r.dx
                let hv: Float = r.oy + t * r.dy
                let u: Float = hu * bnu + hv * bnv + bnd

                if u < 0.0 {
                    return
                }

                let v: Float = hu * cnu + hv * cnv + cnd

                if v < 0.0 {
                    return
                }

                if (u + v) > 1.0 {
                    return
                }

                r.setMax(t)

                state.setIntersection(primID, u, v)

                return
            default:
                UI.printError(.GEOM, "What I'm doing here ?")
            }
        }
    }

    final class BakingSurface: PrimitiveList {
        var triangleMesh: TriangleMesh?

        required init() {}

        init(_ mesh: TriangleMesh) {
            triangleMesh = mesh
        }

        func getBakingPrimitives() -> PrimitiveList? {
            return nil
        }

        func getNumPrimitives() -> Int32 {
            return triangleMesh!.getNumPrimitives()
        }

        func getPrimitiveBound(_ primID: Int32, _ i: Int32) -> Float {
            if i > 3 {
                return 0
            }

            switch triangleMesh!.uvs!.interp {
                case .VERTEX:
                    let tri: Int32 = 3 * primID
                    let index0: Int32 = triangleMesh!.triangles![Int(tri) + 0]
                    let index1: Int32 = triangleMesh!.triangles![Int(tri) + 1]
                    let index2: Int32 = triangleMesh!.triangles![Int(tri) + 2]
                    let i20: Int32 = 2 * index0
                    let i21: Int32 = 2 * index1
                    let i22: Int32 = 2 * index2
                    let uvs: [Float] = triangleMesh!.uvs!.data!

                    switch i {
                    case 0:
                        return min(uvs[Int(i20) + 0], uvs[Int(i21) + 0], uvs[Int(i22) + 0])
                    case 1:
                        return max(uvs[Int(i20) + 0], uvs[Int(i21) + 0], uvs[Int(i22) + 0])
                    case 2:
                        return min(uvs[Int(i20) + 1], uvs[Int(i21) + 1], uvs[Int(i22) + 1])
                    case 3:
                        return max(uvs[Int(i20) + 1], uvs[Int(i21) + 1], uvs[Int(i22) + 1])
                    default:
                        return 0
                    }
                case .FACEVARYING:
                    let idx: Int32 = 6 * primID
                    let uvs: [Float] = triangleMesh!.uvs!.data!

                    switch i {
                    case 0:
                        return min(uvs[Int(idx) + 0], uvs[Int(idx) + 2], uvs[Int(idx) + 4])
                    case 1:
                        return max(uvs[Int(idx) + 0], uvs[Int(idx) + 2], uvs[Int(idx) + 4])
                    case 2:
                        return min(uvs[Int(idx) + 1], uvs[Int(idx) + 3], uvs[Int(idx) + 5])
                    case 3:
                        return max(uvs[Int(idx) + 1], uvs[Int(idx) + 3], uvs[Int(idx) + 5])
                    default:
                        return 0
                    }
                default:
                    return 0
            }
        }

        func getWorldBounds(_ o2w: AffineTransform?) -> BoundingBox? {
            let bounds: BoundingBox = BoundingBox()

            if o2w == nil {
                var i: Int32 = 0

                while i < triangleMesh!.uvs!.data!.count {
                    bounds.include(triangleMesh!.uvs!.data![Int(i)], triangleMesh!.uvs!.data![Int(i) + 1], 0)

                    i += 2
                }
            } else {
                var i: Int32 = 0

                while i < triangleMesh!.uvs!.data!.count {
                    let x: Float = triangleMesh!.uvs!.data![Int(i)]
                    let y: Float = triangleMesh!.uvs!.data![Int(i) + 1]
                    let wx: Float = o2w!.transformPX(x, y, 0)
                    let wy: Float = o2w!.transformPY(x, y, 0)
                    let wz: Float = o2w!.transformPZ(x, y, 0)

                    bounds.include(wx, wy, wz)

                    i = i + 2
                }
            }

            return bounds
        }

        func intersectPrimitive(_ r: Ray, _ primID: Int32, _ state: IntersectionState) {
            var uv00: Float = 0
            var uv01: Float = 0
            var uv10: Float = 0
            var uv11: Float = 0
            var uv20: Float = 0
            var uv21: Float = 0

            switch triangleMesh!.uvs!.interp {
                case ParameterList.InterpolationType.VERTEX:
                    let tri: Int32 = 3 * primID
                    let index0: Int32 = triangleMesh!.triangles![Int(tri) + 0]
                    let index1: Int32 = triangleMesh!.triangles![Int(tri) + 1]
                    let index2: Int32 = triangleMesh!.triangles![Int(tri) + 2]
                    let i20: Int32 = 2 * index0
                    let i21: Int32 = 2 * index1
                    let i22: Int32 = 2 * index2
                    let uvs: [Float] = triangleMesh!.uvs!.data!

                    uv00 = uvs[Int(i20) + 0]
                    uv01 = uvs[Int(i20) + 1]
                    uv10 = uvs[Int(i21) + 0]
                    uv11 = uvs[Int(i21) + 1]
                    uv20 = uvs[Int(i22) + 0]
                    uv21 = uvs[Int(i22) + 1]

                case ParameterList.InterpolationType.FACEVARYING:
                    let idx: Int32 = (3 * primID) << 1
                    let uvs: [Float] = triangleMesh!.uvs!.data!

                    uv00 = uvs[Int(idx) + 0]
                    uv01 = uvs[Int(idx) + 1]
                    uv10 = uvs[Int(idx) + 2]
                    uv11 = uvs[Int(idx) + 3]
                    uv20 = uvs[Int(idx) + 4]
                    uv21 = uvs[Int(idx) + 5]

                default:
                    return
            }

            let edge1x: Double = Double(uv10 - uv00)
            let edge1y: Double = Double(uv11 - uv01)
            let edge2x: Double = Double(uv20 - uv00)
            let edge2y: Double = Double(uv21 - uv01)
            let pvecx: Double = Double((r.dy * 0) - (r.dz * Float(edge2y)))
            let pvecy: Double = Double((r.dz * Float(edge2x)) - (r.dx * 0))
            let pvecz: Double = (Double(r.dx) * edge2y) - (Double(r.dy) * edge2x)
            var qvecx: Double
            var qvecy: Double
            var qvecz: Double
            var u: Double
            var v: Double
            let det: Double = (edge1x * pvecx) + (edge1y * pvecy) + (0 * pvecz)

            if det > 0 {
                let tvecx: Double = Double(r.ox - uv00)
                let tvecy: Double = Double(r.oy - uv01)
                let tvecz: Double = Double(r.oz)

                u = (tvecx * pvecx) + (tvecy * pvecy) + (tvecz * pvecz)

                if (u < 0.0) || (u > det) {
                    return
                }

                qvecx = (tvecy * 0) - (tvecz * edge1y)
                qvecy = (tvecz * edge1x) - (tvecx * 0)
                qvecz = (tvecx * edge1y) - (tvecy * edge1x)

                let _v1 = Double(r.dx) * qvecx
                let _v2 = Double(r.dy) * qvecy
                let _v3 = Double(r.dz) * qvecz

                v = _v1 + _v2 + _v3

                if v < 0.0 || u + v > det {
                    return
                }
            } else if det < 0 {
                let tvecx: Double = Double(r.ox - uv00)
                let tvecy: Double = Double(r.oy - uv01)
                let tvecz: Double = Double(r.oz)

                u = (tvecx * pvecx + tvecy * pvecy + tvecz * pvecz)

                if u > 0.0 || u < det {
                    return
                }

                qvecx = (tvecy * 0) - (tvecz * edge1y)
                qvecy = (tvecz * edge1x) - (tvecx * 0)
                qvecz = (tvecx * edge1y) - (tvecy * edge1x)

                let _v1 = Double(r.dx) * qvecx
                let _v2 = Double(r.dy) * qvecy
                let _v3 = Double(r.dz) * qvecz

                v = _v1 + _v2 + _v3

                if v > 0.0 || u + v < det {
                    return
                }
            } else {
                return
            }

            let inv_det: Double = 1.0 / det
            let t: Float = Float(((edge2x * qvecx) + (edge2y * qvecy) + (0 * qvecz)) * inv_det)

            if r.isInside(t) {
                r.setMax(t)

                state.setIntersection(primID, Float(u * inv_det), Float(v * inv_det))
            }
        }

        func prepareShadingState(_ state: ShadingState) {
            state.initState()

            let parent: Instance? = state.getInstance()
            let primID: Int32 = state.getPrimitiveID()

            let u: Float = state.getU()
            let v: Float = state.getV()
            let w: Float = 1 - u - v

            //  state.getRay().getPoint(state.getPoint());
            let tri: Int32 = 3 * primID
            let index0: Int32 = triangleMesh!.triangles![Int(tri) + 0]
            let index1: Int32 = triangleMesh!.triangles![Int(tri) + 1]
            let index2: Int32 = triangleMesh!.triangles![Int(tri) + 2]

            let v0p: Point3 = triangleMesh!.getPoint(index0)
            let v1p: Point3 = triangleMesh!.getPoint(index1)
            let v2p: Point3 = triangleMesh!.getPoint(index2)

            //  get object space point from barycentric coordinates
            state.getPoint().x = (w * v0p.x) + (u * v1p.x) + (v * v2p.x)
            state.getPoint().y = (w * v0p.y) + (u * v1p.y) + (v * v2p.y)
            state.getPoint().z = (w * v0p.z) + (u * v1p.z) + (v * v2p.z)

            //  move into world space
            state.getPoint().set(state.transformObjectToWorld(state.getPoint()))

            var ng: Vector3 = Point3.normal(v0p, v1p, v2p)

            if parent != nil {
                ng = state.transformNormalObjectToWorld(ng)
            }

            ng.normalize()

            state.getGeoNormal()!.set(ng)

            switch triangleMesh!.normals!.interp {
                case .NONE,
                     .FACE:
                    state.getNormal()!.set(ng)
                case .VERTEX:
                    let i30: Int32 = 3 * index0
                    let i31: Int32 = 3 * index1
                    let i32: Int32 = 3 * index2
                    let normals: [Float] = triangleMesh!.normals!.data!

                    let _x = v * normals[Int(i32) + 0]
                    let _y = v * normals[Int(i32) + 1]
                    let _z = v * normals[Int(i32) + 2]

                    state.getNormal()!.x = w * normals[Int(i30) + 0] + u * normals[Int(i31) + 0] + _x
                    state.getNormal()!.y = w * normals[Int(i30) + 1] + u * normals[Int(i31) + 1] + _y
                    state.getNormal()!.z = w * normals[Int(i30) + 2] + u * normals[Int(i31) + 2] + _z

                    if parent != nil {
                        state.getNormal()!.set(state.transformNormalObjectToWorld(state.getNormal()!))
                    }

                    state.getNormal()!.normalize()
                case .FACEVARYING:
                    let idx: Int32 = 3 * tri
                    let normals: [Float] = triangleMesh!.normals!.data!

                    let _x = v * normals[Int(idx) + 6]
                    let _y = v * normals[Int(idx) + 7]
                    let _z = v * normals[Int(idx) + 8]

                    state.getNormal()!.x = w * normals[Int(idx) + 0] + u * normals[Int(idx) + 3] + _x
                    state.getNormal()!.y = w * normals[Int(idx) + 1] + u * normals[Int(idx) + 4] + _y
                    state.getNormal()!.z = w * normals[Int(idx) + 2] + u * normals[Int(idx) + 5] + _z

                    if parent != nil {
                        state.getNormal()!.set(state.transformNormalObjectToWorld(state.getNormal()!))
                    }

                    state.getNormal()!.normalize()
            }

            var uv00: Float = 0
            var uv01: Float = 0
            var uv10: Float = 0
            var uv11: Float = 0
            var uv20: Float = 0
            var uv21: Float = 0

            switch triangleMesh!.uvs!.interp {
                case .NONE,
                     .FACE:
                    state.getUV()!.x = 0
                    state.getUV()!.y = 0
                case .VERTEX:
                    let i20: Int32 = 2 * index0
                    let i21: Int32 = 2 * index1
                    let i22: Int32 = 2 * index2
                    let uvs: [Float] = triangleMesh!.uvs!.data!

                    uv00 = uvs[Int(i20) + 0]
                    uv01 = uvs[Int(i20) + 1]
                    uv10 = uvs[Int(i21) + 0]
                    uv11 = uvs[Int(i21) + 1]
                    uv20 = uvs[Int(i22) + 0]
                    uv21 = uvs[Int(i22) + 1]
                case .FACEVARYING:
                    let idx: Int32 = tri << 1
                    let uvs: [Float] = triangleMesh!.uvs!.data!

                    uv00 = uvs[Int(idx) + 0]
                    uv01 = uvs[Int(idx) + 1]
                    uv10 = uvs[Int(idx) + 2]
                    uv11 = uvs[Int(idx) + 3]
                    uv20 = uvs[Int(idx) + 4]
                    uv21 = uvs[Int(idx) + 5]
            }

            if triangleMesh!.uvs!.interp != .NONE {
                //  get exact uv coords and compute tangent vectors
                state.getUV()!.x = (w * uv00) + (u * uv10) + (v * uv20)
                state.getUV()!.y = (w * uv01) + (u * uv11) + (v * uv21)

                let du1: Float = uv00 - uv20
                let du2: Float = uv10 - uv20
                let dv1: Float = uv01 - uv21
                let dv2: Float = uv11 - uv21
                let dp1: Vector3 = Point3.sub(v0p, v2p)
                let dp2: Vector3 = Point3.sub(v1p, v2p)
                let determinant: Float = (du1 * dv2) - (dv1 * du2)

                if determinant == 0.0 {
                    //  create basis in world space
                    state.setBasis(OrthoNormalBasis.makeFromW(state.getNormal()!))
                } else {
                    let invdet: Float = 1 / determinant

                    //  Vector3 dpdu = new Vector3();
                    //  dpdu.x = (dv2 * dp1.x - dv1 * dp2.x) * invdet;
                    //  dpdu.y = (dv2 * dp1.y - dv1 * dp2.y) * invdet;
                    //  dpdu.z = (dv2 * dp1.z - dv1 * dp2.z) * invdet;
                    var dpdv: Vector3 = Vector3()

                    dpdv.x = ((-du2 * dp1.x) + (du1 * dp2.x)) * invdet
                    dpdv.y = ((-du2 * dp1.y) + (du1 * dp2.y)) * invdet
                    dpdv.z = ((-du2 * dp1.z) + (du1 * dp2.z)) * invdet

                    if parent != nil {
                        dpdv = state.transformVectorObjectToWorld(dpdv)
                    }

                    //  create basis in world space
                    state.setBasis(OrthoNormalBasis.makeFromWV(state.getNormal()!, dpdv))
                }
            } else {
                state.setBasis(OrthoNormalBasis.makeFromW(state.getNormal()!))
            }

            // FIXME: implement same faceshader strategy
            
            let shaderIndex: Int32 = Int32(triangleMesh!.faceShaders == nil ? 0 : triangleMesh!.faceShaders![Int(primID)] & 0xFF)

            state.setShader(parent!.getShader(shaderIndex))
        }

        func update(_: ParameterList) -> Bool {
            return true
        }
    }
}
