//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class OrthoNormalBasis {
    var u: Vector3
    var v: Vector3
    var w: Vector3

    init() {
        u = Vector3()
        v = Vector3()
        w = Vector3()
    }

    func flipU() {
        u = u.negate()
    }

    func flipV() {
        v = v.negate()
    }

    func flipW() {
        w = w.negate()
    }

    func swapUV() {
        let t: Vector3 = u

        u = v
        v = t
    }

    func swapVW() {
        let t: Vector3 = v

        v = w
        w = t
    }

    func swapWU() {
        let t: Vector3 = w

        w = u
        u = t
    }

    @discardableResult
    func transform(_ a: Vector3, _ dest: Vector3) -> Vector3 {
        dest.x = (a.x * u.x) + (a.y * v.x) + (a.z * w.x)
        dest.y = (a.x * u.y) + (a.y * v.y) + (a.z * w.y)
        dest.z = (a.x * u.z) + (a.y * v.z) + (a.z * w.z)

        return dest
    }

    @discardableResult
    func transform(_ a: Vector3) -> Vector3 {
        let x: Float = (a.x * u.x) + (a.y * v.x) + (a.z * w.x)
        let y: Float = (a.x * u.y) + (a.y * v.y) + (a.z * w.y)
        let z: Float = (a.x * u.z) + (a.y * v.z) + (a.z * w.z)

        return a.set(x, y, z)
    }

    func untransform(_ a: Vector3, _ dest: Vector3) -> Vector3 {
        dest.x = Vector3.dot(a, u)
        dest.y = Vector3.dot(a, v)
        dest.z = Vector3.dot(a, w)

        return dest
    }

    @discardableResult
    func untransform(_ a: Vector3) -> Vector3 {
        let x: Float = Vector3.dot(a, u)
        let y: Float = Vector3.dot(a, v)
        let z: Float = Vector3.dot(a, w)

        return a.set(x, y, z)
    }

    func untransformX(_ a: Vector3) -> Float {
        return Vector3.dot(a, u)
    }

    func untransformY(_ a: Vector3) -> Float {
        return Vector3.dot(a, v)
    }

    func untransformZ(_ a: Vector3) -> Float {
        return Vector3.dot(a, w)
    }

    static func makeFromW(_ w: Vector3) -> OrthoNormalBasis {
        let onb: OrthoNormalBasis = OrthoNormalBasis()

        // FIXME: controllare se l'implementazione e' corretta
        let _w = Vector3(w)
        
        onb.w = _w.normalize()

        if abs(onb.w.x) < abs(onb.w.y), abs(onb.w.x) < abs(onb.w.z) {
            onb.v.x = 0
            onb.v.y = onb.w.z
            onb.v.z = -onb.w.y
        } else if abs(onb.w.y) < abs(onb.w.z) {
            onb.v.x = onb.w.z
            onb.v.y = 0
            onb.v.z = -onb.w.x
        } else {
            onb.v.x = onb.w.y
            onb.v.y = -onb.w.x
            onb.v.z = 0
        }

        // FIXME: controllare se l'implementazione e' corretta
        onb.u.set(Vector3.cross(onb.v.normalize(), onb.w))

        return onb
    }

    static func makeFromWV(_ w: Vector3, _ v: Vector3) -> OrthoNormalBasis {
        let onb: OrthoNormalBasis = OrthoNormalBasis()

        // FIXME: controllare se l'implementazione e' corretta
        let _w = Vector3(w)
        
        onb.w = _w.normalize()

        onb.u.set(Vector3.cross(v, onb.w)).normalize()

        onb.v.set(Vector3.cross(onb.w, onb.u))

        return onb
    }
}
