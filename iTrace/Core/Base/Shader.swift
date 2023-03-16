//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

protocol Shader: RenderObject {
    // Gets the radiance for a specified rendering state. When this method is
    // called, you can assume that a hit has been registered in the state and
    // that the hit surface information has been computed.
    //
    // @param state current render state
    // @return color emitted or reflected by the shader
    func getRadiance(_ state: ShadingState) -> Color

    // Scatter a photon with the specied power. Incoming photon direction is
    // specified by the ray attached to the current render state. This method
    // can safely do nothing if photon scattering is not supported or relevant
    // for the shader type.
    //
    // @param state current state
    // @param power power of the incoming photon.
    func scatterPhoton(_ state: ShadingState, _ power: Color)
}
