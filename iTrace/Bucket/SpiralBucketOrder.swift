//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class SpiralBucketOrder: BucketOrder {
    required init() {}
 
    func getBucketSequence(_ nbw: Int32, _ nbh: Int32) -> [Int32] {
        var coords: [Int32] = [Int32](repeating: 0, count: Int(2 * nbw * nbh))
        
        for i in 0 ..< nbw * nbh {
            var bx: Int32
            var by: Int32
            let center: Int32 = (min(nbw, nbh) - 1) / 2
            var nx: Int32 = nbw
            var ny: Int32 = nbh
            
            while i < (nx * ny) {
                nx -= 1
                ny -= 1
            }
            
            let nxny: Int32 = nx * ny
            let minnxny: Int32 = min(nx, ny)
            
            if (minnxny & 1) == 1 {
                if i <= (nxny + ny) {
                    bx = nx - (minnxny / 2)
                    
                    by = ((-minnxny / 2) + i) - nxny
                } else {
                    bx = nx - (minnxny / 2) - i - (nxny + ny)
                    
                    by = ny - (minnxny / 2)
                }
            } else {
                if i <= (nxny + ny) {
                    bx = -minnxny / 2
                    
                    by = ny - (minnxny / 2) - i - nxny
                } else {
                    bx = (-minnxny / 2) + (i - (nxny + ny))
                    
                    by = -minnxny / 2
                }
            }
            
            coords[2 * Int(i) + 0] = bx + center
            coords[2 * Int(i) + 1] = by + center
        }
        
        return coords
    }
}
