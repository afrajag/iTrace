//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

protocol AccelerationStructure: Initializable {
    // Construct an acceleration structure for the specified primitive list.
    //
    // @param primitives
    func build(_ primitives: PrimitiveList)

    // Intersect the specified ray with the geometry in local space. The ray
    // will be provided in local space.
    //
    // @param r ray in local space
    // @param istate state to store the intersection into
    func intersect(_ r: Ray, _ istate: IntersectionState)
}
