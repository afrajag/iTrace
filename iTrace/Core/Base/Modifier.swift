//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

protocol Modifier: RenderObject {
    // Modify the shading state for the point to be shaded.
    //
    // @param state shading state to modify
    func modify(_ state: ShadingState)
}
