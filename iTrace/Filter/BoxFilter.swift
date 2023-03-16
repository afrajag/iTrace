//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class BoxFilter: Filter {
    required init() {}
    
    func getSize() -> Float {
        return 1.0
    }

    func get(_: Float, _: Float) -> Float {
        return 1.0
    }
}
