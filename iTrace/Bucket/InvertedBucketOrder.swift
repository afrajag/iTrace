//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class InvertedBucketOrder: BucketOrder {
    var order: BucketOrder?
    
    required init() {}
    
    required init(_ order: BucketOrder) {
        self.order = order
    }

    func getBucketSequence(_ nbw: Int32, _ nbh: Int32) -> [Int32] {
        var coords: [Int32] = order!.getBucketSequence(nbw, nbh)
        var i: Int32 = 0
       
        while i < (coords.count / 2) {
            let src: Int32 = i
            let dst: Int32 = Int32(coords.count - 2) - i
            var tmp: Int32 = coords[Int(src) + 0]
            
            coords[Int(src) + 0] = coords[Int(dst) + 0]
            
            coords[Int(dst) + 0] = tmp
            
            tmp = coords[Int(src) + 1]
            
            
            coords[Int(src) + 1] = coords[Int(dst) + 1]
            coords[Int(dst) + 1] = tmp
            
            i = i + 2
        }
        
        return coords
    }
}

