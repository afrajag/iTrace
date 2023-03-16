//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class ViewGlobalPhotonsShader: Shader {
    required init() {}

    func update(_ pl: ParameterList) -> Bool {
        return true
    }

    func getRadiance(_ state: ShadingState) -> Color {
        state.faceforward()
        
        return state.getGlobalRadiance()
    }

    func scatterPhoton(_: ShadingState, _: Color) {}
}
