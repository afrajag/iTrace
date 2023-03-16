//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class DiagonalBucketOrder: BucketOrder {
    required init() {}
 
    func getBucketSequence(_ nbw: Int32, _ nbh: Int32) -> [Int32] {
        var coords: [Int32] = [Int32](repeating: 0, count: Int(2 * nbw * nbh))
        var x: Int32 = 0
        var y: Int32 = 0
        var nx: Int32 = 1
        var ny: Int32 = 0
        
        for i in 0 ..< nbw * nbh {
            coords[2 * Int(i) + 0] = x
            coords[2 * Int(i) + 1] = y
            
            repeat {
                if y == ny {
                    y = 0
                    x = nx
                    
                    ny += 1
                    nx += 1
                } else {
                    x -= 1
                    y += 1
                }
            } while ((y >= nbh || x >= nbw) && i != (nbw * nbh - 1))
        }
        
        return coords
    }
}
