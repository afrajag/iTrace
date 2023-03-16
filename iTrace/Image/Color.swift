//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

#if !DEBUG

import simd

final class Color: CustomStringConvertible, Codable, Hashable {
    static var NATIVE_SPACE: RGBSpace = RGBSpace.SRGB
    static var BLACK: Color = Color(0, 0, 0)
    static var WHITE: Color = Color(1, 1, 1)
    static var RED: Color = Color(1, 0, 0)
    static var GREEN: Color = Color(0, 1, 0)
    static var BLUE: Color = Color(0, 0, 1)
    static var YELLOW: Color = Color(1, 1, 0)
    static var CYAN: Color = Color(0, 1, 1)
    static var MAGENTA: Color = Color(1, 0, 1)
    static var GRAY: Color = Color(0.5, 0.5, 0.5)
    static var EXPONENT: [Float] = {
        var EXPONENT: [Float] = [Float](repeating: 0, count: 256)

        EXPONENT[0] = 0

        for i in 1 ..< 256 {
            var f: Float = 1.0
            let e: Int32 = Int32(i) - (128 + 8)

            if e > 0 {
                for _ in 0 ..< e {
                    f *= 2.0
                }
            } else {
                for _ in 0 ..< -e {
                    f *= 0.5
                }
            }

            EXPONENT[i] = f
        }

        return EXPONENT
    }()

    // MARK: model

    var model: simd_float3

    // MARK: properties

    private var x: Float { get { return model.x } set { model.x = newValue } }
    private var y: Float { get { return model.y } set { model.y = newValue } }
    private var z: Float { get { return model.z } set { model.z = newValue } }

    var r: Float { get { return model.x } set { model.x = newValue } }
    var g: Float { get { return model.y } set { model.y = newValue } }
    var b: Float { get { return model.z } set { model.z = newValue } }

    var squaredLength: Float { return simd_length_squared(model) }
    var length: Float { return simd_length(model) }
    var unitVector: Color { return self / length }

    static let ZERO: Color = Color(0.0, 0.0, 0.0)

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

    convenience init(_ gray: Float) {
        self.init()

        r = gray
        g = gray
        b = gray
    }

    convenience init(_ c: Color) {
        self.init()

        r = c.r
        g = c.g
        b = c.b
    }

    convenience init(_ rgb: Int32) {
        self.init()

        r = Float((rgb >> 16) & 0xFF) / 255.0
        g = Float((rgb >> 8) & 0xFF) / 255.0
        b = Float(rgb & 0xFF) / 255.0
    }

    // MARK: operator overloads

    static prefix func -(vec3: Color) -> Color { return Color(-vec3.model) }

    static func +(lhs: Color, rhs: Color) -> Color {
        return Color(lhs.model + rhs.model)
    }

    static func -(lhs: Color, rhs: Color) -> Color {
        return Color(lhs.model - rhs.model)
    }

    static func *(lhs: Color, rhs: Color) -> Color {
        return Color(lhs.model * rhs.model)
    }

    static func /(lhs: Color, rhs: Color) -> Color {
        return Color(lhs.model / rhs.model)
    }

    static func +(lhs: Color, rhs: Float) -> Color {
        return Color(lhs.x + rhs, lhs.y + rhs, lhs.z + rhs)
    }

    static func -(lhs: Color, rhs: Float) -> Color {
        return Color(lhs.x - rhs, lhs.y - rhs, lhs.z - rhs)
    }

    static func *(lhs: Color, rhs: Float) -> Color {
        return Color(lhs.model * rhs)
    }

    static func *(lhs: Float, rhs: Color) -> Color {
        return Color(lhs * rhs.model)
    }

    static func /(lhs: Color, rhs: Float) -> Color {
        return Color(lhs.model / rhs)
    }

    static func +=(lhs: inout Color, rhs: Color) {
        lhs.model += rhs.model
    }

    static func -=(lhs: inout Color, rhs: Color) {
        lhs.model -= rhs.model
    }

    static func *=(lhs: inout Color, rhs: Color) {
        lhs.model *= rhs.model
    }

    static func /=(lhs: inout Color, rhs: Color) {
        lhs.model /= rhs.model
    }

    static func +=(lhs: inout Color, rhs: Float) {
        lhs.x += rhs; lhs.y += rhs; lhs.z += rhs
    }

    static func -=(lhs: inout Color, rhs: Float) {
        lhs.x -= rhs; lhs.y -= rhs; lhs.z -= rhs
    }

    static func *=(lhs: inout Color, rhs: Float) {
        lhs.model *= rhs
    }

    static func /=(lhs: inout Color, rhs: Float) {
        lhs.model /= rhs
    }

    subscript(index: Int) -> Float {
        return model[index]
    }

    static func black() -> Color {
        return Color()
    }

    static func white() -> Color {
        return Color(1, 1, 1)
    }

    func toNonLinear() -> Color {
        r = Self.NATIVE_SPACE.gammaCorrect(r)
        g = Self.NATIVE_SPACE.gammaCorrect(g)
        b = Self.NATIVE_SPACE.gammaCorrect(b)

        return self
    }

    func toLinear() -> Color {
        r = Self.NATIVE_SPACE.ungammaCorrect(r)
        g = Self.NATIVE_SPACE.ungammaCorrect(g)
        b = Self.NATIVE_SPACE.ungammaCorrect(b)

        return self
    }

    func copy() -> Color {
        return Color(self)
    }

    @discardableResult
    func set(_ r: Float, _ g: Float, _ b: Float) -> Color {
        self.r = r
        self.g = g
        self.b = b

        return self
    }

    @discardableResult
    func set(_ c: Color) -> Color {
        r = c.r
        g = c.g
        b = c.b

        return self
    }

    func setRGB(_ rgb: Int32) -> Color {
        r = Float((rgb >> 16) & 0xFF) / 255.0
        g = Float((rgb >> 8) & 0xFF) / 255.0
        b = Float(rgb & 0xFF) / 255.0

        return self
    }

    func setRGBE(_ rgbe: Int32) -> Color {
        let f: Float = Self.EXPONENT[Int(rgbe) & 0xFF]

        r = f * (Float(rgbe >>> 24) + 0.5)

        let g_temp = Float((rgbe >> 16) & 0xFF) + 0.5
        g = f * g_temp

        let b_temp = Float((rgbe >> 8) & 0xFF) + 0.5
        b = f * b_temp

        return self
    }

    func isBlack() -> Bool {
        return (r <= 0.0) && (g <= 0.0) && (b <= 0.0)
    }

    func getLuminance() -> Float {
        return simd_dot(simd_float3(0.2989, 0.5866, 0.1145), model)
    }

    func getMin() -> Float {
        return model.min()
    }

    func getMax() -> Float {
        return model.max()
    }

    func getAverage() -> Float {
        return (r + g + b) / 3.0
    }

    func getRGB() -> [Float] {
        return [r, g, b]
    }

    func toRGB() -> Int32 {
        var ir: Int32 = Int32(r * 255 + 0.5)
        var ig: Int32 = Int32(g * 255 + 0.5)
        var ib: Int32 = Int32(b * 255 + 0.5)

        ir = ir.clamp(0, 255)
        ig = ig.clamp(0, 255)
        ib = ib.clamp(0, 255)

        return (ir << 16) | (ig << 8) | ib
    }

    func toRGBA(_ a: Float) -> Int32 {
        var ir: Int32 = Int32(r * 255 + 0.5)
        var ig: Int32 = Int32(g * 255 + 0.5)
        var ib: Int32 = Int32(b * 255 + 0.5)
        var ia: Int32 = Int32(a * 255 + 0.5)

        ir = ir.clamp(0, 255)
        ig = ig.clamp(0, 255)
        ib = ib.clamp(0, 255)
        ia = ia.clamp(0, 255)

        return (ia << 24) | (ir << 16) | (ig << 8) | ib
    }

    func toRGBE() -> Int32 {
        //  encode the color into 32bits while preserving HDR using Ward's RGBE
        //  technique
        var v: Float = max(r, g, b)

        if v < 1e-32 {
            return 0
        }

        //  get mantissa and exponent
        var m: Float = v
        var e: Int32 = 0

        if v > 1.0 {
            while m > 1.0 {
                m *= 0.5

                e += 1
            }
        } else if v <= 0.5 {
            while m <= 0.5 {
                m *= 2.0

                e -= 1
            }
        }

        v = (m * 255.0) / v

        var c: Int32 = e + 128

        c |= (Int32(r * v) << 24)
        c |= (Int32(g * v) << 16)
        c |= (Int32(b * v) << 8)

        return c
    }

    func constrainRGB() -> Color {
        //  clamp the RGB value to a representable value
        let w: Float = -min(0, r, g, b)

        if w > 0 {
            r += w
            g += w
            b += w
        }

        return self
    }

    func isNan() -> Bool {
        return r.isNaN || g.isNaN || b.isNaN
    }

    func isInf() -> Bool {
        return r.isInfinite || g.isInfinite || b.isInfinite
    }

    @discardableResult
    func add(_ c: Color) -> Color {
        model += c.model

        return self
    }

    static func add(_ c1: Color, _ c2: Color) -> Color {
        return c1 + c2
    }

    @discardableResult
    func madd(_ s: Float, _ c: Color) -> Color {
        model += (s * c.model)

        return self
    }

    @discardableResult
    func madd(_ s: Color, _ c: Color) -> Color {
        model += (s.model * c.model)

        return self
    }

    @discardableResult
    func sub(_ c: Color) -> Color {
        model -= c.model

        return self
    }

    static func sub(_ c1: Color, _ c2: Color) -> Color {
        return c1 - c2
    }

    @discardableResult
    func mul(_ c: Color) -> Color {
        model *= c.model

        return self
    }

    static func mul(_ c1: Color, _ c2: Color) -> Color {
        return c1 * c2
    }

    @discardableResult
    func mul(_ s: Float) -> Color {
        model *= s

        return self
    }

    static func mul(_ s: Float, _ c: Color) -> Color {
        return s * c
    }

    @discardableResult
    func div(_ c: Color) -> Color {
        model /= c.model

        return self
    }

    static func div(_ c1: Color, _ c2: Color) -> Color {
        return c1 / c2
    }

    func cExp() -> Color {
        r = exp(r)
        g = exp(g)
        b = exp(b)

        return self
    }

    func opposite() -> Color {
        let one: Color = Color(1, 1, 1)

        model = one.model - model

        return self
    }

    func clamp(_ min: Float, _ max: Float) -> Color {
        model = simd_clamp(model, simd_float3(repeating: min), simd_float3(repeating: max))

        return self
    }

    static func blend(_ c1: Color, _ c2: Color, _ b: Float) -> Color {
        let dest: Color = Color()

        dest.r = (1.0 - b) * c1.r + b * c2.r
        dest.g = (1.0 - b) * c1.g + b * c2.g
        dest.b = (1.0 - b) * c1.b + b * c2.b

        return dest
    }

    @discardableResult
    static func blend(_ c1: Color, _ c2: Color, _ b: Color) -> Color {
        let dest: Color = Color()

        dest.r = (1.0 - b.r) * c1.r + b.r * c2.r
        dest.g = (1.0 - b.g) * c1.g + b.g * c2.g
        dest.b = (1.0 - b.b) * c1.b + b.b * c2.b

        return dest
    }

    static func hasContrast(_ c1: Color, _ c2: Color, _ thresh: Float) -> Bool {
        if (abs(c1.r - c2.r) / (c1.r + c2.r)) > thresh {
            return true
        }

        if (abs(c1.g - c2.g) / (c1.g + c2.g)) > thresh {
            return true
        }

        if (abs(c1.b - c2.b) / (c1.b + c2.b)) > thresh {
            return true
        }

        return false
    }

    var description: String { "(\(r), \(g), \(b))" }
}

#else

final class Color: CustomStringConvertible, Codable, Hashable {
    static var NATIVE_SPACE: RGBSpace = RGBSpace.SRGB
    static var BLACK: Color = Color(0, 0, 0)
    static var WHITE: Color = Color(1, 1, 1)
    static var RED: Color = Color(1, 0, 0)
    static var GREEN: Color = Color(0, 1, 0)
    static var BLUE: Color = Color(0, 0, 1)
    static var YELLOW: Color = Color(1, 1, 0)
    static var CYAN: Color = Color(0, 1, 1)
    static var MAGENTA: Color = Color(1, 0, 1)
    static var GRAY: Color = Color(0.5, 0.5, 0.5)
    static var EXPONENT: [Float] = {
        var EXPONENT: [Float] = [Float](repeating: 0, count: 256)

        EXPONENT[0] = 0

        for i in 1 ..< 256 {
            var f: Float = 1.0
            let e: Int32 = Int32(i) - (128 + 8)

            if e > 0 {
                for _ in 0 ..< e {
                    f *= 2.0
                }
            } else {
                for _ in 0 ..< -e {
                    f *= 0.5
                }
            }

            EXPONENT[i] = f
        }

        return EXPONENT
    }()

    static let ZERO: Color = Color(0.0, 0.0, 0.0)

    // MARK: model

    // var model: [Float]

    // MARK: properties

    // private var x: Float { get { return model[0] } set { model[0] = newValue } }
    // private var y: Float { get { return model[1] } set { model[1] = newValue } }
    // private var z: Float { get { return model[2] } set { model[2] = newValue } }

    // var r: Float { get { return model[0] } set { model[0] = newValue } }
    // var g: Float { get { return model[1] } set { model[1] = newValue } }
    // var b: Float { get { return model[2] } set { model[2] = newValue } }

    var r: Float = 0.0
    var g: Float = 0.0
    var b: Float = 0.0

    // MARK: initialization

    init() {
        // self.model = [0, 0, 0]
    }

    init(_ r: Float, _ g: Float, _ b: Float) {
        // self.model = [r, g, b]

        self.r = r
        self.g = g
        self.b = b
    }

    convenience init(_ gray: Float) {
        self.init()

        r = gray
        g = gray
        b = gray
    }

    convenience init(_ c: Color) {
        self.init()

        r = c.r
        g = c.g
        b = c.b
    }

    convenience init(_ rgb: Int32) {
        self.init()

        r = Float((rgb >> 16) & 0xFF) / 255.0
        g = Float((rgb >> 8) & 0xFF) / 255.0
        b = Float(rgb & 0xFF) / 255.0
    }

    // MARK: operator overloads

    static prefix func -(vec3: Color) -> Color {
        let dest = Color()

        dest.r = -vec3.r
        dest.g = -vec3.g
        dest.b = -vec3.b

        return dest
    }

    static func +(lhs: Color, rhs: Color) -> Color {
        let dest = Color()

        dest.r = lhs.r + rhs.r
        dest.g = lhs.g + rhs.g
        dest.b = lhs.b + rhs.b

        return dest
    }

    static func -(lhs: Color, rhs: Color) -> Color {
        let dest = Color()

        dest.r = lhs.r - rhs.r
        dest.g = lhs.g - rhs.g
        dest.b = lhs.b - rhs.b

        return dest
    }

    static func *(lhs: Color, rhs: Color) -> Color {
        let dest = Color()

        dest.r = lhs.r * rhs.r
        dest.g = lhs.g * rhs.g
        dest.b = lhs.b * rhs.b

        return dest
    }

    static func /(lhs: Color, rhs: Color) -> Color {
        let dest = Color()

        dest.r = lhs.r / rhs.r
        dest.g = lhs.g / rhs.g
        dest.b = lhs.b / rhs.b

        return dest
    }

    static func +(lhs: Color, rhs: Float) -> Color {
        let dest = Color()

        dest.r = lhs.r + rhs
        dest.g = lhs.g + rhs
        dest.b = lhs.b + rhs

        return dest
    }

    static func -(lhs: Color, rhs: Float) -> Color {
        let dest = Color()

        dest.r = lhs.r - rhs
        dest.g = lhs.g - rhs
        dest.b = lhs.b - rhs

        return dest
    }

    static func *(lhs: Color, rhs: Float) -> Color {
        let dest = Color()

        dest.r = lhs.r * rhs
        dest.g = lhs.g * rhs
        dest.b = lhs.b * rhs

        return dest
    }

    static func *(lhs: Float, rhs: Color) -> Color {
        let dest = Color()

        dest.r = lhs * rhs.r
        dest.g = lhs * rhs.g
        dest.b = lhs * rhs.b

        return dest
    }

    static func /(lhs: Color, rhs: Float) -> Color {
        let dest = Color()

        dest.r = lhs.r / rhs
        dest.g = lhs.g / rhs
        dest.b = lhs.b / rhs

        return dest
    }

    static func +=(lhs: inout Color, rhs: Color) {
        lhs.r += rhs.r
        lhs.g += rhs.g
        lhs.b += rhs.b
    }

    static func -=(lhs: inout Color, rhs: Color) {
        lhs.r -= rhs.r
        lhs.g -= rhs.g
        lhs.b -= rhs.b
    }

    static func *=(lhs: inout Color, rhs: Color) {
        lhs.r *= rhs.r
        lhs.g *= rhs.g
        lhs.b *= rhs.b
    }

    static func /=(lhs: inout Color, rhs: Color) {
        lhs.r /= rhs.r
        lhs.g /= rhs.g
        lhs.b /= rhs.b
    }

    static func +=(lhs: inout Color, rhs: Float) {
        lhs.r += rhs
        lhs.g += rhs
        lhs.b += rhs
    }

    static func -=(lhs: inout Color, rhs: Float) {
        lhs.r -= rhs
        lhs.g -= rhs
        lhs.b -= rhs
    }

    static func *=(lhs: inout Color, rhs: Float) {
        lhs.r *= rhs
        lhs.g *= rhs
        lhs.b *= rhs
    }

    static func /=(lhs: inout Color, rhs: Float) {
        lhs.r /= rhs
        lhs.g /= rhs
        lhs.b /= rhs
    }

    subscript(index: Int) -> Float {
        // return model[index]

        switch index {
            case 0:
                return r
            case 1:
                return g
            default:
                return b
        }
    }

    static func black() -> Color {
        return Color()
    }

    static func white() -> Color {
        return Color(1, 1, 1)
    }

    func toNonLinear() -> Color {
        r = Self.NATIVE_SPACE.gammaCorrect(r)
        g = Self.NATIVE_SPACE.gammaCorrect(g)
        b = Self.NATIVE_SPACE.gammaCorrect(b)

        return self
    }

    func toLinear() -> Color {
        r = Self.NATIVE_SPACE.ungammaCorrect(r)
        g = Self.NATIVE_SPACE.ungammaCorrect(g)
        b = Self.NATIVE_SPACE.ungammaCorrect(b)

        return self
    }

    func copy() -> Color {
        return Color(self)
    }

    @discardableResult
    func set(_ r: Float, _ g: Float, _ b: Float) -> Color {
        self.r = r
        self.g = g
        self.b = b

        return self
    }

    @discardableResult
    func set(_ c: Color) -> Color {
        r = c.r
        g = c.g
        b = c.b

        return self
    }

    func setRGB(_ rgb: Int32) -> Color {
        r = Float((rgb >> 16) & 0xFF) / 255.0
        g = Float((rgb >> 8) & 0xFF) / 255.0
        b = Float(rgb & 0xFF) / 255.0

        return self
    }

    func setRGBE(_ rgbe: Int32) -> Color {
        let f: Float = Self.EXPONENT[Int(rgbe) & 0xFF]

        r = f * (Float(rgbe >>> 24) + 0.5)

        let g_temp = Float((rgbe >> 16) & 0xFF) + 0.5
        g = f * g_temp

        let b_temp = Float((rgbe >> 8) & 0xFF) + 0.5
        b = f * b_temp

        return self
    }

    func isBlack() -> Bool {
        return (r <= 0.0) && (g <= 0.0) && (b <= 0.0)
    }

    func getLuminance() -> Float {
        return (0.2989 * r) + (0.5866 * g) + (0.1145 * b)
    }

    func getMin() -> Float {
        // return model.min()!
        min(r, g, b)
    }

    func getMax() -> Float {
        // return model.max()!
        max(r, g, b)
    }

    func getAverage() -> Float {
        return (r + g + b) / 3.0
    }

    func getRGB() -> [Float] {
        return [r, g, b]
    }

    func toRGB() -> Int32 {
        var ir: Int32 = Int32(r * 255 + 0.5)
        var ig: Int32 = Int32(g * 255 + 0.5)
        var ib: Int32 = Int32(b * 255 + 0.5)

        ir = ir.clamp(0, 255)
        ig = ig.clamp(0, 255)
        ib = ib.clamp(0, 255)

        return (ir << 16) | (ig << 8) | ib
    }

    func toRGBA(_ a: Float) -> Int32 {
        var ir: Int32 = Int32(r * 255 + 0.5)
        var ig: Int32 = Int32(g * 255 + 0.5)
        var ib: Int32 = Int32(b * 255 + 0.5)
        var ia: Int32 = Int32(a * 255 + 0.5)

        ir = ir.clamp(0, 255)
        ig = ig.clamp(0, 255)
        ib = ib.clamp(0, 255)
        ia = ia.clamp(0, 255)

        return (ia << 24) | (ir << 16) | (ig << 8) | ib
    }

    func toRGBE() -> Int32 {
        //  encode the color into 32bits while preserving HDR using Ward's RGBE
        //  technique
        var v: Float = max(r, g, b)

        if v < 1e-32 {
            return 0
        }

        //  get mantissa and exponent
        var m: Float = v
        var e: Int32 = 0

        if v > 1.0 {
            while m > 1.0 {
                m *= 0.5

                e += 1
            }
        } else if v <= 0.5 {
            while m <= 0.5 {
                m *= 2.0

                e -= 1
            }
        }

        v = (m * 255.0) / v

        var c: Int32 = e + 128

        c |= (Int32(r * v) << 24)
        c |= (Int32(g * v) << 16)
        c |= (Int32(b * v) << 8)

        return c
    }

    func constrainRGB() -> Color {
        //  clamp the RGB value to a representable value
        let w: Float = -min(0, r, g, b)

        if w > 0 {
            r += w
            g += w
            b += w
        }

        return self
    }

    func isNan() -> Bool {
        return r.isNaN || g.isNaN || b.isNaN
    }

    func isInf() -> Bool {
        return r.isInfinite || g.isInfinite || b.isInfinite
    }

    @discardableResult
    func add(_ c: Color) -> Color {
        // self.model += c.model

        r += c.r
        g += c.g
        b += c.b

        return self
    }

    static func add(_ c1: Color, _ c2: Color) -> Color {
        return c1 + c2
    }

    @discardableResult
    func madd(_ s: Float, _ c: Color) -> Color {
        r += (s * c.r)
        g += (s * c.g)
        b += (s * c.b)

        return self
    }

    @discardableResult
    func madd(_ s: Color, _ c: Color) -> Color {
        r += (s.r * c.r)
        g += (s.g * c.g)
        b += (s.b * c.b)

        return self
    }

    @discardableResult
    func sub(_ c: Color) -> Color {
        r -= c.r
        g -= c.g
        b -= c.b

        return self
    }

    static func sub(_ c1: Color, _ c2: Color) -> Color {
        return c1 - c2
    }

    @discardableResult
    func mul(_ c: Color) -> Color {
        r *= c.r
        g *= c.g
        b *= c.b

        return self
    }

    static func mul(_ c1: Color, _ c2: Color) -> Color {
        return c1 * c2
    }

    @discardableResult
    func mul(_ s: Float) -> Color {
        r *= s
        g *= s
        b *= s

        return self
    }

    static func mul(_ s: Float, _ c: Color) -> Color {
        return s * c
    }

    @discardableResult
    func div(_ c: Color) -> Color {
        r /= c.r
        g /= c.g
        b /= c.b

        return self
    }

    static func div(_ c1: Color, _ c2: Color) -> Color {
        return c1 / c2
    }

    func cExp() -> Color {
        r = exp(r)
        g = exp(g)
        b = exp(b)

        return self
    }

    func opposite() -> Color {
        let one: Color = Color(1, 1, 1)

        r = one.r - r
        g = one.g - g
        b = one.b - b

        return self
    }

    func clamp(_ min: Float, _ max: Float) -> Color {
        r = r.clamp(min, max)
        g = g.clamp(min, max)
        b = b.clamp(min, max)

        return self
    }

    static func blend(_ c1: Color, _ c2: Color, _ b: Float) -> Color {
        let dest: Color = Color()

        dest.r = (1.0 - b) * c1.r + b * c2.r
        dest.g = (1.0 - b) * c1.g + b * c2.g
        dest.b = (1.0 - b) * c1.b + b * c2.b

        return dest
    }

    @discardableResult
    static func blend(_ c1: Color, _ c2: Color, _ b: Color) -> Color {
        let dest: Color = Color()

        dest.r = (1.0 - b.r) * c1.r + b.r * c2.r
        dest.g = (1.0 - b.g) * c1.g + b.g * c2.g
        dest.b = (1.0 - b.b) * c1.b + b.b * c2.b

        return dest
    }

    static func hasContrast(_ c1: Color, _ c2: Color, _ thresh: Float) -> Bool {
        if (abs(c1.r - c2.r) / (c1.r + c2.r)) > thresh {
            return true
        }

        if (abs(c1.g - c2.g) / (c1.g + c2.g)) > thresh {
            return true
        }

        if (abs(c1.b - c2.b) / (c1.b + c2.b)) > thresh {
            return true
        }

        return false
    }

    var description: String { "(\(r), \(g), \(b))" }
}

#endif

extension Color {
    func fuzzyEquals(_ other: Color) -> Bool {
        return MathUtils.doubleEquality(Double(r), Double(other.r)) &&
            MathUtils.doubleEquality(Double(g), Double(other.g)) &&
            MathUtils.doubleEquality(Double(b), Double(other.b))
    }

    static func ==(lhs: Color, rhs: Color) -> Bool {
        lhs.r == rhs.r && lhs.g == rhs.g && lhs.b == rhs.b
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(r)
        hasher.combine(g)
        hasher.combine(b)
    }
}
