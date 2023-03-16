//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class PerlinVector {
    static var P1x: Float = 0.34
    static var P1y: Float = 0.66
    static var P1z: Float = 0.237
    static var P2x: Float = 0.011
    static var P2y: Float = 0.845
    static var P2z: Float = 0.037
    static var P3x: Float = 0.34
    static var P3y: Float = 0.12
    static var P3z: Float = 0.9

    static func snoise(_ x: Float) -> Vector3 {
        return Vector3(PerlinScalar.snoise(x + P1x), PerlinScalar.snoise(x + P2x), PerlinScalar.snoise(x + P3x))
    }

    static func snoise(_ x: Float, _ y: Float) -> Vector3 {
        return Vector3(PerlinScalar.snoise(x + P1x, y + P1y), PerlinScalar.snoise(x + P2x, y + P2y), PerlinScalar.snoise(x + P3x, y + P3y))
    }

    static func snoise(_ x: Float, _ y: Float, _ z: Float) -> Vector3 {
        return Vector3(PerlinScalar.snoise(x + P1x, y + P1y, z + P1z), PerlinScalar.snoise(x + P2x, y + P2y, z + P2z), PerlinScalar.snoise(x + P3x, y + P3y, z + P3z))
    }

    static func snoise(_ x: Float, _ y: Float, _ z: Float, _ t: Float) -> Vector3 {
        return Vector3(PerlinScalar.snoise(x + P1x, y + P1y, z + P1z, t), PerlinScalar.snoise(x + P2x, y + P2y, z + P2z, t), PerlinScalar.snoise(x + P3x, y + P3y, z + P3z, t))
    }

    static func snoise(_ p: Point2) -> Vector3 {
        return snoise(p.x, p.y)
    }

    static func snoise(_ p: Point3) -> Vector3 {
        return snoise(p.x, p.y, p.z)
    }

    static func snoise(_ p: Point3, _ t: Float) -> Vector3 {
        return snoise(p.x, p.y, p.z, t)
    }

    static func noise(_ x: Float) -> Vector3 {
        return Vector3(PerlinScalar.noise(x + P1x), PerlinScalar.noise(x + P2x), PerlinScalar.noise(x + P3x))
    }

    static func noise(_ x: Float, _ y: Float) -> Vector3 {
        return Vector3(PerlinScalar.noise(x + P1x, y + P1y), PerlinScalar.noise(x + P2x, y + P2y), PerlinScalar.noise(x + P3x, y + P3y))
    }

    static func noise(_ x: Float, _ y: Float, _ z: Float) -> Vector3 {
        return Vector3(PerlinScalar.noise(x + P1x, y + P1y, z + P1z), PerlinScalar.noise(x + P2x, y + P2y, z + P2z), PerlinScalar.noise(x + P3x, y + P3y, z + P3z))
    }

    static func noise(_ x: Float, _ y: Float, _ z: Float, _ t: Float) -> Vector3 {
        return Vector3(PerlinScalar.noise(x + P1x, y + P1y, z + P1z, t), PerlinScalar.noise(x + P2x, y + P2y, z + P2z, t), PerlinScalar.noise(x + P3x, y + P3y, z + P3z, t))
    }

    static func noise(_ p: Point2) -> Vector3 {
        return noise(p.x, p.y)
    }

    static func noise(_ p: Point3) -> Vector3 {
        return noise(p.x, p.y, p.z)
    }

    static func noise(_ p: Point3, _ t: Float) -> Vector3 {
        return noise(p.x, p.y, p.z, t)
    }

    static func pnoise(_ x: Float, _ period: Float) -> Vector3 {
        return Vector3(PerlinScalar.pnoise(x + P1x, period), PerlinScalar.pnoise(x + P2x, period), PerlinScalar.pnoise(x + P3x, period))
    }

    static func pnoise(_ x: Float, _ y: Float, _ w: Float, _ h: Float) -> Vector3 {
        return Vector3(PerlinScalar.pnoise(x + P1x, y + P1y, w, h), PerlinScalar.pnoise(x + P2x, y + P2y, w, h), PerlinScalar.pnoise(x + P3x, y + P3y, w, h))
    }

    static func pnoise(_ x: Float, _ y: Float, _ z: Float, _ w: Float, _ h: Float, _ d: Float) -> Vector3 {
        return Vector3(PerlinScalar.pnoise(x + P1x, y + P1y, z + P1z, w, h, d), PerlinScalar.pnoise(x + P2x, y + P2y, z + P2z, w, h, d), PerlinScalar.pnoise(x + P3x, y + P3y, z + P3z, w, h, d))
    }

    static func pnoise(_ x: Float, _ y: Float, _ z: Float, _ t: Float, _ w: Float, _ h: Float, _ d: Float, _ p: Float) -> Vector3 {
        return Vector3(PerlinScalar.pnoise(x + P1x, y + P1y, z + P1z, t, w, h, d, p), PerlinScalar.pnoise(x + P2x, y + P2y, z + P2z, t, w, h, d, p), PerlinScalar.pnoise(x + P3x, y + P3y, z + P3z, t, w, h, d, p))
    }

    static func pnoise(_ p: Point2, _ periodx: Float, _ periody: Float) -> Vector3 {
        return pnoise(p.x, p.y, periodx, periody)
    }

    static func pnoise(_ p: Point3, _ period: Vector3) -> Vector3 {
        return pnoise(p.x, p.y, p.z, period.x, period.y, period.z)
    }

    static func pnoise(_ p: Point3, _ t: Float, _ pperiod: Vector3, _ tperiod: Float) -> Vector3 {
        return pnoise(p.x, p.y, p.z, t, pperiod.x, pperiod.y, pperiod.z, tperiod)
    }

    static func spnoise(_ x: Float, _ period: Float) -> Vector3 {
        return Vector3(PerlinScalar.spnoise(x + P1x, period), PerlinScalar.spnoise(x + P2x, period), PerlinScalar.spnoise(x + P3x, period))
    }

    static func spnoise(_ x: Float, _ y: Float, _ w: Float, _ h: Float) -> Vector3 {
        return Vector3(PerlinScalar.spnoise(x + P1x, y + P1y, w, h), PerlinScalar.spnoise(x + P2x, y + P2y, w, h), PerlinScalar.spnoise(x + P3x, y + P3y, w, h))
    }

    static func spnoise(_ x: Float, _ y: Float, _ z: Float, _ w: Float, _ h: Float, _ d: Float) -> Vector3 {
        return Vector3(PerlinScalar.spnoise(x + P1x, y + P1y, z + P1z, w, h, d), PerlinScalar.spnoise(x + P2x, y + P2y, z + P2z, w, h, d), PerlinScalar.spnoise(x + P3x, y + P3y, z + P3z, w, h, d))
    }

    static func spnoise(_ x: Float, _ y: Float, _ z: Float, _ t: Float, _ w: Float, _ h: Float, _ d: Float, _ p: Float) -> Vector3 {
        return Vector3(PerlinScalar.spnoise(x + P1x, y + P1y, z + P1z, t, w, h, d, p), PerlinScalar.spnoise(x + P2x, y + P2y, z + P2z, t, w, h, d, p), PerlinScalar.spnoise(x + P3x, y + P3y, z + P3z, t, w, h, d, p))
    }

    static func spnoise(_ p: Point2, _ periodx: Float, _ periody: Float) -> Vector3 {
        return spnoise(p.x, p.y, periodx, periody)
    }

    static func spnoise(_ p: Point3, _ period: Vector3) -> Vector3 {
        return spnoise(p.x, p.y, p.z, period.x, period.y, period.z)
    }

    static func spnoise(_ p: Point3, _ t: Float, _ pperiod: Vector3, _ tperiod: Float) -> Vector3 {
        return spnoise(p.x, p.y, p.z, t, pperiod.x, pperiod.y, pperiod.z, tperiod)
    }
}
