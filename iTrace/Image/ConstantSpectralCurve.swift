//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class ConstantSpectralCurve: SpectralCurve {
    var amp: Float = 0.0

    init(_ amp: Float) {
        self.amp = amp

        super.init()
    }

    override func sample(_: Float) -> Float {
        return amp
    }
}
