//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class RegularSpectralCurve: SpectralCurve {
    var spectrum: [Float]
    var lambdaMin: Float = 0.0
    var lambdaMax: Float = 0.0
    var delta: Float = 0.0
    var invDelta: Float = 0.0

    init(_ spectrum: [Float], _ lambdaMin: Float, _ lambdaMax: Float) {
        self.lambdaMin = lambdaMin
        self.lambdaMax = lambdaMax
        self.spectrum = spectrum

        delta = (lambdaMax - lambdaMin) / (Float(spectrum.count) - 1)

        invDelta = 1 / delta

        super.init()
    }

    override func sample(_ lambda: Float) -> Float {
        //  reject waveLengths outside the valid range
        if (lambda < lambdaMin) || (lambda > lambdaMax) {
            return 0
        }

        //  interpolate the two closest samples linearly
        let x: Float = (lambda - lambdaMin) * invDelta
        let b0: Int32 = Int32(x)
        let b1: Int32 = min(b0 + 1, Int32(spectrum.count - 1))
        let dx: Float = x - Float(b0)

        return (1 - dx) * spectrum[Int(b0)] + dx * spectrum[Int(b1)]
    }
}
