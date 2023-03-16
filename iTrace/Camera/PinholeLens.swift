//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//
import Foundation

final class PinholeLens: CameraLens {
    var au: Float = 0.0
    var av: Float = 0.0
    var aspect: Float = 0.0
    var fov: Float = 0.0
    var shiftX: Float = 0.0
    var shiftY: Float = 0.0

    required init() {
        fov = 90
        aspect = 1
        shiftX = 0
        shiftY = 0

        update()
    }

    func update(_ pl: ParameterList) -> Bool {
        //  get parameters
        fov = pl.getFloat("fov", fov)!
        aspect = pl.getFloat("aspect", aspect)!
        shiftX = pl.getFloat("shift.x", shiftX)!
        shiftY = pl.getFloat("shift.y", shiftY)!

        update()

        return true
    }

    func update() {
        au = Float(tan(MathUtils.toRadians(Double(fov) * 0.5)))

        av = au / aspect
    }

    func getRay(_ x: Float, _ y: Float, _ imageWidth: Int32, _ imageHeight: Int32, _: Double, _: Double, _: Double) -> Ray? {
        let du: Float = shiftX - au + ((2.0 * au * x) / (Float(imageWidth) - 1.0))

        let dv: Float = shiftY - av + ((2.0 * av * y) / (Float(imageHeight) - 1.0))

        return Ray(0, 0, 0, du, dv, -1)
    }
}
