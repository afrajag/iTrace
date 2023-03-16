//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class HilbertBucketOrder: BucketOrder {
    required init() {}
 
    func getBucketSequence(_ nbw: Int32, _ nbh: Int32) -> [Int32] {
        var hi: Int32 = 0 //  hilbert curve index
        var hn: Int32 = 0 //  hilbert curve order
        
        while (((1 << hn) < nbw) || ((1 << hn) < nbh)) && (hn < 16) {
            hn += 1 //  fit to number of buckets
        }
        
        let hN: Int32 = 1 << (2 * hn) //  number of hilbert buckets - 2**2n
        let n: Int32 = nbw * nbh  //  total number of buckets
        var coords: [Int32] = [Int32](repeating: 0, count: 2 * Int(n)) //  storage for bucket coordinates
        
        for i in 0 ..< n {
            var hx: Int32
            var hy: Int32
            
            repeat {
                //  s is the hilbert index, shifted to start in the middle
                var s: Int32 = hi
                
                // adapted from Hacker's Delight
                var comp: Int32
                var swap: Int32
                var cs: Int32
                var t: Int32
                var sr: Int32
                
                s = s | (0x55555555 << (2 * hn)) //  Pad s on left with 01
                
                sr = (s >>> 1) & 0x55555555 //  (no change) groups.
                
                cs = ((s & 0x55555555) + sr) ^ 0x55555555
                
                //  Compute
                //  complement
                //  & swap info in
                //  two-bit groups.
                //  Parallel prefix xor op to propagate both complement
                //  and swap info together from left to right (there is
                //  no step "cs ^= cs >> 1", so in effect it computes
                //  two independent parallel prefix operations on two
                //  interleaved sets of sixteen bits).
                cs = cs ^ (cs >>> 2)
                cs = cs ^ (cs >>> 4)
                cs = cs ^ (cs >>> 8)
                cs = cs ^ (cs >>> 16)
                
                swap = cs & 0x55555555         //  Separate the swap and
                comp = (cs >>> 1) & 0x55555555 //  complement bits.
                
                t = (s & swap) ^ comp     //  Calculate x and y in
                s = s ^ sr ^ t ^ (t << 1) //  the odd & even bit positions, resp.
                s = s & ((1 << (2 * hn)) - 1) //  Clear out any junk on the left (unpad).
                
                //  Now "unshuffle" to separate the x and y bits.
                t = (s ^ (s >>> 1)) & 0x22222222
                
                s = s ^ t ^ (t << 1)
                
                t = (s ^ (s >>> 2)) & 0x0C0C0C0C
                
                s = s ^ t ^ (t << 2)
                
                t = (s ^ (s >>> 4)) & 0x00F000F0
                
                s = s ^ t ^ (t << 4)
                
                t = (s ^ (s >>> 8)) & 0x0000FF00
                
                s = s ^ t ^ (t << 8)
                
                hx = s >>> 16   //  Assign the two halves
                hy = s & 0xFFFF //  of t to x and y.
                
                hi += 1
            } while (hx >= nbw || hy >= nbh || hx < 0 || hy < 0) && hi < hN
            
            coords[2 * Int(i) + 0] = hx
            coords[2 * Int(i) + 1] = hy
        }
        
        return coords
    }
}
