//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class ViewCausticsShader: Shader {
    required init() {}

    func update(_ pl: ParameterList) -> Bool {
        return true
    }

    func getRadiance(_ state: ShadingState) -> Color {
        state.faceforward()
        
        state.initCausticSamples()
        
        //  integrate a diffuse function
        let lr: Color = Color.black()
        
        for sample in state.lightSampleList {
            lr.madd(sample.dot(state.getNormal()!), sample.getDiffuseRadiance())
        }
        
        return lr.mul(1.0 / Float.pi)
    }

    func scatterPhoton(_: ShadingState, _: Color) {}
}
