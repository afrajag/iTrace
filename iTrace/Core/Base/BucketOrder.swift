//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

protocol BucketOrder: Initializable {
    // Computes the order in which each coordinate on the screen should be
    // visited.
    //
    // @param nbw number of buckets in the X direction
    // @param nbh number of buckets in the Y direction
    // @return array of coordinates with interleaved X, Y of the positions of
    //         buckets to be rendered.
    func getBucketSequence(_ nbw: Int32, _ nbh: Int32) -> [Int32]
}
