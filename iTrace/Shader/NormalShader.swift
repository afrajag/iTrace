//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class NormalShader: Shader {
    required init() {}

    func update(_ pl: ParameterList) -> Bool {
        return true
    }

    func getRadiance(_ state: ShadingState) -> Color {
        let n: Vector3? = state.getNormal()
        
        if n == nil {
            return Color.BLACK
        }
        
        let r: Float = (n!.x + 1) * 0.5
        let g: Float = (n!.y + 1) * 0.5
        let b: Float = (n!.z + 1) * 0.5
        
        return Color(r, g, b)
    }

    func scatterPhoton(_: ShadingState, _: Color) {}
}
