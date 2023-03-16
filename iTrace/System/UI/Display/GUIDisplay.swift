//
//  GUIDisplay.swift
//  iTrace
//
//  Created by Fabrizio Pezzola on 25/04/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class GUIDisplay: Display {
    var delegate: AppDelegate? = nil
    
    required init() {}
    
    init(_ delegate: AppDelegate?) {
        self.delegate = delegate
    }
    
    // This is called before an image is rendered to indicate how large the
    // rendered image will be. This allows the display driver to write out image
    // headers or allocate surfaces. Bucket size will be 0 when called from a
    // non-bucket based source.
    //
    // @param w width of the rendered image in pixels
    // @param h height of the rendered image in pixels
    // @param bucketSize size of the buckets in pixels
    func imageBegin(_ w: Int32, _ h: Int32, _ bucketSize: Int32) {
         delegate!.viewController.imageBegin(w, h, bucketSize)
    }

    // Prepare the specified area to be rendered. This may be used to highlight
    // the work in progress area or simply to setup the display driver to
    // receive the specified portion of the image
    //
    // @param x x coordinate of the bucket within the image
    // @param y y coordinate of the bucket within the image
    // @param w width of the bucket in pixels
    // @param h height of the bucket in pixels
    // @param id unique identifier corresponding to the thread which invoked
    //            this call
    func imagePrepare(_ x: Int32, _ y: Int32, _ w: Int32, _ h: Int32, _ id: Int32) {
        delegate!.viewController.imagePrepare(x, y, w, h, id)
    }

    // update the current image with a bucket of data. The region is guarenteed
    // to be within the bounds created by the call to imageBegin. No clipping is
    // necessary. Colors are passed in unprocessed. It is up the display driver
    // to do any type of quantization, gamma compensation or tone-mapping
    // needed. The array of colors will be exactly w * h long and
    // in row major order.
    //
    // @param x x coordinate of the bucket within the image
    // @param y y coordinate of the bucket within the image
    // @param w width of the bucket in pixels
    // @param h height of the bucket in pixels
    // @param data bucket data, this array will be exactly w * h
    //            long
    func imageUpdate(_ x: Int32, _ y: Int32, _ w: Int32, _ h: Int32, _ data: [Color], _ alpha: [Float]) {
        delegate!.viewController.imageUpdate(x, y, w, h, data, alpha)
    }

    // update the current image with a region of flat color. This is used by
    // progressive rendering to render progressively smaller regions of the
    // screen which will overlap. The region is guarenteed to be within the
    // bounds created by the call to imageBegin. No clipping is necessary.
    // Colors are passed in unprocessed. It is up the display driver to do any
    // type of quantization , gamma compensation or tone-mapping needed.
    //
    // @param x x coordinate of the region within the image
    // @param y y coordinate of the region within the image
    // @param w with of the region in pixels
    // @param h height of the region in pixels
    // @param c color to fill the region with
    func imageFill(_ x: Int32, _ y: Int32, _ w: Int32, _ h: Int32, _ c: Color, _ alpha: Float) {
        delegate!.viewController.imageFill(x, y, w, h, c, alpha)
    }

    // This call is made after the image has been rendered. This allows the
    // display driver to close any open files, write the image to disk or flush
    // any other type of buffers.
    func imageEnd() {}
}
