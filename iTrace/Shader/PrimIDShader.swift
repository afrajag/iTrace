//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class PrimIDShader: Shader {
    static var BORDERS: [Color] = [Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW, Color.CYAN, Color.MAGENTA]

    required init() {}

    func update(_ pl: ParameterList) -> Bool {
        return true
    }

    func getRadiance(_ state: ShadingState) -> Color {
        let n: Vector3? = state.getNormal()
        let f: Float = n == nil ? 1.0 : abs(state.getRay()!.dot(n!))
        
        return PrimIDShader.BORDERS[Int(state.getPrimitiveID()) % PrimIDShader.BORDERS.count].copy().mul(f)
    }

    func scatterPhoton(_ state: ShadingState, _ power: Color) {}
}
