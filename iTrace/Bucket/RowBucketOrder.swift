//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class RowBucketOrder: BucketOrder {
    required init() {}
 
    func getBucketSequence(_ nbw: Int32, _ nbh: Int32) -> [Int32] {
        var coords: [Int32] = [Int32](repeating: 0, count: Int(2 * nbw * nbh))
        
        for i in 0 ..< nbw * nbh {
            let by: Int32 = i / nbw
            var bx: Int32 = i % nbw
            
            if (by & 1) == 1 {
                bx = nbw - 1 - bx
            }
            
            coords[2 * Int(i) + 0] = bx
            coords[2 * Int(i) + 1] = by
        }
        return coords
    }
}
