//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//
import Foundation

final class CameraBase: RenderObject {
    var lens: CameraLens?
    var shutterOpen: Float = 0.0
    var shutterClose: Float = 0.0
    var c2w: TimeAffineTransform?
    var w2c: TimeAffineTransform?

    required init() {
        lens = nil
        c2w = TimeAffineTransform(AffineTransform())
        w2c = TimeAffineTransform(AffineTransform())
        shutterOpen = 0
        shutterClose = 0
    }

    init(_ lens: CameraLens) {
        self.lens = lens
        c2w = TimeAffineTransform(AffineTransform())
        w2c = TimeAffineTransform(AffineTransform())
        shutterOpen = 0
        shutterClose = 0
    }

    func update(_ pl: ParameterList) -> Bool {
        shutterOpen = pl.getFloat("shutter.open", shutterOpen)!
        shutterClose = pl.getFloat("shutter.close", shutterClose)!

        c2w = pl.getMovingMatrix("transform", c2w!)

        w2c = c2w!.inverse()

        if w2c == nil {
            UI.printWarning(.CAM, "Unable to compute camera\'s inverse transform")

            return false
        }

        return lens!.update(pl)
    }

    // Computes actual time from a time sample in the interval [0,1). This
    // random number is mapped somewhere between the shutterOpen and
    // shutterClose times.
    //
    // @param time
    // @return
    func getTime(_ time: Float) -> Float {
        var _time = time

        if shutterOpen >= shutterClose {
            return shutterOpen
        }
        //  warp the time sample by a tent filter - this helps simulates the
        //  behaviour of a standard shutter as explained here:
        //  "Shutter Efficiency and Temporal Sampling" by "Ian Stephenson"
        //  http://www.dctsystems.co.uk/Text/shutter.pdf
        if _time < 0.5 {
            _time = -1 + sqrt(2 * _time)
        } else {
            _time = 1 - sqrt(2 - (2 * _time))
        }

        _time = 0.5 * (_time + 1)

        return ((1 - _time) * shutterOpen) + (_time * shutterClose)
    }

    // Generate a ray passing though the specified point on the image plane.
    // Additional random variables are provided for the lens to optionally
    // compute depth-of-field or motion blur effects. Note that the camera may
    // return null for invalid arguments or for pixels which
    // don't project to anything.
    //
    // @param x x pixel coordinate
    // @param y y pixel coordinate
    // @param imageWidth width of the image in pixels
    // @param imageHeight height of the image in pixels
    // @param lensX a random variable in [0,1) to be used for DOF sampling
    // @param lensY a random variable in [0,1) to be used for DOF sampling
    // @param time a random variable in [0,1) to be used for motion blur
    //            sampling
    // @return a ray passing through the specified pixel, or null
    func getRay(_ x: Float, _ y: Float, _ imageWidth: Int32, _ imageHeight: Int32, _ lensX: Double, _ lensY: Double, _ time: Float) -> Ray? {
        var r: Ray? = lens!.getRay(x, y, imageWidth, imageHeight, lensX, lensY, Double(time))

        if r != nil {
            //  transform from camera space to world space
            r = r!.transform(c2w!.sample(time))

            //  renormalize to account for scale factors embeded in the transform
            r!.normalize()
        }

        return r
    }

    // Generate a ray from the origin of camera space toward the specified
    // point.
    //
    // @param p point in world space
    // @return ray from the origin of camera space to the specified point
    func getRay(_ p: Point3, _ time: Float) -> Ray {
        return Ray(c2w == nil ? Point3(0, 0, 0) : c2w!.sample(time)!.transformP(Point3(0, 0, 0)), p)
    }

    // Returns a transformation matrix mapping camera space to world space.
    //
    // @return a transformation matrix
    func getCameraToWorld(_ time: Float) -> AffineTransform {
        return (c2w == nil ? AffineTransform.IDENTITY : c2w!.sample(time))!
    }

    // Returns a transformation matrix mapping world space to camera space.
    //
    // @return a transformation matrix
    func getWorldToCamera(_ time: Float) -> AffineTransform {
        return (w2c == nil ? AffineTransform.IDENTITY : w2c!.sample(time))!
    }
}
