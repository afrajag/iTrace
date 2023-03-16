//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//
import Foundation

final class PerlinScalar {
    static var G1: [Float] = [-1, 1]
    static var G2: [[Float]] = [[1, 0], [-1, 0], [0, 1], [0, -1]]
    static var G3: [[Float]] = [[1, 1, 0], [-1, 1, 0], [1, -1, 0], [-1, -1, 0], [1, 0, 1], [-1, 0, 1], [1, 0, -1], [-1, 0, -1], [0, 1, 1], [0, -1, 1], [0, 1, -1], [0, -1, -1], [1, 1, 0], [-1, 1, 0], [0, -1, 1], [0, -1, -1]]
    static var G4: [[Float]] = [[-1, -1, -1, 0], [-1, -1, 1, 0], [-1, 1, -1, 0], [-1, 1, 1, 0], [1, -1, -1, 0], [1, -1, 1, 0], [1, 1, -1, 0], [1, 1, 1, 0], [-1, -1, 0, -1], [-1, 1, 0, -1], [1, -1, 0, -1], [1, 1, 0, -1], [-1, -1, 0, 1], [-1, 1, 0, 1], [1, -1, 0, 1], [1, 1, 0, 1], [-1, 0, -1, -1], [1, 0, -1, -1], [-1, 0, -1, 1], [1, 0, -1, 1], [-1, 0, 1, -1], [1, 0, 1, -1], [-1, 0, 1, 1], [1, 0, 1, 1], [0, -1, -1, -1], [0, -1, -1, 1], [0, -1, 1, -1], [0, -1, 1, 1], [0, 1, -1, -1], [0, 1, -1, 1], [0, 1, 1, -1], [0, 1, 1, 1]]
    static var p: [Int32] = [151, 160, 137, 91, 90, 15, 131, 13, 201, 95, 96, 53, 194, 233, 7, 225, 140, 36, 103, 30, 69, 142, 8, 99, 37, 240, 21, 10, 23, 190, 6, 148, 247, 120, 234, 75, 0, 26, 197, 62, 94, 252, 219, 203, 117, 35, 11, 32, 57, 177, 33, 88, 237, 149, 56, 87, 174, 20, 125, 136, 171, 168, 68, 175, 74, 165, 71, 134, 139, 48, 27, 166, 77, 146, 158, 231, 83, 111, 229, 122, 60, 211, 133, 230, 220, 105, 92, 41, 55, 46, 245, 40, 244, 102, 143, 54, 65, 25, 63, 161, 1, 216, 80, 73, 209, 76, 132, 187, 208, 89, 18, 169, 200, 196, 135, 130, 116, 188, 159, 86, 164, 100, 109, 198, 173, 186, 3, 64, 52, 217, 226, 250, 124, 123, 5, 202, 38, 147, 118, 126, 255, 82, 85, 212, 207, 206, 59, 227, 47, 16, 58, 17, 182, 189, 28, 42, 223, 183, 170, 213, 119, 248, 152, 2, 44, 154, 163, 70, 221, 153, 101, 155, 167, 43, 172, 9, 129, 22, 39, 253, 19, 98, 108, 110, 79, 113, 224, 232, 178, 185, 112, 104, 218, 246, 97, 228, 251, 34, 242, 193, 238, 210, 144, 12, 191, 179, 162, 241, 81, 51, 145, 235, 249, 14, 239, 107, 49, 192, 214, 31, 181, 199, 106, 157, 184, 84, 204, 176, 115, 121, 50, 45, 127, 4, 150, 254, 138, 236, 205, 93, 222, 114, 67, 29, 24, 72, 243, 141, 128, 195, 78, 66, 215, 61, 156, 180, 151, 160, 137, 91, 90, 15, 131, 13, 201, 95, 96, 53, 194, 233, 7, 225, 140, 36, 103, 30, 69, 142, 8, 99, 37, 240, 21, 10, 23, 190, 6, 148, 247, 120, 234, 75, 0, 26, 197, 62, 94, 252, 219, 203, 117, 35, 11, 32, 57, 177, 33, 88, 237, 149, 56, 87, 174, 20, 125, 136, 171, 168, 68, 175, 74, 165, 71, 134, 139, 48, 27, 166, 77, 146, 158, 231, 83, 111, 229, 122, 60, 211, 133, 230, 220, 105, 92, 41, 55, 46, 245, 40, 244, 102, 143, 54, 65, 25, 63, 161, 1, 216, 80, 73, 209, 76, 132, 187, 208, 89, 18, 169, 200, 196, 135, 130, 116, 188, 159, 86, 164, 100, 109, 198, 173, 186, 3, 64, 52, 217, 226, 250, 124, 123, 5, 202, 38, 147, 118, 126, 255, 82, 85, 212, 207, 206, 59, 227, 47, 16, 58, 17, 182, 189, 28, 42, 223, 183, 170, 213, 119, 248, 152, 2, 44, 154, 163, 70, 221, 153, 101, 155, 167, 43, 172, 9, 129, 22, 39, 253, 19, 98, 108, 110, 79, 113, 224, 232, 178, 185, 112, 104, 218, 246, 97, 228, 251, 34, 242, 193, 238, 210, 144, 12, 191, 179, 162, 241, 81, 51, 145, 235, 249, 14, 239, 107, 49, 192, 214, 31, 181, 199, 106, 157, 184, 84, 204, 176, 115, 121, 50, 45, 127, 4, 150, 254, 138, 236, 205, 93, 222, 114, 67, 29, 24, 72, 243, 141, 128, 195, 78, 66, 215, 61, 156, 180]

    static func snoise(_ x: Float) -> Float {
        let xf: Int32 = Int32(floor(x))
        let X: Int32 = xf & 255

        let _x = x - Float(xf)

        let u: Float = fade(_x)

        let A: Int32 = p[Int(X)]
        let B: Int32 = p[Int(X) + 1]

        return lerp(u, grad(p[Int(A)], _x), grad(p[Int(B)], _x - 1))
    }

    static func snoise(_ x: Float, _ y: Float) -> Float {
        let xf: Int32 = Int32(floor(x))
        let yf: Int32 = Int32(floor(y))
        let X: Int32 = xf & 255
        let Y: Int32 = yf & 255

        let _x = x - Float(xf)

        let _y = y - Float(yf)

        let u: Float = fade(_x)
        let v: Float = fade(_y)
        let A: Int32 = p[Int(X)] + Y
        let B: Int32 = p[Int(X) + 1] + Y

        return lerp(v, lerp(u, grad(p[Int(A)], _x, _y), grad(p[Int(B)], _x - 1, _y)), lerp(u, grad(p[Int(A) + 1], _x, _y - 1), grad(p[Int(B) + 1], _x - 1, _y - 1)))
    }

    static func snoise(_ x: Float, _ y: Float, _ z: Float) -> Float {
        let xf: Int32 = Int32(floor(x))
        let yf: Int32 = Int32(floor(y))
        let zf: Int32 = Int32(floor(z))
        let X: Int32 = xf & 255
        let Y: Int32 = yf & 255
        let Z: Int32 = zf & 255

        let _x = x - Float(xf)
        let _y = y - Float(yf)
        let _z = z - Float(zf)

        let u: Float = fade(_x)
        let v: Float = fade(_y)
        let w: Float = fade(_z)
        let A: Int32 = p[Int(X)] + Y
        let AA: Int32 = p[Int(A)] + Z
        let AB: Int32 = p[Int(A) + 1] + Z
        let B: Int32 = p[Int(X) + 1] + Y
        let BA: Int32 = p[Int(B)] + Z
        let BB: Int32 = p[Int(B) + 1] + Z

        return lerp(w, lerp(v, lerp(u, grad(p[Int(AA)], _x, _y, z), grad(p[Int(BA)], _x - 1, _y, z)), lerp(u, grad(p[Int(AB)], _x, _y - 1, z), grad(p[Int(BB)], _x - 1, _y - 1, z))), lerp(v, lerp(u, grad(p[Int(AA) + 1], _x, _y, z - 1), grad(p[Int(BA) + 1], _x - 1, _y, z - 1)), lerp(u, grad(p[Int(AB) + 1], _x, _y - 1, z - 1), grad(p[Int(BB) + 1], _x - 1, _y - 1, z - 1))))
    }

    static func snoise(_ x: Float, _ y: Float, _ z: Float, _ w: Float) -> Float {
        let xf: Int32 = Int32(floor(x))
        let yf: Int32 = Int32(floor(y))
        let zf: Int32 = Int32(floor(z))
        let wf: Int32 = Int32(floor(w))
        let X: Int32 = xf & 255
        let Y: Int32 = yf & 255
        let Z: Int32 = zf & 255
        let W: Int32 = wf & 255

        let _x = x - Float(xf)
        let _y = x - Float(yf)
        let _z = x - Float(zf)
        let _w = x - Float(wf)

        let u: Float = fade(_x)
        let v: Float = fade(_y)
        let t: Float = fade(_z)
        let s: Float = fade(_w)
        let A: Int32 = p[Int(X)] + Y
        let AA: Int32 = p[Int(A)] + Z
        let AB: Int32 = p[Int(A) + 1] + Z
        let B: Int32 = p[Int(X) + 1] + Y
        let BA: Int32 = p[Int(B)] + Z
        let BB: Int32 = p[Int(B) + 1] + Z
        let AAA: Int32 = p[Int(AA)] + W
        let AAB: Int32 = p[Int(AA) + 1] + W
        let ABA: Int32 = p[Int(AB)] + W
        let ABB: Int32 = p[Int(AB) + 1] + W
        let BAA: Int32 = p[Int(BA)] + W
        let BAB: Int32 = p[Int(BA) + 1] + W
        let BBA: Int32 = p[Int(BB)] + W
        let BBB: Int32 = p[Int(BB) + 1] + W

        return lerp(s, lerp(t, lerp(v, lerp(u, grad(p[Int(AAA)], _x, _y, z, w), grad(p[Int(BAA)], _x - 1, _y, z, w)), lerp(u, grad(p[Int(ABA)], _x, _y - 1, z, w), grad(p[Int(BBA)], _x - 1, _y - 1, z, w))), lerp(v, lerp(u, grad(p[Int(AAB)], _x, _y, z - 1, w), grad(p[Int(BAB)], _x - 1, _y, z - 1, w)), lerp(u, grad(p[Int(ABB)], _x, _y - 1, z - 1, w), grad(p[Int(BBB)], _x - 1, _y - 1, z - 1, w)))), lerp(t, lerp(v, lerp(u, grad(p[Int(AAA) + 1], _x, _y, z, w - 1), grad(p[Int(BAA) + 1], _x - 1, _y, z, w - 1)), lerp(u, grad(p[Int(ABA) + 1], _x, _y - 1, z, w - 1), grad(p[Int(BBA) + 1], _x - 1, _y - 1, z, w - 1))), lerp(v, lerp(u, grad(p[Int(AAB) + 1], _x, _y, z - 1, w - 1), grad(p[Int(BAB) + 1], _x - 1, _y, z - 1, w - 1)), lerp(u, grad(p[Int(ABB) + 1], _x, _y - 1, z - 1, w - 1), grad(p[Int(BBB) + 1], _x - 1, _y - 1, z - 1, w - 1)))))
    }

    static func snoise(_ p: Point2) -> Float {
        return snoise(p.x, p.y)
    }

    static func snoise(_ p: Point3) -> Float {
        return snoise(p.x, p.y, p.z)
    }

    static func snoise(_ p: Point3, _ t: Float) -> Float {
        return snoise(p.x, p.y, p.z, t)
    }

    static func noise(_ x: Float) -> Float {
        return 0.5 + (0.5 * snoise(x))
    }

    static func noise(_ x: Float, _ y: Float) -> Float {
        return 0.5 + (0.5 * snoise(x, y))
    }

    static func noise(_ x: Float, _ y: Float, _ z: Float) -> Float {
        return 0.5 + (0.5 * snoise(x, y, z))
    }

    static func noise(_ x: Float, _ y: Float, _ z: Float, _ t: Float) -> Float {
        return 0.5 + (0.5 * snoise(x, y, z, t))
    }

    static func noise(_ p: Point2) -> Float {
        return 0.5 + (0.5 * snoise(p.x, p.y))
    }

    static func noise(_ p: Point3) -> Float {
        return 0.5 + (0.5 * snoise(p.x, p.y, p.z))
    }

    static func noise(_ p: Point3, _ t: Float) -> Float {
        return 0.5 + (0.5 * snoise(p.x, p.y, p.z, t))
    }

    static func pnoise(_ xi: Float, _ period: Float) -> Float {
        let x: Float = xi.truncatingRemainder(dividingBy: period) + (xi < 0 ? period : 0)

        return (((period - x) * noise(x)) + (x * noise(x - period))) / period
    }

    static func pnoise(_ xi: Float, _ yi: Float, _ w: Float, _ h: Float) -> Float {
        let x: Float = xi.truncatingRemainder(dividingBy: w) + (xi < 0 ? w : 0)
        let y: Float = yi.truncatingRemainder(dividingBy: h) + (yi < 0 ? h : 0)
        let w_x: Float = w - x
        let h_y: Float = h - y
        let x_w: Float = x - w
        let y_h: Float = y - h

        return ((noise(x, y) * w_x * h_y) + (noise(x_w, y) * x * h_y) + (noise(x_w, y_h) * x * y) + (noise(x, y_h) * w_x * y)) / (w * h)
    }

    static func pnoise(_ xi: Float, _ yi: Float, _ zi: Float, _ w: Float, _ h: Float, _ d: Float) -> Float {
        let x: Float = xi.truncatingRemainder(dividingBy: w) + (xi < 0 ? w : 0)
        let y: Float = yi.truncatingRemainder(dividingBy: h) + (yi < 0 ? h : 0)
        let z: Float = zi.truncatingRemainder(dividingBy: d) + (zi < 0 ? d : 0)
        let w_x: Float = w - x
        let h_y: Float = h - y
        let d_z: Float = d - z
        let x_w: Float = x - w
        let y_h: Float = y - h
        let z_d: Float = z - d
        let xy: Float = x * y
        let h_yXd_z: Float = h_y * d_z
        let h_yXz: Float = h_y * z
        let w_xXy: Float = w_x * y

        return ((noise(x, y, z) * w_x * h_yXd_z) + (noise(x, y_h, z) * w_xXy * d_z) + (noise(x_w, y, z) * x * h_yXd_z) + (noise(x_w, y_h, z) * xy * d_z) + (noise(x_w, y_h, z_d) * xy * z) + (noise(x, y, z_d) * w_x * h_yXz) + (noise(x, y_h, z_d) * w_xXy * z) + (noise(x_w, y, z_d) * x * h_yXz)) / (w * h * d)
    }

    static func pnoise(_ xi: Float, _ yi: Float, _ zi: Float, _ ti: Float, _ w: Float, _ h: Float, _ d: Float, _ p: Float) -> Float {
        let x: Float = xi.truncatingRemainder(dividingBy: w) + (xi < 0 ? w : 0)
        let y: Float = yi.truncatingRemainder(dividingBy: h) + (yi < 0 ? h : 0)
        let z: Float = zi.truncatingRemainder(dividingBy: d) + (zi < 0 ? d : 0)
        let t: Float = ti.truncatingRemainder(dividingBy: p) + (ti < 0 ? p : 0)
        let w_x: Float = w - x
        let h_y: Float = h - y
        let d_z: Float = d - z
        let p_t: Float = p - t
        let x_w: Float = x - w
        let y_h: Float = y - h
        let z_d: Float = z - d
        let t_p: Float = t - p
        let xy: Float = x * y
        let d_zXp_t: Float = d_z * p_t
        let zXp_t: Float = z * p_t
        let zXt: Float = z * t
        let d_zXt: Float = d_z * t
        let w_xXy: Float = w_x * y
        let w_xXh_y: Float = w_x * h_y
        let xXh_y: Float = x * h_y

        return ((noise(x, y, z, t) * w_xXh_y * d_zXp_t) + (noise(x_w, y, z, t) * xXh_y * d_zXp_t) + (noise(x_w, y_h, z, t) * xy * d_zXp_t) + (noise(x, y_h, z, t) * w_xXy * d_zXp_t) + (noise(x_w, y_h, z_d, t) * xy * zXp_t) + (noise(x, y, z_d, t) * w_xXh_y * zXp_t) + (noise(x, y_h, z_d, t) * w_xXy * zXp_t) + (noise(x_w, y, z_d, t) * xXh_y * zXp_t) + (noise(x, y, z, t_p) * w_xXh_y * d_zXt) + (noise(x_w, y, z, t_p) * xXh_y * d_zXt) + (noise(x_w, y_h, z, t_p) * xy * d_zXt) + (noise(x, y_h, z, t_p) * w_xXy * d_zXt) + (noise(x_w, y_h, z_d, t_p) * xy * zXt) + (noise(x, y, z_d, t_p) * w_xXh_y * zXt) + (noise(x, y_h, z_d, t_p) * w_xXy * zXt) + (noise(x_w, y, z_d, t_p) * xXh_y * zXt)) / (w * h * d * t)
    }

    static func pnoise(_ p: Point2, _ periodx: Float, _ periody: Float) -> Float {
        return pnoise(p.x, p.y, periodx, periody)
    }

    static func pnoise(_ p: Point3, _ period: Vector3) -> Float {
        return pnoise(p.x, p.y, p.z, period.x, period.y, period.z)
    }

    static func pnoise(_ p: Point3, _ t: Float, _ pperiod: Vector3, _ tperiod: Float) -> Float {
        return pnoise(p.x, p.y, p.z, t, pperiod.x, pperiod.y, pperiod.z, tperiod)
    }

    static func spnoise(_ xi: Float, _ period: Float) -> Float {
        let x: Float = xi.truncatingRemainder(dividingBy: period) + (xi < 0 ? period : 0)

        return (((period - x) * snoise(x)) + (x * snoise(x - period))) / period
    }

    static func spnoise(_ xi: Float, _ yi: Float, _ w: Float, _ h: Float) -> Float {
        let x: Float = xi.truncatingRemainder(dividingBy: w) + (xi < 0 ? w : 0)
        let y: Float = yi.truncatingRemainder(dividingBy: h) + (yi < 0 ? h : 0)
        let w_x: Float = w - x
        let h_y: Float = h - y
        let x_w: Float = x - w
        let y_h: Float = y - h

        return ((snoise(x, y) * w_x * h_y) + (snoise(x_w, y) * x * h_y) + (snoise(x_w, y_h) * x * y) + (snoise(x, y_h) * w_x * y)) / (w * h)
    }

    static func spnoise(_ xi: Float, _ yi: Float, _ zi: Float, _ w: Float, _ h: Float, _ d: Float) -> Float {
        let x: Float = xi.truncatingRemainder(dividingBy: w) + (xi < 0 ? w : 0)
        let y: Float = yi.truncatingRemainder(dividingBy: h) + (yi < 0 ? h : 0)
        let z: Float = zi.truncatingRemainder(dividingBy: d) + (zi < 0 ? d : 0)
        let w_x: Float = w - x
        let h_y: Float = h - y
        let d_z: Float = d - z
        let x_w: Float = x - w
        let y_h: Float = y - h
        let z_d: Float = z - d
        let xy: Float = x * y
        let h_yXd_z: Float = h_y * d_z
        let h_yXz: Float = h_y * z
        let w_xXy: Float = w_x * y

        return ((snoise(x, y, z) * w_x * h_yXd_z) + (snoise(x, y_h, z) * w_xXy * d_z) + (snoise(x_w, y, z) * x * h_yXd_z) + (snoise(x_w, y_h, z) * xy * d_z) + (snoise(x_w, y_h, z_d) * xy * z) + (snoise(x, y, z_d) * w_x * h_yXz) + (snoise(x, y_h, z_d) * w_xXy * z) + (snoise(x_w, y, z_d) * x * h_yXz)) / (w * h * d)
    }

    static func spnoise(_ xi: Float, _ yi: Float, _ zi: Float, _ ti: Float, _ w: Float, _ h: Float, _ d: Float, _ p: Float) -> Float {
        let x: Float = xi.truncatingRemainder(dividingBy: w) + (xi < 0 ? w : 0)
        let y: Float = yi.truncatingRemainder(dividingBy: h) + (yi < 0 ? h : 0)
        let z: Float = zi.truncatingRemainder(dividingBy: d) + (zi < 0 ? d : 0)
        let t: Float = ti.truncatingRemainder(dividingBy: p) + (ti < 0 ? p : 0)
        let w_x: Float = w - x
        let h_y: Float = h - y
        let d_z: Float = d - z
        let p_t: Float = p - t
        let x_w: Float = x - w
        let y_h: Float = y - h
        let z_d: Float = z - d
        let t_p: Float = t - p
        let xy: Float = x * y
        let d_zXp_t: Float = d_z * p_t
        let zXp_t: Float = z * p_t
        let zXt: Float = z * t
        let d_zXt: Float = d_z * t
        let w_xXy: Float = w_x * y
        let w_xXh_y: Float = w_x * h_y
        let xXh_y: Float = x * h_y

        return ((snoise(x, y, z, t) * w_xXh_y * d_zXp_t) + (snoise(x_w, y, z, t) * xXh_y * d_zXp_t) + (snoise(x_w, y_h, z, t) * xy * d_zXp_t) + (snoise(x, y_h, z, t) * w_xXy * d_zXp_t) + (snoise(x_w, y_h, z_d, t) * xy * zXp_t) + (snoise(x, y, z_d, t) * w_xXh_y * zXp_t) + (snoise(x, y_h, z_d, t) * w_xXy * zXp_t) + (snoise(x_w, y, z_d, t) * xXh_y * zXp_t) + (snoise(x, y, z, t_p) * w_xXh_y * d_zXt) + (snoise(x_w, y, z, t_p) * xXh_y * d_zXt) + (snoise(x_w, y_h, z, t_p) * xy * d_zXt) + (snoise(x, y_h, z, t_p) * w_xXy * d_zXt) + (snoise(x_w, y_h, z_d, t_p) * xy * zXt) + (snoise(x, y, z_d, t_p) * w_xXh_y * zXt) + (snoise(x, y_h, z_d, t_p) * w_xXy * zXt) + (snoise(x_w, y, z_d, t_p) * xXh_y * zXt)) / (w * h * d * t)
    }

    static func spnoise(_ p: Point2, _ periodx: Float, _ periody: Float) -> Float {
        return spnoise(p.x, p.y, periodx, periody)
    }

    static func spnoise(_ p: Point3, _ period: Vector3) -> Float {
        return spnoise(p.x, p.y, p.z, period.x, period.y, period.z)
    }

    static func spnoise(_ p: Point3, _ t: Float, _ pperiod: Vector3, _ tperiod: Float) -> Float {
        return spnoise(p.x, p.y, p.z, t, pperiod.x, pperiod.y, pperiod.z, tperiod)
    }

    static func fade(_ t: Float) -> Float {
        return t * t * t * (t * (t * 6 - 15) + 10)
    }

    static func lerp(_ t: Float, _ a: Float, _ b: Float) -> Float {
        return a + t * (b - a)
    }

    static func grad(_ hash: Int32, _ x: Float) -> Float {
        let h: Int32 = hash & 0x1

        return x * G1[Int(h)]
    }

    static func grad(_ hash: Int32, _ x: Float, _ y: Float) -> Float {
        let h: Int32 = hash & 0x3

        return x * G2[Int(h)][0] + y * G2[Int(h)][1]
    }

    static func grad(_ hash: Int32, _ x: Float, _ y: Float, _ z: Float) -> Float {
        let h: Int32 = hash & 15

        return x * G3[Int(h)][0] + y * G3[Int(h)][1] + z * G3[Int(h)][2]
    }

    static func grad(_ hash: Int32, _ x: Float, _ y: Float, _ z: Float, _ w: Float) -> Float {
        let h: Int32 = hash & 31

        return x * G4[Int(h)][0] + y * G4[Int(h)][1] + z * G4[Int(h)][2] + w * G4[Int(h)][3]
    }
}
