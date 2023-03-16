//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

import Foundation

#if !DEBUG

import simd

final class Ray {
    static var EPSILON: Float = Float.ulpOfOne // 0.01f

    var origin: simd_float3
    var direction: simd_float3

    var tMin: Float = 0.0
    var tMax: Float = 0.0

    var ox: Float { get { return origin.x } set { origin.x = newValue } }
    var oy: Float { get { return origin.y } set { origin.y = newValue } }
    var oz: Float { get { return origin.z } set { origin.z = newValue } }

    var dx: Float { get { return direction.x } set { direction.x = newValue } }
    var dy: Float { get { return direction.y } set { direction.y = newValue } }
    var dz: Float { get { return direction.z } set { direction.z = newValue } }

    init() {
        origin = simd_float3(0, 0, 0)
        direction = simd_float3(0, 0, 0)
    }

    // Creates a new ray that points from the given origin to the given
    // direction. The ray has infinite Length. The direction vector is
    // normalized.
    //
    // @param ox ray origin x
    // @param oy ray origin y
    // @param oz ray origin z
    // @param dx ray direction x
    // @param dy ray direction y
    // @param dz ray direction z
    init(_ ox: Float, _ oy: Float, _ oz: Float, _ dx: Float, _ dy: Float, _ dz: Float) {
        origin = simd_float3(ox, oy, oz)

        direction = simd_float3(dx, dy, dz)

        let inf: Float = 1.0 / simd_length(direction)

        direction *= inf

        tMin = Self.EPSILON
        tMax = Float.infinity
    }

    // Creates a new ray that points from the given origin to the given
    // direction. The ray has infinite Length. The direction vector is
    // normalized.
    //
    // @param o ray origin
    // @param d ray direction (need not be normalized)
    init(_ o: Point3, _ d: Vector3) {
        origin = simd_float3(o.x, o.y, o.z)

        direction = simd_float3(d.x, d.y, d.z)

        let inf: Float = 1.0 / simd_length(direction)

        direction *= inf

        tMin = Self.EPSILON
        tMax = Float.infinity
    }

    // Creates a new ray that points from point a to point b. The created ray
    // will set tMin and tMax to limit the ray to the segment (a,b)
    // (non-inclusive of a and b). This is often used to create shadow rays.
    //
    // @param a start point
    // @param b end point
    init(_ a: Point3, _ b: Point3) {
        origin = simd_float3(a.x, a.y, a.z)

        direction = simd_float3(b.x, b.y, b.z) - origin

        tMin = Self.EPSILON

        let n: Float = simd_length(direction)
        let inf: Float = 1.0 / simd_length(direction)

        direction *= inf

        tMax = n - Self.EPSILON
    }

    // Create a new ray by transforming the supplied one by the given matrix. If
    // the matrix is null, the original ray is returned.
    //
    // @param m matrix to transform the ray by
    func transform(_ m: AffineTransform?) -> Ray {
        if m == nil {
            return self
        }

        let r: Ray = Ray()

        r.ox = m!.transformPX(ox, oy, oz)
        r.oy = m!.transformPY(ox, oy, oz)
        r.oz = m!.transformPZ(ox, oy, oz)
        r.dx = m!.transformVX(dx, dy, dz)
        r.dy = m!.transformVY(dx, dy, dz)
        r.dz = m!.transformVZ(dx, dy, dz)

        r.tMin = tMin
        r.tMax = tMax

        return r
    }

    // Normalize the direction component of the ray.
    func normalize() {
        let inf: Float = 1.0 / simd_length(direction)

        direction *= inf
    }

    // Gets the minimum distance along the ray - usually 0.
    //
    // @return value of the smallest distance along the ray
    func getMin() -> Float {
        return tMin
    }

    // Gets the maximum distance along the ray. May be infinite.
    //
    // @return value of the largest distance along the ray
    func getMax() -> Float {
        return tMax
    }

    // Creates a vector to represent the direction of the ray.
    //
    // @return a vector equal to the direction of this ray
    func getDirection() -> Vector3 {
        return Vector3(direction.x, direction.y, direction.z) // Vector3(direction)
    }

    // Checks to see if the specified distance falls within the valid range on
    // this ray. This should always be used before an intersection with the ray
    // is detected.
    //
    // @param t distance to be tested
    // @return true if t falls between the minimum and maximum
    //         distance of this ray, false otherwise
    func isInside(_ t: Float) -> Bool {
        return (tMin < t) && (t < tMax)
    }

    // Gets the end point of the ray. A reference to dest is
    // returned to support chaining.
    //
    // @param dest reference to the point to store
    // @return reference to dest
    @discardableResult
    func getPoint(_ dest: Point3) -> Point3 {
        dest.x = ox + (tMax * dx)
        dest.y = oy + (tMax * dy)
        dest.z = oz + (tMax * dz)

        return dest
    }

    // Computes the dot product of an arbitrary vector with the direction of the
    // ray. This method avoids having to call getDirection() which would
    // instantiate a new Vector object.
    //
    // @param v vector
    // @return dot product of the ray direction and the specified vector
    func dot(_ v: Vector3) -> Float {
        return simd_dot(direction, simd_float3(v.x, v.y, v.z))
    }

    // Computes the dot product of an arbitrary vector with the direction of the
    // ray. This method avoids having to call getDirection() which would
    // instantiate a new Vector object.
    //
    // @param vx vector x coordinate
    // @param vy vector y coordinate
    // @param vz vector z coordinate
    // @return dot product of the ray direction and the specified vector
    func dot(_ vx: Float, _ vy: Float, _ vz: Float) -> Float {
        return simd_dot(direction, simd_float3(vx, vy, vz))
    }

    // updates the maximum to the specified distance if and only if the new
    // distance is smaller than the current one.
    //
    // @param t new maximum distance
    func setMax(_ t: Float) {
        tMax = t
    }
}

#else

final class Ray {
    static var EPSILON: Float = Float.ulpOfOne // 0.01f

    // var origin: [Float]
    // var direction: [Float]

    var tMin: Float = 0.0
    var tMax: Float = 0.0

    // var ox: Float { get { return origin[0] } set { origin[0] = newValue } }
    // var oy: Float { get { return origin[1] } set { origin[1] = newValue } }
    // var oz: Float { get { return origin[2] } set { origin[2] = newValue } }

    // var dx: Float { get { return direction[0] } set { direction[0] = newValue } }
    // var dy: Float { get { return direction[1] } set { direction[1] = newValue } }
    // var dz: Float { get { return direction[2] } set { direction[2] = newValue } }

    var ox: Float = 0.0
    var oy: Float = 0.0
    var oz: Float = 0.0

    var dx: Float = 0.0
    var dy: Float = 0.0
    var dz: Float = 0.0

    init() {
        // origin = [0, 0, 0]
        // direction = [0, 0, 0]
    }

    // Creates a new ray that points from the given origin to the given
    // direction. The ray has infinite Length. The direction vector is
    // normalized.
    //
    // @param ox ray origin x
    // @param oy ray origin y
    // @param oz ray origin z
    // @param dx ray direction x
    // @param dy ray direction y
    // @param dz ray direction z
    convenience init(_ ox: Float, _ oy: Float, _ oz: Float, _ dx: Float, _ dy: Float, _ dz: Float) {
        self.init()

        self.ox = ox
        self.oy = oy
        self.oz = oz

        self.dx = dx
        self.dy = dy
        self.dz = dz

        let inf: Float = 1.0 / sqrt((dx * dx) + (dy * dy) + (dz * dz))

        self.dx *= inf
        self.dy *= inf
        self.dz *= inf

        tMin = Self.EPSILON
        tMax = Float.infinity
    }

    // Creates a new ray that points from the given origin to the given
    // direction. The ray has infinite Length. The direction vector is
    // normalized.
    //
    // @param o ray origin
    // @param d ray direction (need not be normalized)
    convenience init(_ o: Point3, _ d: Vector3) {
        self.init()

        ox = o.x
        oy = o.y
        oz = o.z

        dx = d.x
        dy = d.y
        dz = d.z

        let inf: Float = 1.0 / sqrt((dx * dx) + (dy * dy) + (dz * dz))

        dx *= inf
        dy *= inf
        dz *= inf

        tMin = Self.EPSILON
        tMax = Float.infinity
    }

    // Creates a new ray that points from point a to point b. The created ray
    // will set tMin and tMax to limit the ray to the segment (a,b)
    // (non-inclusive of a and b). This is often used to create shadow rays.
    //
    // @param a start point
    // @param b end point
    convenience init(_ a: Point3, _ b: Point3) {
        self.init()

        ox = a.x
        oy = a.y
        oz = a.z

        dx = b.x - ox
        dy = b.y - oy
        dz = b.z - oz

        tMin = Self.EPSILON

        let n: Float = sqrt((dx * dx) + (dy * dy) + (dz * dz))
        let inf: Float = 1.0 / n

        dx *= inf
        dy *= inf
        dz *= inf

        tMax = n - Self.EPSILON
    }

    // Create a new ray by transforming the supplied one by the given matrix. If
    // the matrix is null, the original ray is returned.
    //
    // @param m matrix to transform the ray by
    func transform(_ m: AffineTransform?) -> Ray {
        if m == nil {
            return self
        }

        let r: Ray = Ray()

        r.ox = m!.transformPX(ox, oy, oz)
        r.oy = m!.transformPY(ox, oy, oz)
        r.oz = m!.transformPZ(ox, oy, oz)
        r.dx = m!.transformVX(dx, dy, dz)
        r.dy = m!.transformVY(dx, dy, dz)
        r.dz = m!.transformVZ(dx, dy, dz)

        r.tMin = tMin
        r.tMax = tMax

        return r
    }

    // Normalize the direction component of the ray.
    func normalize() {
        let inf: Float = 1.0 / sqrt((dx * dx) + (dy * dy) + (dz * dz))

        dx *= inf
        dy *= inf
        dz *= inf
    }

    // Gets the minimum distance along the ray - usually 0.
    //
    // @return value of the smallest distance along the ray
    func getMin() -> Float {
        return tMin
    }

    // Gets the maximum distance along the ray. May be infinite.
    //
    // @return value of the largest distance along the ray
    func getMax() -> Float {
        return tMax
    }

    // Creates a vector to represent the direction of the ray.
    //
    // @return a vector equal to the direction of this ray
    func getDirection() -> Vector3 {
        return Vector3(dx, dy, dz)
    }

    // Checks to see if the specified distance falls within the valid range on
    // this ray. This should always be used before an intersection with the ray
    // is detected.
    //
    // @param t distance to be tested
    // @return true if t falls between the minimum and maximum
    //         distance of this ray, false otherwise
    func isInside(_ t: Float) -> Bool {
        return (tMin < t) && (t < tMax)
    }

    // Gets the end point of the ray. A reference to dest is
    // returned to support chaining.
    //
    // @param dest reference to the point to store
    // @return reference to dest
    @discardableResult
    func getPoint(_ dest: Point3) -> Point3 {
        dest.x = ox + (tMax * dx)
        dest.y = oy + (tMax * dy)
        dest.z = oz + (tMax * dz)

        return dest
    }

    // Computes the dot product of an arbitrary vector with the direction of the
    // ray. This method avoids having to call getDirection() which would
    // instantiate a new Vector object.
    //
    // @param v vector
    // @return dot product of the ray direction and the specified vector
    func dot(_ v: Vector3) -> Float {
        return (dx * v.x) + (dy * v.y) + (dz * v.z)
    }

    // Computes the dot product of an arbitrary vector with the direction of the
    // ray. This method avoids having to call getDirection() which would
    // instantiate a new Vector object.
    //
    // @param vx vector x coordinate
    // @param vy vector y coordinate
    // @param vz vector z coordinate
    // @return dot product of the ray direction and the specified vector
    func dot(_ vx: Float, _ vy: Float, _ vz: Float) -> Float {
        return (dx * vx) + (dy * vy) + (dz * vz)
    }

    // updates the maximum to the specified distance if and only if the new
    // distance is smaller than the current one.
    //
    // @param t new maximum distance
    func setMax(_ t: Float) {
        tMax = t
    }
}

#endif
