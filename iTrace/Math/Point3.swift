//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

import Foundation

#if !DEBUG

import simd

final class Point3: CustomStringConvertible, Comparable, Codable {
    // MARK: model

    var model: simd_float3

    // MARK: properties

    var x: Float { get { return model.x } set { model.x = newValue } }
    var y: Float { get { return model.y } set { model.y = newValue } }
    var z: Float { get { return model.z } set { model.z = newValue } }

    static let ZERO: Point3 = Point3(0.0, 0.0, 0.0)

    // MARK: initialization

    init() {
        model = simd_float3(0, 0, 0)
    }

    init(_ x: Float, _ y: Float, _ z: Float) {
        model = simd_float3(x: x, y: y, z: z)
    }

    init(_ from: simd_float3) {
        model = from
    }

    convenience init(_ p: Point3) {
        self.init()

        x = p.x
        y = p.y
        z = p.z
    }

    // MARK: operator overloads

    static prefix func -(vec3: Point3) -> Point3 { return Point3(-vec3.model) }

    static func +(lhs: Point3, rhs: Point3) -> Point3 {
        return Point3(lhs.model + rhs.model)
    }

    static func -(lhs: Point3, rhs: Point3) -> Point3 {
        return Point3(lhs.model - rhs.model)
    }

    static func *(lhs: Point3, rhs: Point3) -> Point3 {
        return Point3(lhs.model * rhs.model)
    }

    static func /(lhs: Point3, rhs: Point3) -> Point3 {
        return Point3(lhs.model / rhs.model)
    }

    static func +(lhs: Point3, rhs: Float) -> Point3 {
        return Point3(lhs.x + rhs, lhs.y + rhs, lhs.z + rhs)
    }

    static func -(lhs: Point3, rhs: Float) -> Point3 {
        return Point3(lhs.x - rhs, lhs.y - rhs, lhs.z - rhs)
    }

    static func *(lhs: Point3, rhs: Float) -> Point3 {
        return Point3(lhs.model * rhs)
    }

    static func *(lhs: Float, rhs: Point3) -> Point3 {
        return Point3(lhs * rhs.model)
    }

    static func /(lhs: Point3, rhs: Float) -> Point3 {
        return Point3(lhs.model / rhs)
    }

    static func +=(lhs: inout Point3, rhs: Point3) {
        lhs.model += rhs.model
    }

    static func -=(lhs: inout Point3, rhs: Point3) {
        lhs.model -= rhs.model
    }

    static func *=(lhs: inout Point3, rhs: Point3) {
        lhs.model *= rhs.model
    }

    static func /=(lhs: inout Point3, rhs: Point3) {
        lhs.model /= rhs.model
    }

    static func +=(lhs: inout Point3, rhs: Float) {
        lhs.x += rhs; lhs.y += rhs; lhs.z += rhs
    }

    static func -=(lhs: inout Point3, rhs: Float) {
        lhs.x -= rhs; lhs.y -= rhs; lhs.z -= rhs
    }

    static func *=(lhs: inout Point3, rhs: Float) {
        lhs.model *= rhs
    }

    static func /=(lhs: inout Point3, rhs: Float) {
        lhs.model /= rhs
    }

    subscript(index: Int) -> Float {
        return model[index]
    }

    func distanceTo(_ p: Point3) -> Float {
        return simd_distance(model, p.model)
    }

    func distanceTo(_ px: Float, _ py: Float, _ pz: Float) -> Float {
        return simd_distance(model, Point3(px, py, pz).model)
    }

    func distanceToSquared(_ p: Point3) -> Float {
        return simd_distance_squared(model, p.model)
    }

    func distanceToSquared(_ px: Float, _ py: Float, _ pz: Float) -> Float {
        return simd_distance_squared(model, Point3(px, py, pz).model)
    }

    @discardableResult
    func set(_ x: Float, _ y: Float, _ z: Float) -> Point3 {
        self.x = x
        self.y = y
        self.z = z

        return self
    }

    @discardableResult
    func set(_ p: Point3) -> Point3 {
        x = p.x
        y = p.y
        z = p.z

        return self
    }

    @discardableResult
    static func add(_ p: Point3, _ v: Vector3) -> Point3 {
        return Point3(p.model + v.model)
    }

    @discardableResult
    static func sub(_ p1: Point3, _ p2: Point3) -> Vector3 {
        return Vector3(p1.model - p2.model)
    }

    static func mid(_ p1: Point3, _ p2: Point3) -> Point3 {
        let dest: Point3 = Point3()

        dest.x = 0.5 * (p1.x + p2.x)
        dest.y = 0.5 * (p1.y + p2.y)
        dest.z = 0.5 * (p1.z + p2.z)

        return dest
    }

    static func blend(_ p0: Point3, _ p1: Point3, _ blend: Float, _ dest: Point3) -> Point3 {
        let dest: Point3 = Point3()

        dest.x = ((1 - blend) * p0.x) + (blend * p1.x)
        dest.y = ((1 - blend) * p0.y) + (blend * p1.y)
        dest.z = ((1 - blend) * p0.z) + (blend * p1.z)

        return dest
    }

    static func normal(_ p0: Point3, _ p1: Point3, _ p2: Point3) -> Vector3 {
        let vertex1 = simd_float3(p0.model)
        let vertex2 = simd_float3(p1.model)
        let vertex3 = simd_float3(p2.model)

        let vector1 = vertex2 - vertex3
        let vector2 = vertex2 - vertex1

        let normal = simd_normalize(simd_cross(vector1, vector2))

        return Vector3(normal)
    }

    var description: String { "(\(x), \(y), \(z))" }

    static func <(lhs: Point3, rhs: Point3) -> Bool {
        return lhs.x.isLess(than: rhs.x) && lhs.y.isLess(than: rhs.y) && lhs.z.isLess(than: rhs.z)
    }

    static func ==(lhs: Point3, rhs: Point3) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z
    }
}

#else

final class Point3: CustomStringConvertible, Comparable, Codable {
    // MARK: model

    // var model: [Float]

    // MARK: properties

    // var x: Float { get { return model[0] } set { model[0] = newValue } }
    // var y: Float { get { return model[1] } set { model[1] = newValue } }
    // var z: Float { get { return model[2] } set { model[2] = newValue } }

    var x: Float = 0.0
    var y: Float = 0.0
    var z: Float = 0.0

    static let ZERO: Point3 = Point3(0.0, 0.0, 0.0)

    // MARK: initialization

    init() {
        // self.model = [0, 0, 0]
    }

    init(_ x: Float, _ y: Float, _ z: Float) {
        // self.model = [x, y, z]

        self.x = x
        self.y = y
        self.z = z
    }

    init(_ p: Point3) {
        // self.model = p.model

        x = p.x
        y = p.y
        z = p.z
    }

    // MARK: operator overloads

    static prefix func -(vec3: Point3) -> Point3 {
        let dest = Point3()

        dest.x = -vec3.x
        dest.y = -vec3.y
        dest.z = -vec3.z

        return dest
    }

    static func +(lhs: Point3, rhs: Point3) -> Point3 {
        let dest = Point3()

        dest.x = lhs.x + rhs.x
        dest.y = lhs.y + rhs.y
        dest.z = lhs.z + rhs.z

        return dest
    }

    static func -(lhs: Point3, rhs: Point3) -> Point3 {
        let dest = Point3()

        dest.x = lhs.x - rhs.x
        dest.y = lhs.y - rhs.y
        dest.z = lhs.z - rhs.z

        return dest
    }

    static func *(lhs: Point3, rhs: Point3) -> Point3 {
        let dest = Point3()

        dest.x = lhs.x * rhs.x
        dest.y = lhs.y * rhs.y
        dest.z = lhs.z * rhs.z

        return dest
    }

    static func /(lhs: Point3, rhs: Point3) -> Point3 {
        let dest = Point3()

        dest.x = lhs.x / rhs.x
        dest.y = lhs.y / rhs.y
        dest.z = lhs.z / rhs.z

        return dest
    }

    static func +(lhs: Point3, rhs: Float) -> Point3 {
        let dest = Point3()

        dest.x = lhs.x + rhs
        dest.y = lhs.y + rhs
        dest.z = lhs.z + rhs

        return dest
    }

    static func -(lhs: Point3, rhs: Float) -> Point3 {
        let dest = Point3()

        dest.x = lhs.x - rhs
        dest.y = lhs.y - rhs
        dest.z = lhs.z - rhs

        return dest
    }

    static func *(lhs: Point3, rhs: Float) -> Point3 {
        let dest = Point3()

        dest.x = lhs.x * rhs
        dest.y = lhs.y * rhs
        dest.z = lhs.z * rhs

        return dest
    }

    static func *(lhs: Float, rhs: Point3) -> Point3 {
        let dest = Point3()

        dest.x = lhs * rhs.x
        dest.y = lhs * rhs.y
        dest.z = lhs * rhs.z

        return dest
    }

    static func /(lhs: Point3, rhs: Float) -> Point3 {
        let dest = Point3()

        dest.x = lhs.x / rhs
        dest.y = lhs.y / rhs
        dest.z = lhs.z / rhs

        return dest
    }

    static func +=(lhs: inout Point3, rhs: Point3) {
        lhs.x += rhs.x
        lhs.y += rhs.y
        lhs.z += rhs.z
    }

    static func -=(lhs: inout Point3, rhs: Point3) {
        lhs.x -= rhs.x
        lhs.y -= rhs.y
        lhs.z -= rhs.z
    }

    static func *=(lhs: inout Point3, rhs: Point3) {
        lhs.x *= rhs.x
        lhs.y *= rhs.y
        lhs.z *= rhs.z
    }

    static func /=(lhs: inout Point3, rhs: Point3) {
        lhs.x /= rhs.x
        lhs.y /= rhs.y
        lhs.z /= rhs.z
    }

    static func +=(lhs: inout Point3, rhs: Float) {
        lhs.x += rhs
        lhs.y += rhs
        lhs.z += rhs
    }

    static func -=(lhs: inout Point3, rhs: Float) {
        lhs.x -= rhs
        lhs.y -= rhs
        lhs.z -= rhs
    }

    static func *=(lhs: inout Point3, rhs: Float) {
        lhs.x *= rhs
        lhs.y *= rhs
        lhs.z *= rhs
    }

    static func /=(lhs: inout Point3, rhs: Float) {
        lhs.x /= rhs
        lhs.y /= rhs
        lhs.z /= rhs
    }

    subscript(index: Int) -> Float {
        // return model[index]

        switch index {
            case 0:
                return x
            case 1:
                return y
            default:
                return z
        }
    }

    func distanceTo(_ p: Point3) -> Float {
        let dx: Float = x - p.x
        let dy: Float = y - p.y
        let dz: Float = z - p.z

        return sqrt((dx * dx) + (dy * dy) + (dz * dz))
    }

    func distanceTo(_ px: Float, _ py: Float, _ pz: Float) -> Float {
        let dx: Float = x - px
        let dy: Float = y - py
        let dz: Float = z - pz

        return sqrt((dx * dx) + (dy * dy) + (dz * dz))
    }

    func distanceToSquared(_ p: Point3) -> Float {
        let dx: Float = x - p.x
        let dy: Float = y - p.y
        let dz: Float = z - p.z

        return (dx * dx) + (dy * dy) + (dz * dz)
    }

    func distanceToSquared(_ px: Float, _ py: Float, _ pz: Float) -> Float {
        let dx: Float = x - px
        let dy: Float = y - py
        let dz: Float = z - pz

        return (dx * dx) + (dy * dy) + (dz * dz)
    }

    @discardableResult
    func set(_ x: Float, _ y: Float, _ z: Float) -> Point3 {
        self.x = x
        self.y = y
        self.z = z

        return self
    }

    @discardableResult
    func set(_ p: Point3) -> Point3 {
        x = p.x
        y = p.y
        z = p.z

        return self
    }

    @discardableResult
    static func add(_ p: Point3, _ v: Vector3) -> Point3 {
        let dest = Point3()

        dest.x = p.x + v.x
        dest.y = p.y + v.y
        dest.z = p.z + v.z

        return dest
    }

    @discardableResult
    static func sub(_ p1: Point3, _ p2: Point3) -> Vector3 {
        let dest = Vector3()

        dest.x = p1.x - p2.x
        dest.y = p1.y - p2.y
        dest.z = p1.z - p2.z

        return dest
    }

    static func mid(_ p1: Point3, _ p2: Point3) -> Point3 {
        let dest: Point3 = Point3()

        dest.x = 0.5 * (p1.x + p2.x)
        dest.y = 0.5 * (p1.y + p2.y)
        dest.z = 0.5 * (p1.z + p2.z)

        return dest
    }

    static func blend(_ p0: Point3, _ p1: Point3, _ blend: Float, _ dest: Point3) -> Point3 {
        let dest: Point3 = Point3()

        dest.x = ((1 - blend) * p0.x) + (blend * p1.x)
        dest.y = ((1 - blend) * p0.y) + (blend * p1.y)
        dest.z = ((1 - blend) * p0.z) + (blend * p1.z)

        return dest
    }

    static func normal(_ p0: Point3, _ p1: Point3, _ p2: Point3) -> Vector3 {
        let edge1x: Float = p1.x - p0.x
        let edge1y: Float = p1.y - p0.y
        let edge1z: Float = p1.z - p0.z
        let edge2x: Float = p2.x - p0.x
        let edge2y: Float = p2.y - p0.y
        let edge2z: Float = p2.z - p0.z

        let dest = Vector3()

        dest.x = (edge1y * edge2z) - (edge1z * edge2y)
        dest.y = (edge1z * edge2x) - (edge1x * edge2z)
        dest.z = (edge1x * edge2y) - (edge1y * edge2x)

        return dest
    }

    var description: String { "(\(x), \(y), \(z))" }

    static func <(lhs: Point3, rhs: Point3) -> Bool {
        return lhs.x.isLess(than: rhs.x) && lhs.y.isLess(than: rhs.y) && lhs.z.isLess(than: rhs.z)
    }

    static func ==(lhs: Point3, rhs: Point3) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z
    }
}

#endif
