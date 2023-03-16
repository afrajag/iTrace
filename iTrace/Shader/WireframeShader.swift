//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//
import Foundation

class WireframeShader: Shader {
    var lineColor: Color
    var fillColor: Color
    var width: Float = 0.0
    var cosWidth: Float = 0.0

    required init() {
        lineColor = Color.BLACK
        fillColor = Color.WHITE

        //  pick a very small angle - should be roughly the half the angular width of a
        //  pixel
        width = Float.pi * 0.5 / 4096

        cosWidth = cos(width)
    }

    func update(_ pl: ParameterList) -> Bool {
        lineColor = pl.getColor("line", lineColor)!
        
        fillColor = pl.getColor("fill", fillColor)!
        
        width = pl.getFloat("width", width)!

        cosWidth = cos(width)

        return true
    }

    func getFillColor(_: ShadingState) -> Color {
        return fillColor
    }

    func getLineColor(_: ShadingState) -> Color {
        return lineColor
    }

    func getRadiance(_ state: ShadingState) -> Color {
        // var p: [Point3] = Point3[](repeating: 0, count: 3)
        // FIXME: controllare (cambiata firma metodo)
        var p: [Point3]? = state.getTrianglePoints()

        if p == nil {
            return getFillColor(state)
        }

        //  transform points into camera space
        var center: Point3 = state.getPoint()
        let w2c: AffineTransform = state.getWorldToCamera()

        center = w2c.transformP(center)

        for i in 0 ..< 3 {
            p![i] = w2c.transformP(state.transformObjectToWorld(p![i]))
        }

        let cn: Float = 1.0 / sqrt(center.x * center.x + center.y * center.y + center.z * center.z)
        
        var i2: Int32 = 2

        for i in 0 ..< 3 {
            //  compute orthogonal projection of the shading point onto each
            //  triangle edge as in:
            //  http://mathworld.wolfram.com/Point-LineDistance3-Dimensional.html
            var t: Float = (center.x - p![Int(i)].x) * (p![Int(i2)].x - p![Int(i)].x)

            t += (center.y - p![Int(i)].y) * (p![Int(i2)].y - p![Int(i)].y)
            t += (center.z - p![Int(i)].z) * (p![Int(i2)].z - p![Int(i)].z)

            t /= p![Int(i)].distanceToSquared(p![Int(i2)])

            let projx: Float = (1 - t) * p![Int(i)].x + t * p![Int(i2)].x
            let projy: Float = (1 - t) * p![Int(i)].y + t * p![Int(i2)].y
            let projz: Float = (1 - t) * p![Int(i)].z + t * p![Int(i2)].z
            let n: Float = 1.0 / sqrt(projx * projx + projy * projy + projz * projz)

            //  check angular width
            let dot: Float = projx * center.x + projy * center.y + projz * center.z

            if (dot * n * cn) >= cosWidth {
                return getLineColor(state)
            }

            i2 = Int32(i)
        }

        return getFillColor(state)
    }

    func scatterPhoton(_: ShadingState, _: Color) {}
}
