//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class InstanceList: PrimitiveList {
    var instances: [Instance]
    var lights: [Instance]

    required init() {
        instances = [Instance]()
        lights = [Instance]()

        clearLightSources()
    }

    init(_ instances: [Instance]) {
        self.instances = instances
        lights = [Instance]()

        clearLightSources()
    }

    func addLightSourceInstances(_ lights: [Instance]) {
        self.lights = lights
    }

    func clearLightSources() {
        lights = [Instance]()
    }

    func getPrimitiveBound(_ primID: Int32, _ i: Int32) -> Float {
        if primID < instances.count {
            return instances[Int(primID)].getBounds()!.getBound(i)
        } else {
            return lights[Int(primID) - instances.count].getBounds()!.getBound(i)
        }
    }

    func getWorldBounds(_: AffineTransform?) -> BoundingBox? {
        let bounds: BoundingBox = BoundingBox()

        for i in instances {
            bounds.include(i.getBounds()!)
        }

        for i in lights {
            bounds.include(i.getBounds()!)
        }

        return bounds
    }

    func intersectPrimitive(_ r: Ray, _ primID: Int32, _ state: IntersectionState) {
        if primID < instances.count {
            instances[Int(primID)].intersect(r, state)
        } else {
            lights[Int(primID) - instances.count].intersect(r, state)
        }
    }

    func getNumPrimitives() -> Int32 {
        return Int32(instances.count + lights.count)
    }

    func getNumPrimitives(_ primID: Int32) -> Int32 {
        return (primID < instances.count ? instances[Int(primID)].getNumPrimitives() : lights[Int(primID) - instances.count].getNumPrimitives())
    }

    func prepareShadingState(_ state: ShadingState) {
        state.getInstance()!.prepareShadingState(state)
    }

    func update(_: ParameterList) -> Bool {
        return true
    }

    func getBakingPrimitives() -> PrimitiveList? {
        return nil
    }
}
