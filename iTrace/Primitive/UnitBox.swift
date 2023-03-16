//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class UnitBox: Box {
    required init() {
        super.init()
        
        minX = 0
        minY = 0
        minZ = 0
        maxX = +1
        maxY = +1
        maxZ = +1
    }
}

