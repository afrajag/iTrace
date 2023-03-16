//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class IrregularSpectralCurve: SpectralCurve {
    var waveLengths: [Float]
    var amplitudes: [Float]

    // Define an irregular spectral curve from the provided (sorted) waveLengths
    // and amplitude data. The waveLength array is assumed to contain values in
    // nanometers. Array Lengths must match.
    //
    // @param waveLengths sampled waveLengths in nm
    // @param amplitudes amplitude of the curve at the sampled points
    init(_ waveLengths: [Float], _ amplitudes: [Float]) {
        self.waveLengths = waveLengths
        self.amplitudes = amplitudes

        if waveLengths.count != amplitudes.count {
            fatalError("Error creating irregular spectral curve: \(waveLengths.count) waveLengths and \(amplitudes.count) amplitudes")
        }

        for i in 1 ..< waveLengths.count {
            if waveLengths[i - 1] >= waveLengths[i] {
                fatalError("Error creating irregular spectral curve: values are not sorted - error at index \(i)")
            }
        }

        super.init()
    }

    override func sample(_ lambda: Float) -> Float {
        if waveLengths.isEmpty {
            return 0 //  no data
        }

        if (waveLengths.count == 1) || (lambda <= waveLengths[0]) {
            return amplitudes[0]
        }

        if lambda >= waveLengths[waveLengths.count - 1] {
            return amplitudes[waveLengths.count - 1]
        }

        for i in 1 ..< waveLengths.count {
            if lambda < waveLengths[i] {
                let dx: Float = (lambda - waveLengths[i - 1]) / (waveLengths[i] - waveLengths[i - 1])

                return (1 - dx) * amplitudes[i - 1] + dx * amplitudes[i]
            }
        }

        return amplitudes[waveLengths.count - 1]
    }
}
