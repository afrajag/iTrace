//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//
import Foundation

final class BlackbodySpectrum: SpectralCurve {
    var temp: Float = 0.0

    init(_ temp: Float) {
        self.temp = temp
    }

    override func sample(_ lambda: Float) -> Float {
        let waveLength: Double = Double(lambda) * 1e-09

        return Float(3.74183e-16 * pow(waveLength, -5.0)) / (exp(1.4388e-2 / (Float(waveLength) * temp)) - 1.0)
    }
}
