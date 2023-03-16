//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//
import Foundation

final class Sphere: PrimitiveList {
    required init() {}

    func update(_: ParameterList) -> Bool {
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

        state.getNormal()!.set(localPoint.x, localPoint.y, localPoint.z)
        state.getNormal()!.normalize()

        var phi: Float = Float(atan2(state.getNormal()!.y, state.getNormal()!.x))

        if phi < 0 {
            phi = phi + Float(2 * Double.pi)
        }

        let theta: Float = Float(acos(state.getNormal()!.z))

        state.getUV()!.y = theta / Float.pi
        state.getUV()!.x = phi / 2 * Float.pi

        var v: Vector3 = Vector3()

        v.x = -2 * Float.pi * state.getNormal()!.y
        v.y = 2 * Float.pi * state.getNormal()!.x
        v.z = 0

        state.setShader(parent.getShader(0))
        state.setModifier(parent.getModifier(0))

        //  into world space
        let worldNormal: Vector3 = state.transformNormalObjectToWorld(state.getNormal()!)

        v = state.transformVectorObjectToWorld(v)

        state.getNormal()!.set(worldNormal)
        state.getNormal()!.normalize()
        state.getGeoNormal()!.set(state.getNormal()!)

        //  compute basis in world space
        state.setBasis(OrthoNormalBasis.makeFromWV(state.getNormal()!, v))
    }

    func intersectPrimitive(_ r: Ray, _: Int32, _ state: IntersectionState) {
        //  intersect in local space
        let qa: Double = Double((r.dx * r.dx) + (r.dy * r.dy) + (r.dz * r.dz))

        let qb: Double = 2 * Double((r.dx * r.ox) + (r.dy * r.oy) + (r.dz * r.oz))

        let qc: Double = Double((r.ox * r.ox) + (r.oy * r.oy) + (r.oz * r.oz)) - 1.0

        let t: [Double]? = Solvers.solveQuadric(qa, qb, qc)

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

            state.setIntersection(0)
        }
    }

    func getBakingPrimitives() -> PrimitiveList? {
        return nil
    }
}
