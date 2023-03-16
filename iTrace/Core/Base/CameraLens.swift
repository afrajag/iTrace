//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

protocol CameraLens: RenderObject {
    // Create a new {@link Ray ray}to be cast through pixel (x,y) on the image
    // plane. Two sampling parameters are provided for lens sampling. They are
    // guarenteed to be in the interval [0,1). They can be used to perturb the
    // position of the source of the ray on the lens of the camera for DOF
    // effects. A third sampling parameter is provided for motion blur effects.
    // Note that the {@link Camera} final class already handles camera movement motion
    // blur. Rays should be generated in camera space - that is, with the eye at
    // the origin, looking down the -Z axis, with +Y pointing up.
    //
    // @param x x coordinate of the (sub)pixel
    // @param y y coordinate of the (sub)pixel
    // @param imageWidth image width in pixels
    // @param imageHeight image height in pixels
    // @param lensX x lens sampling parameter
    // @param lensY y lens sampling parameter
    // @param time time sampling parameter
    // @return a new ray passing through the given pixel
    func getRay(_ x: Float, _ y: Float, _ imageWidth: Int32, _ imageHeight: Int32, _ lensX: Double, _ lensY: Double, _ time: Double) -> Ray?
}
