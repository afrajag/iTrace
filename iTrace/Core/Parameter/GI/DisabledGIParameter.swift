//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class DisabledGIParameter: GlobalIlluminationParameter {
    override func setup() {
        API.shared.parameter(Self.PARAM_ENGINE, Self.TYPE_NONE)

        super.setup()
    }
}
