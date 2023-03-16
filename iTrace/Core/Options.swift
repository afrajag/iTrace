//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class Options: ParameterList, RenderObject {
    func update(_ pl: ParameterList) -> Bool {
        //  take all attributes, and update them into the current set
        for e in pl.list {
            list[e.key] = e.value

            e.value.check()
        }

        return true
    }
}
