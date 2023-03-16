//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//
import Foundation

final class GaussianFilter: Filter {
    var es2: Float = 0.0

    required init() {
        es2 = Float(-exp(-getSize() * getSize()))
    }

    func getSize() -> Float {
        return 3.0
    }

    func get(_ x: Float, _ y: Float) -> Float {
        let gx: Float = Float(exp(-x * x)) + es2
        let gy: Float = Float(exp(-y * y)) + es2

        return gx * gy
    }
}
