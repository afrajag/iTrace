//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

protocol GlobalPhotonMapInterface: PhotonStore {
    // Lookup the global diffuse radiance at the specified surface point.
    //
    // @param p surface position
    // @param n surface normal
    // @return an approximation of global diffuse radiance at this point
    func getRadiance(_ p: Point3, _ n: Vector3) -> Color
}
