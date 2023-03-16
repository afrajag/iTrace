//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//
import Foundation

final class TriangleFilter: Filter {
    required init() {}

    func getSize() -> Float {
        return 2.0
    }

    func get(_ x: Float, _ y: Float) -> Float {
        return (1.0 - abs(x)) * (1.0 - abs(y))
    }
}
