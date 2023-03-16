//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//
import Foundation

final class FakeGIEngine: GIEngine {
    var up: Vector3
    var sky: Color
    var ground: Color

    required init() {
        up = Vector3(0, 1, 0).normalize()

        sky = Color.WHITE

        ground = Color.BLACK
    }

    func getIrradiance(_ state: ShadingState, _: Color) -> Color {
        let cosTheta: Float = Vector3.dot(up, state.getNormal()!)
        let sin2: Float = 1 - (cosTheta * cosTheta)
        let sine: Float = (sin2 > 0 ? sqrt(sin2) * 0.5 : 0)

        if cosTheta > 0 {
            return Color.blend(sky, ground, sine)
        } else {
            return Color.blend(ground, sky, sine)
        }
    }

    func getGlobalRadiance(_: ShadingState) -> Color {
        return Color.BLACK
    }

    func initGI(_ options: Options, _: Scene) -> Bool {
        up = options.getVector("gi.fake.up", Vector3(0, 1, 0))!.normalize()

        sky = options.getColor("gi.fake.sky", Color.WHITE)!.copy()

        ground = options.getColor("gi.fake.ground", Color.BLACK)!.copy()

        sky.mul(Float.pi)

        ground.mul(Float.pi)

        return true
    }
}
