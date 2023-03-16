//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class LightSample {
    var shadowRay: Ray?
    var ldiff: Color?
    var lspec: Color?
    var next: LightSample? // pointer to next item in a linked list of samples

    // Creates a new light sample object (invalid by default).
    init() {
        ldiff = nil
        lspec = nil
        shadowRay = nil
        next = nil
    }

    func isValid() -> Bool {
        return ldiff != nil && lspec != nil && shadowRay != nil
    }

    // Set the current shadow ray. The ray's direction is used as the sample's
    // orientation.
    //
    // @param shadowRay shadow ray from the point being shaded towards the light
    func setShadowRay(_ shadowRay: Ray) {
        self.shadowRay = shadowRay
    }

    // Trace the shadow ray, attenuating the sample's color by the opacity of
    // intersected objects.
    //
    // @param state shading state representing the point to be shaded
    func traceShadow(_ state: ShadingState) {
        let opacity: Color = state.traceShadow(shadowRay!)

        ldiff!.set(Color.blend(ldiff!, Color.BLACK, opacity))
        lspec!.set(Color.blend(lspec!, Color.BLACK, opacity))
    }

    // Get the sample's shadow ray.
    //
    // @return shadow ray
    func getShadowRay() -> Ray {
        return shadowRay!
    }

    // Get diffuse radiance.
    //
    // @return diffuse radiance
    func getDiffuseRadiance() -> Color {
        return ldiff!
    }

    // Get specular radiance.
    //
    // @return specular radiance
    func getSpecularRadiance() -> Color {
        return lspec!
    }

    // Set the diffuse and specular radiance emitted by the current light
    // source. These should usually be the same, but are distinguished to allow
    // for non-physical light setups or light source types which compute diffuse
    // and specular responses seperately.
    //
    // @param d diffuse radiance
    // @param s specular radiance
    func setRadiance(_ d: Color, _ s: Color) {
        ldiff = d.copy()
        lspec = s.copy()
    }

    // Compute a dot product between the current shadow ray direction and the
    // specified vector.
    //
    // @param v direction vector
    // @return dot product of the vector with the shadow ray direction
    func dot(_ v: Vector3) -> Float {
        return shadowRay!.dot(v)
    }
}
