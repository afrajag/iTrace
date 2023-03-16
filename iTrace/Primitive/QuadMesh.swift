//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//
import Foundation

final class QuadMesh: PrimitiveList {
    var points: [Float]?
    var quads: [Int32]?
    var normals: ParameterList.FloatParameter?
    var uvs: ParameterList.FloatParameter?
    var faceShaders: [UInt8]?

    required init() {
        quads = nil
        points = nil
        normals = ParameterList.FloatParameter()
        uvs = ParameterList.FloatParameter()
        faceShaders = nil
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

        while i < quads!.count {
            try "f \(quads![Int(i)] + 1) \(quads![Int(i) + 1] + 1) \(quads![Int(i) + 2] + 1) \(quads![Int(i) + 3] + 1))".write(toFile: filename, atomically: true, encoding: .ascii)
        }
    }

    func update(_ pl: ParameterList) -> Bool {
        let quads1: [Int32] = pl.getIntArray("quads")!

        if quads != nil {
            quads = quads1
        }

        if quads == nil {
            UI.printError(.GEOM, "Unable to update mesh - quad indices are missing")
            return false
        }

        if (quads!.count % 4) != 0 {
            UI.printWarning(.GEOM, "Quad index data is not a multiple of 4 - some quads may be missing")
        }

        pl.setFaceCount(Int32(quads!.count / 4))

        let pointsP: ParameterList.FloatParameter? = pl.getPointArray("points")

        if pointsP != nil {
            if pointsP!.interp != ParameterList.InterpolationType.VERTEX {
                UI.printError(.GEOM, "Point interpolation type must be set to \"vertex\" - was \"\(pointsP!.interp)\"")
            } else {
                points = pointsP!.data
            }
        }

        if points == nil {
            UI.printError(.GEOM, "Unabled to update mesh - vertices are missing")

            return false
        }

        pl.setVertexCount(Int32(points!.count / 3))

        pl.setFaceVertexCount(Int32(4 * (quads!.count / 4)))

        let normals: ParameterList.FloatParameter? = pl.getVectorArray("normals")

        if normals != nil {
            self.normals = normals
        }

        let uvs: ParameterList.FloatParameter? = pl.getTexCoordArray("uvs")

        if uvs != nil {
            self.uvs = uvs
        }

        let faceShaders: [Int32]? = pl.getIntArray("faceshaders")

        if faceShaders != nil, faceShaders!.count == (quads!.count / 4) {
            self.faceShaders = [UInt8](repeating: 0, count: faceShaders!.count)

            for i in 0 ..< faceShaders!.count {
                let v: Int32 = faceShaders![i]

                if v > 255 {
                    UI.printWarning(.GEOM, "Shader index too large on quad \(i)")
                }

                self.faceShaders![i] = UInt8(v & 0xFF)
            }
        }

        return true
    }

    func getPrimitiveBound(_ primID: Int32, _ i: Int32) -> Float {
        let quad: Int32 = 4 * primID
        let a: Int32 = 3 * quads![Int(quad) + 0]
        let b: Int32 = 3 * quads![Int(quad) + 1]
        let c: Int32 = 3 * quads![Int(quad) + 2]
        let d: Int32 = 3 * quads![Int(quad) + 3]
        let axis: Int32 = i >>> 1

        if (i & 1) == 0 {
            return min(points![Int(a + axis)], points![Int(b + axis)], points![Int(c + axis)], points![Int(d + axis)])
        } else {
            return max(points![Int(a + axis)], points![Int(b + axis)], points![Int(c + axis)], points![Int(d + axis)])
        }
    }

    func getWorldBounds(_ o2w: AffineTransform?) -> BoundingBox? {
        let bounds: BoundingBox = BoundingBox()

        if o2w == nil {
            let i: Int32 = 0

            while i < points!.count {
                bounds.include(points![Int(i)], points![Int(i) + 1], points![Int(i) + 2])
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

    func intersectPrimitive(_ r: Ray, _ primID: Int32, _ state: IntersectionState) {
        //  ray/bilinear patch intersection adapted from "Production Rendering:
        //  Design and Implementation" by Ian Stephenson (Ed.)
        let quad: Int32 = 4 * primID
        let p0: Int32 = 3 * quads![Int(quad) + 0]
        let p1: Int32 = 3 * quads![Int(quad) + 1]
        let p2: Int32 = 3 * quads![Int(quad) + 2]
        let p3: Int32 = 3 * quads![Int(quad) + 3]

        //  transform patch into Hilbert space
        let A: [Float] = [(points![Int(p2) + 0] - points![Int(p3) + 0] - points![Int(p1) + 0]) + points![Int(p0) + 0], (points![Int(p2) + 1] - points![Int(p3) + 1] - points![Int(p1) + 1]) + points![Int(p0) + 1], (points![Int(p2) + 2] - points![Int(p3) + 2] - points![Int(p1) + 2]) + points![Int(p0) + 2]]
        let B: [Float] = [points![Int(p1) + 0] - points![Int(p0) + 0], points![Int(p1) + 1] - points![Int(p0) + 1], points![Int(p1) + 2] - points![Int(p0) + 2]]
        let C: [Float] = [points![Int(p3) + 0] - points![Int(p0) + 0], points![Int(p3) + 1] - points![Int(p0) + 1], points![Int(p3) + 2] - points![Int(p0) + 2]]
        let R: [Float] = [r.ox - points![Int(p0) + 0], r.oy - points![Int(p0) + 1], r.oz - points![Int(p0) + 2]]
        let Q: [Float] = [r.dx, r.dy, r.dz]

        //  pick major direction
        let absqx: Float = abs(r.dx)
        let absqy: Float = abs(r.dy)
        let absqz: Float = abs(r.dz)

        var X: Int32 = 0
        var Y: Int32 = 1
        var Z: Int32 = 2

        if absqx > absqy, absqx > absqz {
            //  X = 0, Y = 1, Z = 2
        } else {
            if absqy > absqz {
                //  X = 1, Y = 0, Z = 2
                X = 1
                Y = 0
            } else {
                //  X = 2, Y = 1, Z = 0
                X = 2
                Z = 0
            }
        }

        let _v0 = (C[Int(Z)] * Q[Int(X)])
        let _v1 = (C[Int(X)] * Q[Int(Y)])
        let _v2 = (C[Int(Y)] * Q[Int(Z)])
        let _v3 = (R[Int(Z)] * Q[Int(X)])
        let _v4 = (R[Int(X)] * Q[Int(Y)])
        let _v5 = (R[Int(Y)] * Q[Int(Z)])
        let _v6 = (B[Int(Y)] * Q[Int(X)])
        let _v7 = (B[Int(Z)] * Q[Int(Y)])
        let _v8 = (B[Int(X)] * Q[Int(Z)])

        let Cxz: Float = (C[Int(X)] * Q[Int(Z)]) - _v0
        let Cyx: Float = (C[Int(Y)] * Q[Int(X)]) - _v1
        let Czy: Float = (C[Int(Z)] * Q[Int(Y)]) - _v2
        let Rxz: Float = (R[Int(X)] * Q[Int(Z)]) - _v3
        let Ryx: Float = (R[Int(Y)] * Q[Int(X)]) - _v4
        let Rzy: Float = (R[Int(Z)] * Q[Int(Y)]) - _v5
        let Bxy: Float = (B[Int(X)] * Q[Int(Y)]) - _v6
        let Byz: Float = (B[Int(Y)] * Q[Int(Z)]) - _v7
        let Bzx: Float = (B[Int(Z)] * Q[Int(X)]) - _v8

        let _a = (A[Int(Z)] * Bxy)

        let a: Float = (A[Int(X)] * Byz) + (A[Int(Y)] * Bzx) + _a

        if a == 0 {
            //  setup for linear equation
            let _b = (B[Int(Z)] * Cyx)
            let _c = (C[Int(Z)] * Ryx)

            let b: Float = (B[Int(X)] * Czy) + (B[Int(Y)] * Cxz) + _b
            let c: Float = (C[Int(X)] * Rzy) + (C[Int(Y)] * Rxz) + _c
            let u: Float = -c / b

            if u >= 0, u <= 1 {
                let v: Float = ((u * Bxy) + Ryx) / Cyx

                if v >= 0, v <= 1 {
                    let _t = ((B[Int(X)] * u) + (C[Int(X)] * v)) - R[Int(X)]

                    let t: Float = _t / Q[Int(X)]

                    if r.isInside(t) {
                        r.setMax(t)

                        state.setIntersection(primID, u, v)
                    }
                }
            }
        } else {
            //  setup for quadratic equation
            let _b = (B[Int(Y)] * Cxz) + (B[Int(Z)] * Cyx)
            let _c = (C[Int(Y)] * Rxz) + (C[Int(Z)] * Ryx)

            let b: Float = (A[Int(X)] * Rzy) + (A[Int(Y)] * Rxz) + (A[Int(Z)] * Ryx) + (B[Int(X)] * Czy) + _b
            let c: Float = (C[Int(X)] * Rzy) + _c
            let discrim: Float = (b * b) - (4 * a * c)

            //  reject trivial cases
            if (c * (a + b + c)) > 0, (discrim < 0) || ((a * c) < 0) || ((b / a) > 0) || ((b / a) < -2) {
                return
            }

            //  solve quadratic
            let q: Float = (b > 0 ? -0.5 * (b + sqrt(discrim)) : -0.5 * (b - sqrt(discrim)))

            //  check first solution
            let _Axy = A[Int(X)] * Q[Int(Y)]

            let Axy: Float = _Axy - (A[Int(Y)] * Q[Int(X)])
            var u: Float = q / a

            if u >= 0, u <= 1 {
                let d: Float = (u * Axy) - Cyx
                let v: Float = -(u * Bxy) + Ryx / d

                if v >= 0, v <= 1 {
                    let _t = (((A[Int(X)] * u * v) + (B[Int(X)] * u) + (C[Int(X)] * v)) - R[Int(X)])

                    let t: Float = _t / Q[Int(X)]

                    if r.isInside(t) {
                        r.setMax(t)

                        state.setIntersection(primID, u, v)
                    }
                }
            }

            u = c / q

            if u >= 0, u <= 1 {
                let d: Float = (u * Axy) - Cyx
                let v: Float = -(u * Bxy) + Ryx / d

                if v >= 0, v <= 1 {
                    let _t = (((A[Int(X)] * u * v) + (B[Int(X)] * u) + (C[Int(X)] * v)) - R[Int(X)])

                    let t: Float = _t / Q[Int(X)]

                    if r.isInside(t) {
                        r.setMax(t)

                        state.setIntersection(primID, u, v)
                    }
                }
            }
        }
    }

    func getNumPrimitives() -> Int32 {
        return Int32(quads!.count / 4)
    }

    func prepareShadingState(_ state: ShadingState) {
        state.initState()

        let parent: Instance? = state.getInstance()
        let primID: Int32 = state.getPrimitiveID()
        let u: Float = state.getU()
        let v: Float = state.getV()

        state.getRay()!.getPoint(state.getPoint())

        let quad: Int32 = 4 * primID
        let index0: Int32 = quads![Int(quad) + 0]
        let index1: Int32 = quads![Int(quad) + 1]
        let index2: Int32 = quads![Int(quad) + 2]
        let index3: Int32 = quads![Int(quad) + 3]
        let v0p: Point3 = getPoint(index0)
        let v1p: Point3 = getPoint(index1)
        let v2p: Point3 = getPoint(index2)
        let v3p: Point3 = getPoint(index3)
        let tanux: Float = ((1 - v) * (v1p.x - v0p.x)) + (v * (v2p.x - v3p.x))
        let tanuy: Float = ((1 - v) * (v1p.y - v0p.y)) + (v * (v2p.y - v3p.y))
        let tanuz: Float = ((1 - v) * (v1p.z - v0p.z)) + (v * (v2p.z - v3p.z))
        let tanvx: Float = ((1 - u) * (v3p.x - v0p.x)) + (u * (v2p.x - v1p.x))
        let tanvy: Float = ((1 - u) * (v3p.y - v0p.y)) + (u * (v2p.y - v1p.y))
        let tanvz: Float = ((1 - u) * (v3p.z - v0p.z)) + (u * (v2p.z - v1p.z))
        let nx: Float = (tanuy * tanvz) - (tanuz * tanvy)
        let ny: Float = (tanuz * tanvx) - (tanux * tanvz)
        let nz: Float = (tanux * tanvy) - (tanuy * tanvx)
        var ng: Vector3 = Vector3(nx, ny, nz)

        ng = state.transformNormalObjectToWorld(ng)

        ng.normalize()

        state.getGeoNormal()!.set(ng)

        let k00: Float = (1 - u) * (1 - v)
        let k10: Float = u * (1 - v)
        let k01: Float = (1 - u) * v
        let k11: Float = u * v

        switch normals!.interp {
        case ParameterList.InterpolationType.NONE:
            break
        case ParameterList.InterpolationType.FACE:
            state.getNormal()!.set(ng)
        case ParameterList.InterpolationType.VERTEX:
            let i30: Int32 = 3 * index0
            let i31: Int32 = 3 * index1
            let i32: Int32 = 3 * index2
            let i33: Int32 = 3 * index3
            let normals1: [Float] = normals!.data!

            state.getNormal()!.x = (k00 * normals1[Int(i30) + 0]) + (k10 * normals1[Int(i31) + 0]) + (k11 * normals1[Int(i32) + 0]) + (k01 * normals1[Int(i33) + 0])
            state.getNormal()!.y = (k00 * normals1[Int(i30) + 1]) + (k10 * normals1[Int(i31) + 1]) + (k11 * normals1[Int(i32) + 1]) + (k01 * normals1[Int(i33) + 1])
            state.getNormal()!.z = (k00 * normals1[Int(i30) + 2]) + (k10 * normals1[Int(i31) + 2]) + (k11 * normals1[Int(i32) + 2]) + (k01 * normals1[Int(i33) + 2])

            state.getNormal()!.set(state.transformNormalObjectToWorld(state.getNormal()!))

            state.getNormal()!.normalize()
        case ParameterList.InterpolationType.FACEVARYING:
            let idx: Int32 = 3 * quad
            let normals1: [Float] = normals!.data!

            state.getNormal()!.x = (k00 * normals1[Int(idx) + 0]) + (k10 * normals1[Int(idx) + 3]) + (k11 * normals1[Int(idx) + 6]) + (k01 * normals1[Int(idx) + 9])
            state.getNormal()!.y = (k00 * normals1[Int(idx) + 1]) + (k10 * normals1[Int(idx) + 4]) + (k11 * normals1[Int(idx) + 7]) + (k01 * normals1[Int(idx) + 10])
            state.getNormal()!.z = (k00 * normals1[Int(idx) + 2]) + (k10 * normals1[Int(idx) + 5]) + (k11 * normals1[Int(idx) + 8]) + (k01 * normals1[Int(idx) + 11])

            state.getNormal()!.set(state.transformNormalObjectToWorld(state.getNormal()!))

            state.getNormal()!.normalize()
        }

        var uv00: Float = 0
        var uv01: Float = 0
        var uv10: Float = 0
        var uv11: Float = 0
        var uv20: Float = 0
        var uv21: Float = 0
        var uv30: Float = 0
        var uv31: Float = 0

        switch uvs!.interp {
        case ParameterList.InterpolationType.NONE:
            break
        case ParameterList.InterpolationType.FACE:
            state.getUV()!.x = 0
            state.getUV()!.y = 0
        case ParameterList.InterpolationType.VERTEX:
            let i20: Int32 = 2 * index0
            let i21: Int32 = 2 * index1
            let i22: Int32 = 2 * index2
            let i23: Int32 = 2 * index3
            let uvs1: [Float] = uvs!.data!

            uv00 = uvs1[Int(i20) + 0]
            uv01 = uvs1[Int(i20) + 1]
            uv10 = uvs1[Int(i21) + 0]
            uv11 = uvs1[Int(i21) + 1]
            uv20 = uvs1[Int(i22) + 0]
            uv21 = uvs1[Int(i22) + 1]
            uv20 = uvs1[Int(i23) + 0]
            uv21 = uvs1[Int(i23) + 1]
        case ParameterList.InterpolationType.FACEVARYING:
            let idx: Int32 = quad << 1
            let uvs1: [Float] = uvs!.data!

            uv00 = uvs1[Int(idx) + 0]
            uv01 = uvs1[Int(idx) + 1]
            uv10 = uvs1[Int(idx) + 2]
            uv11 = uvs1[Int(idx) + 3]
            uv20 = uvs1[Int(idx) + 4]
            uv21 = uvs1[Int(idx) + 5]
            uv30 = uvs1[Int(idx) + 6]
            uv31 = uvs1[Int(idx) + 7]
        }

        if uvs!.interp != ParameterList.InterpolationType.NONE {
            //  get exact uv coords and compute tangent vectors
            state.getUV()!.x = (k00 * uv00) + (k10 * uv10) + (k11 * uv20) + (k01 * uv30)
            state.getUV()!.y = (k00 * uv01) + (k10 * uv11) + (k11 * uv21) + (k01 * uv31)

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

                dpdv = state.transformVectorObjectToWorld(dpdv)

                //  create basis in world space
                state.setBasis(OrthoNormalBasis.makeFromWV(state.getNormal()!, dpdv))
            }
        } else {
            state.setBasis(OrthoNormalBasis.makeFromW(state.getNormal()!))
        }

        let shaderIndex: Int32 = Int32(faceShaders == nil ? 0 : faceShaders![Int(primID)] & 255)

        state.setShader(parent!.getShader(shaderIndex))

        state.setModifier(parent!.getModifier(shaderIndex))
    }

    func getPoint(_ i: Int32) -> Point3 {
        let _i = i * 3

        return Point3(points![Int(_i)], points![Int(_i) + 1], points![Int(_i) + 2])
    }

    func getBakingPrimitives() -> PrimitiveList? {
        return nil
    }
}
