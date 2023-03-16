//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

protocol Filter: Initializable {
    // Width in pixels of the filter extents. The filter will be applied to the
    // range of pixels within a box of +/- getSize() / 2 around
    // the center of the pixel.
    //
    // @return width in pixels
    func getSize() -> Float

    // Get value of the filter at offset (x, y). The filter should never be
    // called with values beyond its extents but should return 0 in those cases
    // anyway.
    //
    // @param x x offset in pixels
    // @param y y offset in pixels
    // @return value of the filter at the specified location
    func get(_ x: Float, _ y: Float) -> Float
}
