//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class CatmullRomFilter: Filter {
    required init() {}
    
    func getSize() -> Float {
        return 4.0
    }

    func get(_ x: Float, _ y: Float) -> Float {
        return catrom1d(x) * catrom1d(y)
    }

    func catrom1d(_ x: Float) -> Float {
        let _x = abs(x)
        
        let x2: Float = _x * _x
        let x3: Float = _x * x2
        
        if _x >= 2 {
            return 0
        }
        
        if _x < 1 {
            return ((3 * x3) - (5 * x2)) + 2
        }
        
        return ((-x3 + (5 * x2)) - (8 * _x)) + 4
    }
}
