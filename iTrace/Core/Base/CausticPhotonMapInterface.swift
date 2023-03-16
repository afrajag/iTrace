//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

protocol CausticPhotonMapInterface: PhotonStore {
    // Retrieve caustic photons at the specified shading location and add them
    // as diffuse light samples.
    //
    // @param state
    func getSamples(_ state: ShadingState)
}
