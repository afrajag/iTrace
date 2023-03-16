//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class SphericalLens: CameraLens {
    required init() {}
    
    func update(_ pl: ParameterList) -> Bool {
        return true
    }

    func getRay(_ x: Float, _ y: Float, _ imageWidth: Int32, _ imageHeight: Int32, _ lensX: Double, _ lensY: Double, _ time: Double) -> Ray? {
        //  Generate environment camera ray direction
        let theta: Double = 2 * Double.pi * Double(x) / Double(imageWidth) + Double.pi / 2
        let phi: Double = Double.pi * Double(imageHeight - 1 - Int32(y)) / Double(imageHeight)
        
        return Ray(0, 0, 0, Float(cos(theta) * sin(phi)), Float(cos(phi)), Float(sin(theta) * sin(phi)))
    }
}
