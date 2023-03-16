//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class AccelerationStructureFactory {
    static func create(_ name: String?, _ n: Int32, _ primitives: Bool) -> AccelerationStructure {
        var _name: String = ""

        // FIXME: per debug accel structure
        /*
         if name == nil || name!.isEmpty {
             Thread.callStackSymbols.forEach{print($0)}
         }
         */

        if name == nil || name! == "auto" {
            if primitives {
                if n > 20_000_000 {
                    _name = "uniformgrid"
                } else if n > 2_000_000 {
                    _name = "bih"
                } else if n > 1 {
                    _name = "kdtree"
                } else {
                    _name = "null"
                }
            } else {
                if n > 1 {
                    _name = "bih"
                } else {
                    _name = "null"
                }
            }
        } else {
            _name = name!
        }

        // #if DEBUG
        // UI.printInfo(.ACCEL, "  * building \(_name) acceleration structure ...")
        // #endif

        let accel: AccelerationStructure? = PluginRegistry.accelPlugins.createInstance(_name)

        guard accel != nil else {
            UI.printWarning(.ACCEL, "  * unrecognized intersection accelerator \'\(_name == "" ? "NULL" : _name)\' - using auto")

            return create("auto", n, primitives)
        }

        return accel!
    }
}
