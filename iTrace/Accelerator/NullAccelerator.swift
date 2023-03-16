//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class NullAccelerator: AccelerationStructure {
    var primitives: PrimitiveList?
    var n: Int32 = 0

    required init() {
        primitives = nil
        
        n = 0
    }

    func build(_ primitives: PrimitiveList) {
        self.primitives = primitives
        
        n = primitives.getNumPrimitives()
    }

    func intersect(_ r: Ray, _ state: IntersectionState) {
        for i in 0 ..< n {
            primitives!.intersectPrimitive(r, i, state)
        }
    }
}
