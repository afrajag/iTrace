//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class LanczosFilter: Filter {
    required init() {}
    
    func getSize() -> Float {
        return 4.0
    }

    func get(_ x: Float, _ y: Float) -> Float {
        return sinc1d(x * 0.5) * sinc1d(y * 0.5)
    }

    func sinc1d(_ x: Float) -> Float {
        var _x = abs(x)
        
        if _x < 1e-5 {
            return 1
        }
        
        if _x > 1.0 {
            return 0
        }
        
        _x = _x * Float.pi
        
        let sinc: Float = sin(3 * _x) / (3 * _x)
        let lanczos: Float = sin(_x) / _x
        
        return sinc * lanczos
    }
}
