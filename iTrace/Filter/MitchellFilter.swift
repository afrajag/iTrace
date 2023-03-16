//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class MitchellFilter: Filter {
    required init() {}
    
    func getSize() -> Float {
        return 4.0
    }

    func get(_ x: Float, _ y: Float) -> Float {
        return mitchell(x) * mitchell(y)
    }

    func mitchell(_ x: Float) -> Float {
        let B: Float = 1 / 3.0
        let C: Float = 1 / 3.0
        let SIXTH: Float = 1 / 6.0
        
        let _x = abs(x)
        
        let x2: Float = _x * _x
        
        if _x > 1.0 {
            return (((-B - (6 * C)) * _x * x2) + (((6 * B) + (30 * C)) * x2) + (((-12 * B) - (48 * C)) * _x) + (8 * B) + (24 * C)) * SIXTH
        }
        
        return (((12 - (9 * B) - (6 * C)) * _x * x2) + ((-18 + (12 * B) + (6 * C)) * x2) + (6 - (2 * B))) * SIXTH
    }
}
