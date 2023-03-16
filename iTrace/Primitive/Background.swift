//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class Background: PrimitiveList {
    required init() {}

    func update(_: ParameterList) -> Bool {
        return true
    }

    func prepareShadingState(_ state: ShadingState) {
        if state.getDepth() == 0 {
            state.setShader(state.getInstance()!.getShader(0))
        }
    }

    func getNumPrimitives() -> Int32 {
        return 1
    }

    func getPrimitiveBound(_: Int32, _: Int32) -> Float {
        return 0
    }

    func getWorldBounds(_: AffineTransform?) -> BoundingBox? {
        return nil
    }

    func intersectPrimitive(_ r: Ray, _: Int32, _ state: IntersectionState) {
        if r.getMax() == Float.infinity {
            state.setIntersection(0)
        }
    }

    func getBakingPrimitives() -> PrimitiveList? {
        return nil
    }
}
