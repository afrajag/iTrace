//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

class BezierMesh: Tesselatable {
    var subdivs: Int32 = 0
    var smooth: Bool = false
    var quads: Bool = false
    var patches: [[Float]]?

    required convenience init() {
        self.init(nil)
    }

    init(_ patches: [[Float]]?) {
        subdivs = 8
        smooth = true
        quads = false

        //  convert to single precision
        self.patches = patches
    }

    func getWorldBounds(_ o2w: AffineTransform?) -> BoundingBox? {
        let bounds: BoundingBox = BoundingBox()

        if o2w == nil {
            for i in 0 ..< patches!.count {
                let patch: [Float] = patches![i]
                var j: Int32 = 0

                while j < patch.count {
                    bounds.include(patch[Int(j)], patch[Int(j) + 1], patch[Int(j) + 2])

                    j += 3
                }
            }
        } else {
            //  transform vertices first
            for i in 0 ..< patches!.count {
                let patch: [Float] = patches![i]
                var j: Int32 = 0

                while j < patch.count {
                    let x: Float = patch[Int(j)]
                    let y: Float = patch[Int(j) + 1]
                    let z: Float = patch[Int(j) + 2]
                    let wx: Float = o2w!.transformPX(x, y, z)
                    let wy: Float = o2w!.transformPY(x, y, z)
                    let wz: Float = o2w!.transformPZ(x, y, z)

                    bounds.include(wx, wy, wz)

                    j += 3
                }
            }
        }

        return bounds
    }

    func bernstein(_ u: Float) -> [Float] {
        var b: [Float] = [Float](repeating: 0, count: 4)
        let i: Float = 1 - u

        b[0] = i * i * i
        b[1] = 3 * u * i * i
        b[2] = 3 * u * u * i
        b[3] = u * u * u

        return b
    }

    func bernsteinDeriv(_ u: Float) -> [Float]? {
        if !smooth {
            return nil
        }

        var b: [Float] = [Float](repeating: 0, count: 4)
        let i: Float = 1 - u

        b[0] = 3 * (0 - (i * i))
        b[1] = 3 * ((i * i) - (2 * u * i))
        b[2] = 3 * ((2 * u * i) - (u * u))
        b[3] = 3 * ((u * u) - 0)

        return b
    }

    func getPatchPoint(_: Float, _: Float, _ ctrl: [Float], _ bu: [Float], _ bv: [Float], _ bdu: [Float]?, _ bdv: [Float]?, _ p: Point3, _ n: Vector3?) {
        var px: Float = 0
        var py: Float = 0
        var pz: Float = 0

        var index: Int32 = 0

        for i in 0 ..< 4 {
            for j in 0 ..< 4 {
                let scale: Float = bu[j] * bv[i]

                px += ctrl[Int(index) + 0] * scale
                py += ctrl[Int(index) + 1] * scale
                pz += ctrl[Int(index) + 2] * scale

                index += 3
            }
        }

        p.x = px
        p.y = py
        p.z = pz

        if n != nil {
            var dpdux: Float = 0
            var dpduy: Float = 0
            var dpduz: Float = 0
            var dpdvx: Float = 0
            var dpdvy: Float = 0
            var dpdvz: Float = 0

            var index: Int32 = 0

            for i in 0 ..< 4 {
                for j in 0 ..< 4 {
                    let scaleu: Float = bdu![j] * bv[i]

                    dpdux = dpdux + ctrl[Int(index) + 0] * scaleu
                    dpduy = dpduy + ctrl[Int(index) + 1] * scaleu
                    dpduz = dpduz + ctrl[Int(index) + 2] * scaleu

                    let scalev: Float = bu[j] * bdv![i]

                    dpdvx = dpdvx + ctrl[Int(index) + 0] * scalev
                    dpdvy = dpdvy + ctrl[Int(index) + 1] * scalev
                    dpdvz = dpdvz + ctrl[Int(index) + 2] * scalev

                    index += 3
                }
            }

            //  surface normal
            n!.x = (dpduy * dpdvz) - (dpduz * dpdvy)
            n!.y = (dpduz * dpdvx) - (dpdux * dpdvz)
            n!.z = (dpdux * dpdvy) - (dpduy * dpdvx)
        }
    }

    func tesselate() -> PrimitiveList? {
        let _count = Int32(patches!.count) * (subdivs + 1) * (subdivs + 1)

        var vertices: [Float] = [Float](repeating: 0, count: Int(_count) * 3)

        var normals: [Float]? = smooth ? [Float](repeating: 0, count: Int(_count) * 3) : nil

        var uvs: [Float] = [Float](repeating: 0, count: Int(_count) * 2)

        let _quads: Int32 = quads ? 4 : 2 * 3

        let _countQ = Int32(patches!.count) * subdivs * subdivs * _quads

        var indices: [Int32] = [Int32](repeating: 0, count: Int(_countQ))

        var vidx: Int32 = 0
        var pidx: Int32 = 0
        let step: Float = 1.0 / Float(subdivs)
        let vstride: Int32 = subdivs + 1
        let p: Point3 = Point3()
        let n: Vector3? = smooth ? Vector3() : nil

        for patch in patches! {
            var voff: Int32 = 0

            //  create patch vertices
            for i in 0 ... subdivs {
                let u: Float = Float(i) * step
                let bu: [Float] = bernstein(u)
                let bdu: [Float]? = bernsteinDeriv(u)

                for j in 0 ... subdivs {
                    let v: Float = Float(j) * step
                    let bv: [Float] = bernstein(v)
                    let bdv: [Float]? = bernsteinDeriv(v)

                    getPatchPoint(u, v, patch, bu, bv, bdu, bdv, p, n)

                    vertices[Int(vidx + voff) + 0] = p.x
                    vertices[Int(vidx + voff) + 1] = p.y
                    vertices[Int(vidx + voff) + 2] = p.z

                    if smooth {
                        normals![Int(vidx + voff) + 0] = n!.x
                        normals![Int(vidx + voff) + 1] = n!.y
                        normals![Int(vidx + voff) + 2] = n!.z
                    }

                    uvs[Int(vidx + voff) / 3 * 2 + 0] = u
                    uvs[Int(vidx + voff) / 3 * 2 + 1] = v

                    voff += 3
                }
            }

            let vbase: Int32 = vidx / 3

            //  generate patch triangles
            for i in 0 ..< subdivs {
                for j in 0 ..< subdivs {
                    let v00: Int32 = (i + 0) * vstride + (j + 0)
                    let v10: Int32 = (i + 1) * vstride + (j + 0)
                    let v01: Int32 = (i + 0) * vstride + (j + 1)
                    let v11: Int32 = (i + 1) * vstride + (j + 1)

                    if quads {
                        indices[Int(pidx) + 0] = vbase + v01
                        indices[Int(pidx) + 1] = vbase + v00
                        indices[Int(pidx) + 2] = vbase + v10
                        indices[Int(pidx) + 3] = vbase + v11

                        pidx += 4
                    } else {
                        //  add 2 triangles
                        indices[Int(pidx) + 0] = vbase + v00
                        indices[Int(pidx) + 1] = vbase + v10
                        indices[Int(pidx) + 2] = vbase + v01
                        indices[Int(pidx) + 3] = vbase + v10
                        indices[Int(pidx) + 4] = vbase + v11
                        indices[Int(pidx) + 5] = vbase + v01

                        pidx += 6
                    }
                }
            }

            vidx += vstride * vstride * 3
        }

        let pl: ParameterList = ParameterList()

        pl.addPoints("points", ParameterList.InterpolationType.VERTEX, vertices)

        if quads {
            pl.addIntegerArray("quads", indices)
        } else {
            pl.addIntegerArray("triangles", indices)
        }

        pl.addTexCoords("uvs", ParameterList.InterpolationType.VERTEX, uvs)

        if smooth {
            pl.addVectors("normals", ParameterList.InterpolationType.VERTEX, normals!)
        }

        let m: PrimitiveList = quads ? (QuadMesh() as PrimitiveList) : (TriangleMesh() as PrimitiveList)

        m.update(pl)

        pl.clear(true)

        return m
    }

    func update(_ pl: ParameterList) -> Bool {
        subdivs = pl.getInt("subdivs", subdivs)!

        smooth = pl.getBool("smooth", smooth)!

        quads = pl.getBool("quads", quads)!

        let nu: Int32 = pl.getInt("nu", 0)!
        let nv: Int32 = pl.getInt("nv", 0)!

        pl.setVertexCount(nu * nv)

        let uwrap: Bool = pl.getBool("uwrap", false)!
        let vwrap: Bool = pl.getBool("vwrap", false)!
        let points: ParameterList.FloatParameter? = pl.getPointArray("points")

        if points != nil, points!.interp == ParameterList.InterpolationType.VERTEX {
            let numUPatches: Int32 = (uwrap ? nu / 3 : ((nu - 4) / 3) + 1)
            let numVPatches: Int32 = (vwrap ? nv / 3 : ((nv - 4) / 3) + 1)

            if (numUPatches < 1) || (numVPatches < 1) {
                UI.printError(.GEOM, "Invalid number of patches for bezier mesh - ignoring")

                return false
            }

            //  generate patches
            patches = [[Float]](repeating: [], count: Int(numUPatches * numVPatches))

            let p: Int32 = 0

            for v in 0 ..< numVPatches {
                for u in 0 ..< numUPatches {
                    var patch: [Float] = [Float](repeating: 0, count: 16 * 3)

                    patches![Int(p)] = [Float](repeating: 0, count: 16 * 3)

                    let up: Int32 = u * 3
                    let vp: Int32 = v * 3

                    for pv in 0 ..< 4 {
                        for pu in 0 ..< 4 {
                            let meshU: Int32 = (up + Int32(pu)) % nu
                            let meshV: Int32 = (vp + Int32(pv)) % nv

                            //  copy point
                            let _idx = 3 * (meshU + nu * meshV)

                            patch[3 * (pv * 4 + pu) + 0] = points!.data![Int(_idx) + 0]
                            patch[3 * (pv * 4 + pu) + 1] = points!.data![Int(_idx) + 1]
                            patch[3 * (pv * 4 + pu) + 2] = points!.data![Int(_idx) + 2]
                        }
                    }
                }
            }
        }

        if subdivs < 1 {
            UI.printError(.GEOM, "Invalid subdivisions for bezier mesh - ignoring")

            return false
        }

        if patches == nil {
            UI.printError(.GEOM, "No patch data present in bezier mesh - ignoring")

            return false
        }

        return true
    }
}
