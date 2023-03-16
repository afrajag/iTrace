//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class IDShaderParameter: ShaderParameter {
    override func setup() {
        API.shared.shader(name, Self.TYPE_SHOW_INSTANCE_ID)
    }
}
