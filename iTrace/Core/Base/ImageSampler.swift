//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

protocol ImageSampler: Initializable {
    // Prepare the sampler for rendering an image of w x h pixels
    //
    // @param w width of the image
    // @param h height of the image
    @discardableResult
    func prepare(_ options: Options, _ scene: Scene, _ w: Int32, _ h: Int32) -> Bool

    // Render the image to the specified display. The sampler can assume the
    // display has been opened and that it will be closed after the method
    // returns.
    //
    // @param display Display driver to send image data to
    func render(_ display: Display)
}
