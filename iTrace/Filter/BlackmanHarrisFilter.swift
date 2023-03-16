//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class BlackmanHarrisFilter: Filter {
    required init() {}
    
    func getSize() -> Float {
        return 4
    }

    func get(_ x: Float, _ y: Float) -> Float {
        return bh1d(x * 0.5) * bh1d(y * 0.5)
    }

    func bh1d(_ x: Float) -> Float {
        
        if (x < -1.0) || (x > 1.0) {
            return 0.0
        }
        
        let _x: Double = Double(x + 1) * 0.5
        
        let A0: Double = 0.35875
        let A1: Double = -0.48829
        let A2: Double = 0.14128
        let A3: Double = -0.01168
        
        return Float(A0 + A1 * cos(2 * Double.pi * _x) + A2 * cos(4 * Double.pi * _x) + A3 * cos(6 * Double.pi * _x))
    }
}
