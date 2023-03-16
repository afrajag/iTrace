//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class CubicBSpline: Filter {
    required init() {}
    
    func get(_ x: Float, _ y: Float) -> Float {
        return B3(x) * B3(y)
    }

    func getSize() -> Float {
        return 4
    }

    func B3(_ t: Float) -> Float {
        let _t = abs(t)
        
        if t <= 1 {
            return b1(1 - _t)
        }
        return b0(2 - _t)
    }

    func b0(_ t: Float) -> Float {
        return t * t * t * (1.0 / 6)
    }

    func b1(_ t: Float) -> Float {
        return (1.0 / 6) * ((-3 * t * t * t) + (3 * t * t) + (3 * t) + 1)
    }
}
