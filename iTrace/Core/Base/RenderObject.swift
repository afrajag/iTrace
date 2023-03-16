//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

protocol RenderObject: Initializable {
    // Update this object given a list of parameters. This method is guarenteed
    // to be called at least once on every object, but it should correctly
    // handle empty parameter lists. This means that the object should be in a
    // valid state from the time it is constructed. This method should also
    // return true or false depending on whether the update was succesfull or
    // not.
    //
    // @param pl list of parameters to read from
    // @param api reference to the current scene
    // @return true if the update is succesfull,
    //         false otherwise
    @discardableResult
    func update(_ pl: ParameterList) -> Bool
}
