//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class Plane: PrimitiveList {
    var center: Point3?
    var normal: Vector3?
    var k: Int32 = 0
    var bnu: Float = 0.0
    var bnv: Float = 0.0
    var bnd: Float = 0.0
    var cnu: Float = 0.0
    var cnv: Float = 0.0
    var cnd: Float = 0.0

    required init() {
        center = Point3(0, 0, 0)
        normal = Vector3(0, 1, 0)

        k = 3

        bnu = 0
        bnv = 0
        bnd = 0

        cnu = 0
        cnv = 0
        cnd = 0
    }

    func update(_ pl: ParameterList) -> Bool {
        center = pl.getPoint("center", center)

        let b: Point3? = pl.getPoint("point1", nil)
        let c: Point3? = pl.getPoint("point2", nil)

        if b != nil, c != nil {
            let v0: Point3 = center!
            let v1: Point3 = b!
            let v2: Point3 = c!
            let ng: Vector3 = Vector3.cross(Point3.sub(v1, v0), Point3.sub(v2, v0)).normalize()

            normal = Vector3.cross(Point3.sub(v1, v0), Point3.sub(v2, v0)).normalize()

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
                ax = v0.y
                ay = v0.z
                bx = v2.y - ax
                by = v2.z - ay
                cx = v1.y - ax
                cy = v1.z - ay
            case 1:
                ax = v0.z
                ay = v0.x
                bx = v2.z - ax
                by = v2.x - ay
                cx = v1.z - ax
                cy = v1.x - ay
            default:
                ax = v0.x
                ay = v0.y
                bx = v2.x - ax
                by = v2.y - ay
                cx = v1.x - ax
                cy = v1.y - ay
            }

            let det: Float = (bx * cy) - (by * cx)

            bnu = -by / det
            bnv = bx / det
            bnd = ((by * ax) - (bx * ay)) / det

            cnu = cy / det
            cnv = -cx / det
            cnd = ((cx * ay) - (cy * ax)) / det
        } else {
            normal = pl.getVector("normal", normal)

            k = 3

            bnu = 0
            bnv = 0
            bnd = 0

            cnu = 0
            cnv = 0
            cnd = 0
        }

        return true
    }

    func prepareShadingState(_ state: ShadingState) {
        state.initState()

        state.getRay()!.getPoint(state.getPoint())

        let parent: Instance = state.getInstance()!
        let worldNormal: Vector3 = state.transformNormalObjectToWorld(normal!)

        state.getNormal()!.set(worldNormal)

        state.getGeoNormal()!.set(worldNormal)

        state.setShader(parent.getShader(0))

        state.setModifier(parent.getModifier(0))

        let p: Point3 = state.transformWorldToObject(state.getPoint())
        var hu: Float
        var hv: Float

        switch k {
        case 0:
            hu = p.y
            hv = p.z
        case 1:
            hu = p.z
            hv = p.x
        case 2:
            hu = p.x
            hv = p.y
        default:
            hu = 0
            hv = 0
        }

        state.getUV()!.x = (hu * bnu) + (hv * bnv) + bnd
        state.getUV()!.y = (hu * cnu) + (hv * cnv) + cnd

        state.setBasis(OrthoNormalBasis.makeFromW(normal!))
    }

    func intersectPrimitive(_ r: Ray, _: Int32, _ state: IntersectionState) {
        let _dz = normal!.z * r.dz

        let dn: Float = normal!.x * r.dx + normal!.y * r.dy + _dz

        if dn == 0.0 {
            return
        }

        let _cx = (center!.x - r.ox) * normal!.x
        let _cy = (center!.y - r.oy) * normal!.y
        let _cz = (center!.z - r.oz) * normal!.z

        let t: Float = (_cx + _cy + _cz) / dn

        if r.isInside(t) {
            r.setMax(t)

            state.setIntersection(0)
        }
    }

    func getNumPrimitives() -> Int32 {
        return 1
    }

    func getPrimitiveBound(_: Int32, _: Int32) -> Float {
        return 0
    }

    func getWorldBounds(_: AffineTransform?) -> BoundingBox? {
        return nil
    }

    func getBakingPrimitives() -> PrimitiveList? {
        return nil
    }
}
