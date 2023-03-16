//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

protocol GIEngine: Initializable {
    // This is an optional method for engines that contain a secondary
    // illumination engine which can return an approximation of the global
    // radiance in the scene (like a photon map). Engines can safely return
    // Color.BLACK if they can't or don't wish to support this.
    //
    // @param state shading state
    // @return color approximating global radiance
    func getGlobalRadiance(_ state: ShadingState) -> Color

    // Initialize the engine. This is called before rendering begins.
    //
    // @return true if the init phase succeeded,
    //         false otherwise
    func initGI(_ options: Options, _ scene: Scene) -> Bool

    // Return the incomming irradiance due to indirect diffuse illumination at
    // the specified surface point.
    //
    // @param state current render state describing the point to be computed
    // @param diffuseReflectance diffuse albedo of the point being shaded, this
    //            can be used for importance tracking
    // @return irradiance from indirect diffuse illumination at the specified
    //         point
    func getIrradiance(_ state: ShadingState, _ diffuseReflectance: Color) -> Color
}
