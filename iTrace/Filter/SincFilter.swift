//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class SincFilter: Filter {
    required init() {}
    
    func getSize() -> Float {
        return 4
    }

    func get(_ x: Float, _ y: Float) -> Float {
        return sinc1d(x) * sinc1d(y)
    }

    func sinc1d(_ x: Float) -> Float {
        var _x = abs(x)
        
        if _x < 0.0001 {
            return 1.0
        }
        
        _x = _x * Float.pi
        
        return sin(_x) / _x
    }
}
