//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class FisheyeLens: CameraLens {
    required init() {}
    
    func update(_ pl: ParameterList) -> Bool {
        return true
    }

    func getRay(_ x: Float, _ y: Float, _ imageWidth: Int32, _ imageHeight: Int32, _ lensX: Double, _ lensY: Double, _ time: Double) -> Ray? {
        let cx: Float = 2.0 * x / Float(imageWidth) - 1.0
        let cy: Float = 2.0 * y / Float(imageHeight) - 1.0
        let r2: Float = cx * cx + cy * cy
    
        if r2 > 1 {
            return nil //  outside the fisheye
        }
        
        return Ray(0, 0, 0, cx, cy, -sqrt(1 - r2))
    }
}
