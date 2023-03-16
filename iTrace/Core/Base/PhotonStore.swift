//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

protocol PhotonStore: Initializable {
    // Number of photons to emit from this surface.
    //
    // @return number of photons
    func numEmit() -> Int32

    // Initialize this object for the specified scene size.
    //
    // @param sceneBounds scene bounding box
    func prepare(_ options: Options, _ sceneBounds: BoundingBox)

    // Store the specified photon.
    //
    // @param state shading state
    // @param dir photon direction
    // @param power photon power
    // @param diffuse diffuse color at the hit point
    func store(_ state: ShadingState, _ dir: Vector3, _ power: Color, _ diffuse: Color)

    // Initialize the map after all photons have been stored. This can be used
    // to balance a kd-tree based photon map for example.
    func initStore()

    // Allow photons reflected diffusely
    //
    // @return true if diffuse bounces should be traced
    func allowDiffuseBounced() -> Bool

    // Allow specularly reflected photons
    //
    // @return true if specular reflection bounces should be
    //         traced
    func allowReflectionBounced() -> Bool

    // Allow refracted photons
    //
    // @return true if refracted bounces should be traced
    func allowRefractionBounced() -> Bool
}
