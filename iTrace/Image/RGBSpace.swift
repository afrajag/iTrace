//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//
import Foundation

final class RGBSpace {
    static var ADOBE: RGBSpace = RGBSpace(0.6400, 0.3300, 0.2100, 0.7100, 0.1500, 0.0600, 0.31271, 0.32902, 2.2, 0)
    static var APPLE: RGBSpace = RGBSpace(0.6250, 0.3400, 0.2800, 0.5950, 0.1550, 0.0700, 0.31271, 0.32902, 1.8, 0)
    static var NTSC: RGBSpace = RGBSpace(0.6700, 0.3300, 0.2100, 0.7100, 0.1400, 0.0800, 0.31010, 0.31620, 20.0 / 9.0, 0.018)
    static var HDTV: RGBSpace = RGBSpace(0.6400, 0.3300, 0.3000, 0.6000, 0.1500, 0.0600, 0.31271, 0.32902, 20.0 / 9.0, 0.018)
    static var SRGB: RGBSpace = RGBSpace(0.6400, 0.3300, 0.3000, 0.6000, 0.1500, 0.0600, 0.31271, 0.32902, 2.4, 0.00304)
    static var CIE: RGBSpace = RGBSpace(0.7350, 0.2650, 0.2740, 0.7170, 0.1670, 0.0090, 1 / 3.0, 1 / 3.0, 2.2, 0)
    static var EBU: RGBSpace = RGBSpace(0.6400, 0.3300, 0.2900, 0.6000, 0.1500, 0.0600, 0.31271, 0.32902, 20.0 / 9.0, 0.018)
    static var SMPTE_C: RGBSpace = RGBSpace(0.6300, 0.3400, 0.3100, 0.5950, 0.1550, 0.0700, 0.31271, 0.32902, 20.0 / 9.0, 0.018)
    static var SMPTE_240M: RGBSpace = RGBSpace(0.6300, 0.3400, 0.3100, 0.5950, 0.1550, 0.0700, 0.31271, 0.32902, 20.0 / 9.0, 0.018)
    static var WIDE_GAMUT: RGBSpace = RGBSpace(0.7347, 0.2653, 0.1152, 0.8264, 0.1566, 0.0177, 0.3457, 0.3585, 2.2, 0)

    var GAMMA_CURVE: [Int32]
    var INV_GAMMA_CURVE: [Int32]

    var gamma: Float = 0.0
    var breakPoint: Float = 0.0
    var slope: Float = 0.0
    var slopeMatch: Float = 0.0
    var segmentOffset: Float = 0.0

    var xr: Float = 0.0
    var yr: Float = 0.0
    var zr: Float = 0.0
    var xg: Float = 0.0
    var yg: Float = 0.0
    var zg: Float = 0.0
    var xb: Float = 0.0
    var yb: Float = 0.0
    var zb: Float = 0.0
    var xw: Float = 0.0
    var yw: Float = 0.0
    var zw: Float = 0.0
    var rx: Float = 0.0
    var ry: Float = 0.0
    var rz: Float = 0.0
    var gx: Float = 0.0
    var gy: Float = 0.0
    var gz: Float = 0.0
    var bx: Float = 0.0
    var by: Float = 0.0
    var bz: Float = 0.0
    var rw: Float = 0.0
    var gw: Float = 0.0
    var bw: Float = 0.0

    init(_ xRed: Float, _ yRed: Float, _ xGreen: Float, _ yGreen: Float, _ xBlue: Float, _ yBlue: Float, _ xWhite: Float, _ yWhite: Float, _ gamma: Float, _ breakPoint: Float) {
        self.gamma = gamma

        self.breakPoint = breakPoint

        if breakPoint > 0 {
            slope = 1 / (gamma / pow(breakPoint, 1 / gamma - 1) - gamma * breakPoint + breakPoint)

            slopeMatch = gamma * slope / pow(breakPoint, 1 / gamma - 1)

            segmentOffset = slopeMatch * pow(breakPoint, 1 / gamma) - slope * breakPoint
        } else {
            slope = 1

            slopeMatch = 1

            segmentOffset = 0
        }

        //  prepare gamma curves
        GAMMA_CURVE = [Int32](repeating: 0, count: 256)
        INV_GAMMA_CURVE = [Int32](repeating: 0, count: 256)

        for i in 0 ..< 256 {
            let c: Float = Float(i) / 255.0

            GAMMA_CURVE[i] = Int32((gammaCorrect(c) * 255 + 0.5).clamp(0.0, 255.0))

            INV_GAMMA_CURVE[i] = Int32((ungammaCorrect(c) * 255 + 0.5).clamp(0.0, 255.0))
        }

        let xr: Float = xRed
        let yr: Float = yRed
        let zr: Float = 1 - (xr + yr)
        let xg: Float = xGreen
        let yg: Float = yGreen
        let zg: Float = 1 - (xg + yg)
        let xb: Float = xBlue
        let yb: Float = yBlue
        let zb: Float = 1 - (xb + yb)

        xw = xWhite
        yw = yWhite
        zw = 1 - (xw + yw)

        //  xyz -> rgb matrix, before scaling to white.
        let rx: Float = (yg * zb) - (yb * zg)
        let ry: Float = (xb * zg) - (xg * zb)
        let rz: Float = (xg * yb) - (xb * yg)
        let gx: Float = (yb * zr) - (yr * zb)
        let gy: Float = (xr * zb) - (xb * zr)
        let gz: Float = (xb * yr) - (xr * yb)
        let bx: Float = (yr * zg) - (yg * zr)
        let by: Float = (xg * zr) - (xr * zg)
        let bz: Float = (xr * yg) - (xg * yr)

        //  White scaling factors
        //  Dividing by yw scales the white luminance to unity, as conventional
        rw = ((rx * xw) + (ry * yw) + (rz * zw)) / yw
        gw = ((gx * xw) + (gy * yw) + (gz * zw)) / yw
        bw = ((bx * xw) + (by * yw) + (bz * zw)) / yw

        //  xyz -> rgb matrix, correctly scaled to white
        self.rx = rx / rw
        self.ry = ry / rw
        self.rz = rz / rw
        self.gx = gx / gw
        self.gy = gy / gw
        self.gz = gz / gw
        self.bx = bx / bw
        self.by = by / bw
        self.bz = bz / bw

        //  invert matrix again to get proper rgb -> xyz matrix
        let s: Float = 1 / (self.rx * (self.gy * self.bz - self.by * self.gz) - self.ry * (self.gx * self.bz - self.bx * self.gz) + self.rz * (self.gx * self.by - self.bx * self.gy))

        self.xr = s * (self.gy * self.bz - self.gz * self.by)
        self.xg = s * (self.rz * self.by - self.ry * self.bz)
        self.xb = s * (self.ry * self.gz - self.rz * self.gy)
        self.yr = s * (self.gz * self.bx - self.gx * self.bz)
        self.yg = s * (self.rx * self.bz - self.rz * self.bx)
        self.yb = s * (self.rz * self.gx - self.rx * self.gz)
        self.zr = s * (self.gx * self.by - self.gy * self.bx)
        self.zg = s * (self.ry * self.bx - self.rx * self.by)
        self.zb = s * (self.rx * self.gy - self.ry * self.gx)
    }

    func convertXYZtoRGB(_ c: XYZColor) -> Color {
        return convertXYZtoRGB(c.getX(), c.getY(), c.getZ())
    }

    func convertXYZtoRGB(_ X: Float, _ Y: Float, _ Z: Float) -> Color {
        let r: Float = (rx * X) + (ry * Y) + (rz * Z)
        let g: Float = (gx * X) + (gy * Y) + (gz * Z)
        let b: Float = (bx * X) + (by * Y) + (bz * Z)

        return Color(r, g, b)
    }

    func convertRGBtoXYZ(_ c: Color) -> XYZColor {
        let rgb: [Float] = c.getRGB()

        let X: Float = (xr * rgb[0]) + (xg * rgb[1]) + (xb * rgb[2])
        let Y: Float = (yr * rgb[0]) + (yg * rgb[1]) + (yb * rgb[2])
        let Z: Float = (zr * rgb[0]) + (zg * rgb[1]) + (zb * rgb[2])

        return XYZColor(X, Y, Z)
    }

    func insideGamut(_ r: Float, _ g: Float, _ b: Float) -> Bool {
        return (r >= 0) && (g >= 0) && (b >= 0)
    }

    func gammaCorrect(_ v: Float) -> Float {
        if v <= 0 {
            return 0
        } else if v >= 1 {
            return 1
        } else if v <= breakPoint {
            return slope * v
        } else {
            return slopeMatch * pow(v, 1 / gamma) - segmentOffset
        }
    }

    func ungammaCorrect(_ vp: Float) -> Float {
        if vp <= 0 {
            return 0
        } else if vp >= 1 {
            return 1
        } else if vp <= breakPoint * slope {
            return vp / slope
        } else {
            return pow((vp + segmentOffset) / slopeMatch, gamma)
        }
    }

    func rgbToNonLinear(_ rgb: Int32) -> Int32 {
        //  gamma correct 24bit rgb value via tables
        let rp: Int32 = GAMMA_CURVE[(Int(rgb) >> 16) & 0xFF]
        let gp: Int32 = GAMMA_CURVE[(Int(rgb) >> 8) & 0xFF]
        let bp: Int32 = GAMMA_CURVE[Int(rgb) & 0xFF]

        return (rp << 16) | (gp << 8) | bp
    }

    func rgbToLinear(_ rgb: Int32) -> Int32 {
        //  convert a packed RGB triplet to a linearized
        //  one by applying the proper LUT
        let rp: Int32 = INV_GAMMA_CURVE[(Int(rgb) >> 16) & 0xFF]
        let gp: Int32 = INV_GAMMA_CURVE[(Int(rgb) >> 8) & 0xFF]
        let bp: Int32 = INV_GAMMA_CURVE[Int(rgb) & 0xFF]

        return (rp << 16) | (gp << 8) | bp
    }

    func rgbToNonLinear(_ r: UInt8) -> UInt8 {
        return UInt8(GAMMA_CURVE[Int(r) & 0xFF])
    }

    func rgbToLinear(_ r: UInt8) -> UInt8 {
        return UInt8(INV_GAMMA_CURVE[Int(r) & 0xFF])
    }

    func toString() -> String {
        var info: String = "Gamma function parameters:\n"
        info = info + "  * Gamma:          \(gamma)\n"
        info = info + "  * Breakpoint:     \(breakPoint)\n"
        info = info + "  * Slope:          \(slope)\n"
        info = info + "  * Slope Match:    \(slopeMatch)\n"
        info = info + "  * Segment Offset: \(segmentOffset)\n"
        info = info + "XYZ -> RGB Matrix:\n"
        info = info + "| \(rx) \(ry) \(rz)|\n"
        info = info + "| \(gx) \(gy) \(gz)|\n"
        info = info + "| \(bx) \(by) \(bz)|\n"
        info = info + "RGB -> XYZ Matrix:\n"
        info = info + "| \(xr) \(xg) \(xb)|\n"
        info = info + "| \(yr) \(yg) \(yb)|\n"
        info = info + "| \(zr) \(zg) \(zb)|\n"

        return info
    }
}
