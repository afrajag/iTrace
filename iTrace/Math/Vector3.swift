//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

import Foundation

#if !DEBUG

import simd

infix operator •: BitwiseShiftPrecedence
infix operator ×: BitwiseShiftPrecedence

final class Vector3: CustomStringConvertible, Comparable, Codable {
    static var COS_THETA = [Float](repeating: 0, count: 256)
    static var SIN_THETA = [Float](repeating: 0, count: 256)
    static var COS_PHI = [Float](repeating: 0, count: 256)
    static var SIN_PHI = [Float](repeating: 0, count: 256)

    static func initVectorTables() {
        UI.printInfo(.QMC, "Initializing trigonometry lookup tables ...")

        for i in 0 ..< 256 {
            let angle: Double = (Double(i) * Double.pi) / 256.0

            Self.COS_THETA[i] = Float(cos(angle))
            Self.SIN_THETA[i] = Float(sin(angle))
            Self.COS_PHI[i] = Float(cos(2 * angle))
            Self.SIN_PHI[i] = Float(sin(2 * angle))
        }
    }

    // MARK: model

    var model: simd_float3

    // MARK: properties

    var x: Float { get { return model.x } set { model.x = newValue } }
    var y: Float { get { return model.y } set { model.y = newValue } }
    var z: Float { get { return model.z } set { model.z = newValue } }

    var r: Float { get { return model.x } set { model.x = newValue } }
    var g: Float { get { return model.y } set { model.y = newValue } }
    var b: Float { get { return model.z } set { model.z = newValue } }

    var squaredLength: Float { return simd_length_squared(model) }
    var length: Float { return simd_length(model) }
    var unitVector: Vector3 { return self / length }

    static let ZERO: Vector3 = Vector3(0.0, 0.0, 0.0)

    // MARK: initialization

    init() {
        self.model = simd_float3(0, 0, 0)
    }

    init(_ x: Float, _ y: Float, _ z: Float) {
        self.model = simd_float3(x: x, y: y, z: z)
    }

    init(_ v: Vector3) {
        self.model = v.model
    }

    init(_ from: simd_float3) {
        self.model = from
    }

    // MARK: methods

    func makeUnitVector() {
        model *= (1.0 / length)
    }

    // MARK: custom operators

    // dot product
    static func •(lhs: Vector3, rhs: Vector3) -> Float {
        return simd_dot(lhs.model, rhs.model)
    }

    static func ×(lhs: Vector3, rhs: Vector3) -> Vector3 {
        return Vector3(simd_cross(lhs.model, rhs.model))
    }

    // MARK: operator overloads

    static prefix func -(vec3: Vector3) -> Vector3 { return Vector3(-vec3.model) }

    static func +(lhs: Vector3, rhs: Vector3) -> Vector3 {
        return Vector3(lhs.model + rhs.model)
    }

    static func -(lhs: Vector3, rhs: Vector3) -> Vector3 {
        return Vector3(lhs.model - rhs.model)
    }

    static func *(lhs: Vector3, rhs: Vector3) -> Vector3 {
        return Vector3(lhs.model * rhs.model)
    }

    static func /(lhs: Vector3, rhs: Vector3) -> Vector3 {
        return Vector3(lhs.model / rhs.model)
    }

    static func +(lhs: Vector3, rhs: Float) -> Vector3 {
        return Vector3(lhs.x + rhs, lhs.y + rhs, lhs.z + rhs)
    }

    static func -(lhs: Vector3, rhs: Float) -> Vector3 {
        return Vector3(lhs.x - rhs, lhs.y - rhs, lhs.z - rhs)
    }

    static func *(lhs: Vector3, rhs: Float) -> Vector3 {
        return Vector3(lhs.model * rhs)
    }

    static func *(lhs: Float, rhs: Vector3) -> Vector3 {
        return Vector3(lhs * rhs.model)
    }

    static func /(lhs: Vector3, rhs: Float) -> Vector3 {
        return Vector3(lhs.model / rhs)
    }

    static func +=(lhs: inout Vector3, rhs: Vector3) {
        lhs.model += rhs.model
    }

    static func -=(lhs: inout Vector3, rhs: Vector3) {
        lhs.model -= rhs.model
    }

    static func *=(lhs: inout Vector3, rhs: Vector3) {
        lhs.model *= rhs.model
    }

    static func /=(lhs: inout Vector3, rhs: Vector3) {
        lhs.model /= rhs.model
    }

    static func +=(lhs: inout Vector3, rhs: Float) {
        lhs.x += rhs; lhs.y += rhs; lhs.z += rhs
    }

    static func -=(lhs: inout Vector3, rhs: Float) {
        lhs.x -= rhs; lhs.y -= rhs; lhs.z -= rhs
    }

    static func *=(lhs: inout Vector3, rhs: Float) {
        lhs.model *= rhs
    }

    static func /=(lhs: inout Vector3, rhs: Float) {
        lhs.model /= rhs
    }

    subscript(index: Int) -> Float {
        return model[index]
    }

    func min() -> Float {
        return model.min()
    }
    
    func max() -> Float {
        return model.max()
    }
    
    @discardableResult
    static func decode(_ n: Int16) -> Vector3 {
        let t: Int32 = (Int32(n) & 0xFF00) >>> 8
        let p: Int32 = Int32(n & 0xFF)
        let dest: Vector3 = Vector3()

        dest.x = Self.SIN_THETA[Int(t)] * Self.COS_PHI[Int(p)]
        dest.y = Self.SIN_THETA[Int(t)] * Self.SIN_PHI[Int(p)]
        dest.z = Self.COS_THETA[Int(t)]

        return dest
    }

    func encode() -> Int16 {
        var theta: Int32 = Int32(acos(z) * (256.0 / Float.pi))

        if theta > 255 {
            theta = 255
        }

        var phi: Int32 = Int32(atan2(y, x) * (128.0 / Float.pi))

        if phi < 0 {
            phi += 256
        } else if phi > 255 {
            phi = 255
        }

        return Int16(bitPattern: UInt16(((theta & 0xFF) << 8) | (phi & 0xFF)))
    }

    @discardableResult
    func negate() -> Vector3 {
        model *= -1

        return self
    }

    @discardableResult
    func mul(_ s: Float) -> Vector3 {
        model *= s

        return self
    }

    @discardableResult
    func div(_ d: Float) -> Vector3 {
        model /= d

        return self
    }

    @discardableResult
    func normalize() -> Vector3 {
        model = simd_normalize(model)

        return self
    }

    @discardableResult
    func set(_ x: Float, _ y: Float, _ z: Float) -> Vector3 {
        self.x = x
        self.y = y
        self.z = z

        return self
    }

    @discardableResult
    func set(_ v: Vector3) -> Vector3 {
        x = v.x
        y = v.y
        z = v.z

        return self
    }

    func dot(_ vx: Float, _ vy: Float, _ vz: Float) -> Float {
        return self • Vector3(vx, vy, vz)
    }

    @discardableResult
    static func dot(_ v1: Vector3, _ v2: Vector3) -> Float {
        return v1 • v2
    }

    @discardableResult
    static func cross(_ v1: Vector3, _ v2: Vector3) -> Vector3 {
        return v1 × v2
    }

    var description: String { "(\(x), \(y), \(z))" }

    static func <(lhs: Vector3, rhs: Vector3) -> Bool {
        return lhs.x.isLess(than: rhs.x) && lhs.y.isLess(than: rhs.y) && lhs.z.isLess(than: rhs.z)
    }

    static func ==(lhs: Vector3, rhs: Vector3) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z
    }
}

#else

infix operator •: BitwiseShiftPrecedence
infix operator ×: BitwiseShiftPrecedence

final class Vector3: CustomStringConvertible, Comparable, Codable {
    static var COS_THETA = [Float](repeating: 0, count: 256)
    static var SIN_THETA = [Float](repeating: 0, count: 256)
    static var COS_PHI = [Float](repeating: 0, count: 256)
    static var SIN_PHI = [Float](repeating: 0, count: 256)

    static func initVectorTables() {
        UI.printInfo(.QMC, "Initializing trigonometry lookup tables ...")

        for i in 0 ..< 256 {
            let angle: Double = (Double(i) * Double.pi) / 256.0

            Self.COS_THETA[i] = Float(cos(angle))
            Self.SIN_THETA[i] = Float(sin(angle))
            Self.COS_PHI[i] = Float(cos(2 * angle))
            Self.SIN_PHI[i] = Float(sin(2 * angle))
        }
    }

    static let ZERO: Vector3 = Vector3(0.0, 0.0, 0.0)

    // MARK: model

    // var model: [Float]

    // MARK: properties

    // var x: Float { get { return model[0] } set { model[0] = newValue } }
    // var y: Float { get { return model[1] } set { model[1] = newValue } }
    // var z: Float { get { return model[2] } set { model[2] = newValue } }

    var x: Float = 0.0
    var y: Float = 0.0
    var z: Float = 0.0

    var squaredLength: Float { return (x * x) + (y * y) + (z * z) }
    var length: Float { return sqrt((x * x) + (y * y) + (z * z)) }
    var unitVector: Vector3 { return self / length }

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

    init(_ v: Vector3) {
        // self.model = v.model

        self.x = v.x
        self.y = v.y
        self.z = v.z
    }

    // MARK: methods

    func makeUnitVector() {
        x *= (1.0 / length)
        y *= (1.0 / length)
        z *= (1.0 / length)
    }

    // MARK: custom operators

    // dot product
    static func •(lhs: Vector3, rhs: Vector3) -> Float {
        return (lhs.x * rhs.x) + (lhs.y * rhs.y) + (lhs.z * rhs.z)
    }

    static func ×(lhs: Vector3, rhs: Vector3) -> Vector3 {
        let dest = Vector3()

        dest.x = (lhs.y * rhs.z) - (lhs.z * rhs.y)
        dest.y = (lhs.z * rhs.x) - (lhs.x * rhs.z)
        dest.z = (lhs.x * rhs.y) - (lhs.y * rhs.x)

        return dest
    }

    // MARK: operator overloads

    static prefix func -(vec3: Vector3) -> Vector3 {
        let dest = Vector3()

        dest.x = -vec3.x
        dest.y = -vec3.y
        dest.z = -vec3.z

        return dest
    }

    static func +(lhs: Vector3, rhs: Vector3) -> Vector3 {
        let dest = Vector3()

        dest.x = lhs.x + rhs.x
        dest.y = lhs.y + rhs.y
        dest.z = lhs.z + rhs.z

        return dest
    }

    static func -(lhs: Vector3, rhs: Vector3) -> Vector3 {
        let dest = Vector3()

        dest.x = lhs.x - rhs.x
        dest.y = lhs.y - rhs.y
        dest.z = lhs.z - rhs.z

        return dest
    }

    static func *(lhs: Vector3, rhs: Vector3) -> Vector3 {
        let dest = Vector3()

        dest.x = lhs.x * rhs.x
        dest.y = lhs.y * rhs.y
        dest.z = lhs.z * rhs.z

        return dest
    }

    static func /(lhs: Vector3, rhs: Vector3) -> Vector3 {
        let dest = Vector3()

        dest.x = lhs.x / rhs.x
        dest.y = lhs.y / rhs.y
        dest.z = lhs.z / rhs.z

        return dest
    }

    static func +(lhs: Vector3, rhs: Float) -> Vector3 {
        let dest = Vector3()

        dest.x = lhs.x + rhs
        dest.y = lhs.y + rhs
        dest.z = lhs.z + rhs

        return dest
    }

    static func -(lhs: Vector3, rhs: Float) -> Vector3 {
        let dest = Vector3()

        dest.x = lhs.x - rhs
        dest.y = lhs.y - rhs
        dest.z = lhs.z - rhs

        return dest
    }

    static func *(lhs: Vector3, rhs: Float) -> Vector3 {
        let dest = Vector3()

        dest.x = lhs.x * rhs
        dest.y = lhs.y * rhs
        dest.z = lhs.z * rhs

        return dest
    }

    static func *(lhs: Float, rhs: Vector3) -> Vector3 {
        let dest = Vector3()

        dest.x = lhs * rhs.x
        dest.y = lhs * rhs.y
        dest.z = lhs * rhs.z

        return dest
    }

    static func /(lhs: Vector3, rhs: Float) -> Vector3 {
        let dest = Vector3()

        dest.x = lhs.x / rhs
        dest.y = lhs.y / rhs
        dest.z = lhs.z / rhs

        return dest
    }

    static func +=(lhs: inout Vector3, rhs: Vector3) {
        lhs.x += rhs.x
        lhs.y += rhs.y
        lhs.z += rhs.z
    }

    static func -=(lhs: inout Vector3, rhs: Vector3) {
        lhs.x -= rhs.x
        lhs.y -= rhs.y
        lhs.z -= rhs.z
    }

    static func *=(lhs: inout Vector3, rhs: Vector3) {
        lhs.x *= rhs.x
        lhs.y *= rhs.y
        lhs.z *= rhs.z
    }

    static func /=(lhs: inout Vector3, rhs: Vector3) {
        lhs.x /= rhs.x
        lhs.y /= rhs.y
        lhs.z /= rhs.z
    }

    static func +=(lhs: inout Vector3, rhs: Float) {
        lhs.x += rhs
        lhs.y += rhs
        lhs.z += rhs
    }

    static func -=(lhs: inout Vector3, rhs: Float) {
        lhs.x -= rhs
        lhs.y -= rhs
        lhs.z -= rhs
    }

    static func *=(lhs: inout Vector3, rhs: Float) {
        lhs.x *= rhs
        lhs.y *= rhs
        lhs.z *= rhs
    }

    static func /=(lhs: inout Vector3, rhs: Float) {
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

    func min() -> Float {
        return Swift.min(x, y, z)
    }
    
    func max() -> Float {
        return Swift.max(x, y, z)
    }
    
    @discardableResult
    static func decode(_ n: Int16) -> Vector3 {
        let t: Int32 = (Int32(n) & 0xFF00) >>> 8
        let p: Int32 = Int32(n & 0xFF)
        let dest: Vector3 = Vector3()

        dest.x = Self.SIN_THETA[Int(t)] * Self.COS_PHI[Int(p)]
        dest.y = Self.SIN_THETA[Int(t)] * Self.SIN_PHI[Int(p)]
        dest.z = Self.COS_THETA[Int(t)]

        return dest
    }

    func encode() -> Int16 {
        var theta: Int32 = Int32(acos(z) * (256.0 / Float.pi))

        if theta > 255 {
            theta = 255
        }

        var phi: Int32 = Int32(atan2(y, x) * (128.0 / Float.pi))

        if phi < 0 {
            phi += 256
        } else if phi > 255 {
            phi = 255
        }

        return Int16(bitPattern: UInt16(((theta & 0xFF) << 8) | (phi & 0xFF)))
    }

    @discardableResult
    func negate() -> Vector3 {
        x = -x
        y = -y
        z = -z

        return self
    }

    @discardableResult
    func mul(_ s: Float) -> Vector3 {
        x *= s
        y *= s
        z *= s

        return self
    }

    @discardableResult
    func div(_ d: Float) -> Vector3 {
        x /= d
        y /= d
        z /= d

        return self
    }

    @discardableResult
    func normalize() -> Vector3 {
        let inf: Float = 1.0 / length

        x *= inf
        y *= inf
        z *= inf

        return self
    }

    @discardableResult
    func set(_ x: Float, _ y: Float, _ z: Float) -> Vector3 {
        self.x = x
        self.y = y
        self.z = z

        return self
    }

    @discardableResult
    func set(_ v: Vector3) -> Vector3 {
        x = v.x
        y = v.y
        z = v.z

        return self
    }

    func dot(_ vx: Float, _ vy: Float, _ vz: Float) -> Float {
        return self • Vector3(vx, vy, vz)
    }

    @discardableResult
    static func dot(_ v1: Vector3, _ v2: Vector3) -> Float {
        return v1 • v2
    }

    @discardableResult
    static func cross(_ v1: Vector3, _ v2: Vector3) -> Vector3 {
        return v1 × v2
    }

    var description: String { "(\(x), \(y), \(z))" }

    static func <(lhs: Vector3, rhs: Vector3) -> Bool {
        return lhs.x.isLess(than: rhs.x) && lhs.y.isLess(than: rhs.y) && lhs.z.isLess(than: rhs.z)
    }

    static func ==(lhs: Vector3, rhs: Vector3) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z
    }
}

#endif
