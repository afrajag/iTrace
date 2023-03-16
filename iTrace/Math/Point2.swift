//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

#if !DEBUG

import simd

final class Point2: CustomStringConvertible, Comparable, Codable {
    // MARK: model

    var model: simd_float2

    // MARK: properties

    var x: Float { get { return model.x } set { model.x = newValue } }
    var y: Float { get { return model.y } set { model.y = newValue } }

    static let ZERO: Point2 = Point2(0.0, 0.0)

    // MARK: initialization

    init() {
        model = simd_float2(0, 0)
    }

    init(_ x: Float, _ y: Float) {
        model = simd_float2(x: x, y: y)
    }

    init(_ from: simd_float2) {
        model = from
    }

    convenience init(_ p: Point2) {
        self.init()

        x = p.x
        y = p.y
    }

    // MARK: operator overloads

    static prefix func -(vec3: Point2) -> Point2 { return Point2(-vec3.model) }

    static func +(lhs: Point2, rhs: Point2) -> Point2 {
        return Point2(lhs.model + rhs.model)
    }

    static func -(lhs: Point2, rhs: Point2) -> Point2 {
        return Point2(lhs.model - rhs.model)
    }

    static func *(lhs: Point2, rhs: Point2) -> Point2 {
        return Point2(lhs.model * rhs.model)
    }

    static func /(lhs: Point2, rhs: Point2) -> Point2 {
        return Point2(lhs.model / rhs.model)
    }

    static func +(lhs: Point2, rhs: Float) -> Point2 {
        return Point2(lhs.x + rhs, lhs.y + rhs)
    }

    static func -(lhs: Point2, rhs: Float) -> Point2 {
        return Point2(lhs.x - rhs, lhs.y - rhs)
    }

    static func *(lhs: Point2, rhs: Float) -> Point2 {
        return Point2(lhs.model * rhs)
    }

    static func *(lhs: Float, rhs: Point2) -> Point2 {
        return Point2(lhs * rhs.model)
    }

    static func /(lhs: Point2, rhs: Float) -> Point2 {
        return Point2(lhs.model / rhs)
    }

    static func +=(lhs: inout Point2, rhs: Point2) {
        lhs.model += rhs.model
    }

    static func -=(lhs: inout Point2, rhs: Point2) {
        lhs.model -= rhs.model
    }

    static func *=(lhs: inout Point2, rhs: Point2) {
        lhs.model *= rhs.model
    }

    static func /=(lhs: inout Point2, rhs: Point2) {
        lhs.model /= rhs.model
    }

    static func +=(lhs: inout Point2, rhs: Float) {
        lhs.x += rhs; lhs.y += rhs
    }

    static func -=(lhs: inout Point2, rhs: Float) {
        lhs.x -= rhs; lhs.y -= rhs
    }

    static func *=(lhs: inout Point2, rhs: Float) {
        lhs.model *= rhs
    }

    static func /=(lhs: inout Point2, rhs: Float) {
        lhs.model /= rhs
    }

    subscript(index: Int) -> Float {
        return model[index]
    }

    @discardableResult
    func set(_ x: Float, _ y: Float) -> Point2 {
        self.x = x
        self.y = y

        return self
    }

    @discardableResult
    func set(_ p: Point2) -> Point2 {
        x = p.x
        y = p.y

        return self
    }

    var description: String { "(\(x), \(y))" }

    static func <(lhs: Point2, rhs: Point2) -> Bool {
        return lhs.x.isLess(than: rhs.x) && lhs.y.isLess(than: rhs.y)
    }

    static func ==(lhs: Point2, rhs: Point2) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }
}

#else

final class Point2: CustomStringConvertible {
    var x: Float = 0.0
    var y: Float = 0.0

    init() {}

    init(_ x: Float, _ y: Float) {
        self.x = x
        self.y = y
    }

    init(_ p: Point2) {
        x = p.x
        y = p.y
    }

    @discardableResult
    func set(_ x: Float, _ y: Float) -> Point2 {
        self.x = x
        self.y = y
        return self
    }

    func set(_ p: Point2) -> Point2 {
        x = p.x
        y = p.y
        return self
    }

    var description: String { "(\(x), \(y))" }
}

#endif
