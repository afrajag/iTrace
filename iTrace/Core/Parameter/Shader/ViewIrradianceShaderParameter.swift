//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class ViewIrradianceShaderParameter: ShaderParameter {
    override func setup() {
        API.shared.shader(name, Self.TYPE_VIEW_IRRADIANCE)
    }
}
