//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class XYZColor {
    var X: Float = 0.0
    var Y: Float = 0.0
    var Z: Float = 0.0

    init() {}

    init(_ X: Float, _ Y: Float, _ Z: Float) {
        self.X = X
        self.Y = Y
        self.Z = Z
    }

    func getX() -> Float {
        return X
    }

    func getY() -> Float {
        return Y
    }

    func getZ() -> Float {
        return Z
    }

    func mul(_ s: Float) -> XYZColor {
        X *= s
        Y *= s
        Z *= s

        return self
    }

    func normalize() {
        let XYZ: Float = X + Y + Z

        if XYZ < 1e-6 {
            return
        }

        let s: Float = 1 / XYZ

        X *= s
        Y *= s
        Z *= s
    }

    func toString() -> String {
        return "(\(X), \(Y), \(Z))"
    }
}
