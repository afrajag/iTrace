//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class RandomBucketOrder: BucketOrder {
    required init() {}
 
    func getBucketSequence(_ nbw: Int32, _ nbh: Int32) -> [Int32] {
        var coords: [Int32] = [Int32](repeating: 0, count: Int(2 * nbw * nbh))
        
        for i in 0 ..< nbw * nbh {
            let by: Int32 = i / nbw
            var bx: Int32 = i % nbw
            
            if (by & 1) == 1 {
                bx = nbw - 1 - bx
            }
            
            coords[(2 * Int(i)) + 0] = bx
            coords[(2 * Int(i)) + 1] = by
        }
        
        var seed: Int64 = 2_463_534_242
        
        for _ in 0 ..< coords.count {
            //  pick 2 random indices
            seed = xorshift(seed)
            
            let src: Int32 = mod(Int32(seed), nbw * nbh)
            
            seed = xorshift(seed)
            
            let dst: Int32 = mod(Int32(seed), nbw * nbh)
            var tmp: Int32 = coords[(2 * Int(src)) + 0]
            
            coords[2 * Int(src) + 0] = coords[2 * Int(dst) + 0]
            coords[2 * Int(dst) + 0] = tmp
            
            tmp = coords[(2 * Int(src)) + 1]
            
            coords[2 * Int(src) + 1] = coords[2 * Int(dst) + 1]
            coords[2 * Int(dst) + 1] = tmp
        }
        
        return coords
    }

    func mod(_ a: Int32, _ b: Int32) -> Int32 {
        let m: Int32 = a % b
        
        return (m < 0) ? m + b : m
    }

    func xorshift(_ y: Int64) -> Int64 {
        var _y = y
        
        _y = _y ^ (_y << 13)
        
        _y = _y ^ (_y >>> 17)
        
        _y = _y ^ (_y << 5)
        
        return _y
    }
}
