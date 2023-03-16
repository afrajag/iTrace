//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class UVShader: Shader {
    required init() {}

    func update(_ pl: ParameterList) -> Bool {
        return true
    }

    func getRadiance(_ state: ShadingState) -> Color {
        if state.getUV() == nil {
            return Color.BLACK
        }
        return Color(state.getUV()!.x, state.getUV()!.y, 0)
    }

    func scatterPhoton(_: ShadingState, _: Color) {}
}
