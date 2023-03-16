//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//
import Foundation

final class PerlinModifier: Modifier {
    var function: Int32 = 0
    var scale: Float = 50
    var size: Float = 1

    required init() {}

    func update(_ pl: ParameterList) -> Bool {
        function = pl.getInt("function", function)!

        size = pl.getFloat("size", size)!

        scale = pl.getFloat("scale", scale)!

        return true
    }

    func modify(_ state: ShadingState) {
        let p: Point3 = state.transformWorldToObject(state.getPoint())
        p.x = p.x * size
        p.y = p.y * size
        p.z = p.z * size

        let normal: Vector3? = state.transformNormalWorldToObject(state.getNormal()!)

        let f0: Double = f(Double(p.x), Double(p.y), Double(p.z))
        let fx: Double = f(Double(p.x + 0.0001), Double(p.y), Double(p.z))
        let fy: Double = f(Double(p.x), Double(p.y + 0.0001), Double(p.z))
        let fz: Double = f(Double(p.x), Double(p.y), Double(p.z + 0.0001))

        normal!.x -= scale * Float(fx - f0) / 0.0001
        normal!.y -= scale * Float(fy - f0) / 0.0001
        normal!.z -= scale * Float(fz - f0) / 0.0001

        normal!.normalize()

        state.getNormal()!.set(state.transformNormalObjectToWorld(normal!))

        state.getNormal()!.normalize()

        state.setBasis(OrthoNormalBasis.makeFromW(state.getNormal()!))
    }

    func f(_ x: Double, _ y: Double, _ z: Double) -> Double {
        switch function {
        case 0:
            return 0.03 * Self.noise(x, y, z, 8)
        case 1:
            return 0.01 * Self.stripes(x + 2 * Self.turbulence(x, y, z, 1), 1.6)
        default:
            return -0.1 * Self.turbulence(x, y, z, 1)
        }
    }

    static func stripes(_ x: Double, _ f: Double) -> Double {
        let t: Double = 0.5 + 0.5 * sin(f * 2 * Double.pi * x)

        return t * t - 0.5
    }

    static func turbulence(_ x: Double, _ y: Double, _ z: Double, _ freq: Double) -> Double {
        var t: Double = -0.5

        var _freq = freq

        while _freq <= (300 / 12) {
            t += abs(noise(x, y, z, freq) / freq)

            _freq *= 2
        }

        return t
    }

    static func noise(_ x: Double, _ y: Double, _ z: Double, _ freq: Double) -> Double {
        var x1: Double
        var y1: Double
        var z1: Double

        x1 = 0.707 * x - 0.707 * z
        z1 = 0.707 * x + 0.707 * z
        y1 = 0.707 * x1 + 0.707 * y
        x1 = 0.707 * x1 - 0.707 * y

        return Double(PerlinScalar.snoise(Float(freq * x1 + 100), Float(freq * y1), Float(freq * z1)))
    }
}
