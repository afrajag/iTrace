//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class ConstantShader: Shader {
    var c: Color?

    required init() {
        c = Color.WHITE
    }

    func update(_ pl: ParameterList) -> Bool {
        c = pl.getColor("color", c)

        return true
    }

    func getRadiance(_: ShadingState) -> Color {
        return c!
    }

    func scatterPhoton(_: ShadingState, _: Color) {}
}
