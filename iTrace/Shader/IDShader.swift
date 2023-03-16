//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class IDShader: Shader {
    required init() {}

    func update(_ pl: ParameterList) -> Bool {
        return true
    }

    func getRadiance(_ state: ShadingState) -> Color {
        let n: Vector3? = state.getNormal()
        let f: Float = n == nil ? 1.0 : abs(state.getRay()!.dot(n!))
        
        return Color(Int32(state.getInstance().debugDescription.hashValue)).mul(f)
    }

    func scatterPhoton(_: ShadingState, _: Color) {}
}
