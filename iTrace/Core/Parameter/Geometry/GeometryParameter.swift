//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

class GeometryParameter: ObjectParameter {
    override func setup() {
        super.setup()
    }
    
    func setupInstance() {
        if instanceParameter != nil {
            instanceParameter!.name(name + ".instance")

            if instanceParameter!.geometry() == nil {
                instanceParameter!.geometry(name)
            }

            instanceParameter!.setup()
        }
    }
}
