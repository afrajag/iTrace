//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//
import Foundation

final class Geometry: RenderObject {
    var tesselatable: Tesselatable?
    var primitives: PrimitiveList?
    var accel: AccelerationStructure?
    var builtAccel: Int32 = 0
    var builtTess: Int32 = 0
    var acceltype: String?

    let lockQueue = DispatchQueue(label: "geometry.lock.serial.queue")

    required init() {}

    // Create a geometry from the specified tesselatable object. The actual
    // renderable primitives will be generated on demand.
    //
    // @param tesselatable tesselation object
    init(_ tesselatable: Tesselatable) {
        self.tesselatable = tesselatable
        primitives = nil
        accel = nil

        builtAccel = 0
        builtTess = 0
        acceltype = nil
    }

    // Create a geometry from the specified primitive aggregate. The
    // acceleration structure for this object will be built on demand.
    //
    // @param primitives primitive list object
    init(_ primitives: PrimitiveList) {
        tesselatable = nil
        self.primitives = primitives
        accel = nil

        builtAccel = 0
        builtTess = 1 // already tesselated
        acceltype = nil
    }

    func update(_ pl: ParameterList) -> Bool {
        acceltype = pl.getString("accel", acceltype)

        // clear up old tesselation if it exists
        if tesselatable != nil {
            primitives = nil
            builtTess = 0
        }

        // clear acceleration structure so it will be rebuilt
        accel = nil
        builtAccel = 0

        if tesselatable != nil {
            return tesselatable!.update(pl)
        }

        // update primitives
        return primitives!.update(pl)
    }

    func getNumPrimitives() -> Int32 {
        return (primitives == nil ? 0 : primitives!.getNumPrimitives())
    }

    func getWorldBounds(_ o2w: AffineTransform?) -> BoundingBox? {
        if primitives == nil {
            let b: BoundingBox? = tesselatable!.getWorldBounds(o2w)

            if b != nil {
                return b!
            }

            if builtTess == 0 {
                tesselate()
            }

            if primitives == nil {
                return nil //  failed tesselation, return infinite bounding box
            }
        }

        return primitives!.getWorldBounds(o2w)
    }

    func intersect(_ r: Ray, _ state: IntersectionState) {
         lockQueue.sync { // synchronized block
            if builtTess == 0 {
                tesselate()
            }

            if builtAccel == 0 {
                build()
            }
            
            accel!.intersect(r, state)
        }
    }

    func tesselate() {
        //lockQueue.sync { // synchronized block
            //  double check flag
            if builtTess != 0 {
                return
            }

            if tesselatable != nil && (primitives == nil) {
                UI.printInfo(.GEOM, "Tesselating geometry ...")

                primitives = tesselatable!.tesselate()

                if primitives == nil {
                    UI.printError(.GEOM, "Tesselation failed - geometry will be discarded")
                } else {
                    UI.printDetailed(.GEOM, "Tesselation produced \(primitives!.getNumPrimitives()) primitives")
                }
            }

            builtTess = 1
        //}
    }

    func build() {
        //lockQueue.sync { // synchronized block
            //  double check flag
            if builtAccel != 0 {
                return
            }

            if primitives != nil {
                let n: Int32 = primitives!.getNumPrimitives()

                if n >= 1000 {
                    UI.printInfo(.GEOM, "Building acceleration structure for \(n) primitives ...")
                }

                accel = AccelerationStructureFactory.create(acceltype, n, true)

                accel!.build(primitives!)
            } else {
                //  create an empty accelerator to avoid having to check for null
                //  pointers in the intersect method
                accel = NullAccelerator()
            }

            builtAccel = 1
        //}
    }

    func prepareShadingState(_ state: ShadingState) {
        primitives!.prepareShadingState(state)
    }

    func getBakingPrimitives() -> PrimitiveList? {
        if builtTess == 0 {
            tesselate()
        }
        if primitives == nil {
            return nil
        }
        return primitives!.getBakingPrimitives()
    }

    func getPrimitiveList() -> PrimitiveList? {
        return primitives
    }
}
