//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//
import Foundation

final class PointLight: LightSource {
    var lightPoint: Point3
    var power: Color

    required init() {
        lightPoint = Point3(0, 0, 0)

        power = Color.WHITE
    }

    func update(_ pl: ParameterList) -> Bool {
        lightPoint = pl.getPoint(PointLightParameter.PARAM_CENTER, lightPoint)!

        power = pl.getColor(PointLightParameter.PARAM_POWER, power)!

        return true
    }

    func getNumSamples() -> Int32 {
        return 1
    }

    func getSamples(_ state: ShadingState) {
        let d: Vector3 = Point3.sub(lightPoint, state.getPoint())

        if Vector3.dot(d, state.getNormal()!) > 0, Vector3.dot(d, state.getGeoNormal()!) > 0 {
            let dest: LightSample = LightSample()

            //  prepare shadow ray
            dest.setShadowRay(Ray(state.getPoint(), lightPoint))

            let scale: Float = 1.0 / Float(4 * Float.pi * lightPoint.distanceToSquared(state.getPoint()))

            dest.setRadiance(power, power)
            dest.getDiffuseRadiance().mul(scale)
            dest.getSpecularRadiance().mul(scale)
            dest.traceShadow(state)

            state.addSample(dest)
        }
    }

    func getPhoton(_ randX1: Double, _ randY1: Double, _: Double, _: Double, _ p: Point3, _ dir: Vector3, _ power: Color) {
        p.set(lightPoint)

        let phi: Float = 2 * Float.pi * Float(randX1)
        let s: Float = Float(sqrt(randY1 * (1.0 - randY1)))

        dir.x = cos(phi) * s
        dir.y = sin(phi) * s
        dir.z = Float(1 - (2 * randY1))

        power.set(self.power)
    }

    func getPower() -> Float {
        return power.getLuminance()
    }

    func createInstance() -> Instance? {
        return nil
    }
}
