//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class ThinLens: CameraLens {
    var focusDistance: Float = 0.0
    var lensRadius: Float = 0.0
    var lensSides: Int32 = 0
    var lensRotation: Float = 0.0
    var lensRotationRadians: Float = 0.0
    var au: Float = 0.0
    var av: Float = 0.0
    var aspect: Float = 0.0
    var fov: Float = 0.0
    var shiftX: Float = 0.0
    var shiftY: Float = 0.0

    required init() {
        focusDistance = 1
        lensRadius = 0
        fov = 90
        aspect = 1
        shiftX = 0
        shiftY = 0
        
        lensSides = 0 //  < 3 means use circular lens
        lensRotation = 0
        lensRotationRadians = 0 //  this rotates polygonal lenses
    }

    func update(_ pl: ParameterList) -> Bool {
        //  get parameters
        fov = pl.getFloat("fov", fov)!
        aspect = pl.getFloat("aspect", aspect)!
        shiftX = pl.getFloat("shift.x", shiftX)!
        shiftY = pl.getFloat("shift.y", shiftY)!
        focusDistance = pl.getFloat("focus.distance", focusDistance)!
        lensRadius = pl.getFloat("lens.radius", lensRadius)!
        lensSides = pl.getInt("lens.sides", lensSides)!
        lensRotation = pl.getFloat("lens.rotation", lensRotation)!
        
        update()
        
        return true
    }

    func update() {
        au = Float(tan(MathUtils.toRadians(Double(fov) * 0.5))) * focusDistance
        
        av = au / aspect
        
        lensRotationRadians = Float(MathUtils.toRadians(Double(lensRotation)))
    }

    func getRay(_ x: Float, _ y: Float, _ imageWidth: Int32, _ imageHeight: Int32, _ lensX: Double, _ lensY: Double, _ time: Double) -> Ray? {
        let du: Float = shiftX * focusDistance - au + ((2.0 * au * x) / (Float(imageWidth) - 1.0))
        let dv: Float = shiftY * focusDistance - av + ((2.0 * av * y) / (Float(imageHeight) - 1.0))
        var eyeX: Float
        var eyeY: Float
        
        if lensSides < 3 {
            var angle: Double
            var r: Double
            
            //  concentric map sampling
            let r1: Double = 2 * lensX - 1
            let r2: Double = 2 * lensY - 1
            
            if r1 > -r2 {
                if r1 > r2 {
                    r = r1
                    
                    angle = 0.25 * Double.pi * r2 / r1
                } else {
                    r = r2
                    
                    angle = 0.25 * Double.pi * (2 - r1 / r2)
                }
            } else {
                if r1 < r2 {
                    r = -r1
                    
                    angle = 0.25 * Double.pi * (4 + r2 / r1)
                } else {
                    r = -r2
                    
                    if r2 != 0 {
                        angle = 0.25 * Double.pi * (6 - r1 / r2)
                    } else {
                        angle = 0
                    }
                }
            }
            
            r *= Double(lensRadius)
            
            //  point on the lens
            eyeX = Float(cos(angle) * r)
            eyeY = Float(sin(angle) * r)
        } else {
            //  sample N-gon
            //  FIXME: this could use concentric sampling
            var _lensY = lensY
            _lensY *= Double(lensSides)
            
            let side: Float = Float(_lensY)
            let offs: Float = Float(_lensY) - side
            let dist: Float = Float(sqrt(lensX))
            let a0: Float = side * Float.pi * 2.0 / Float(lensSides) + lensRotationRadians
            let a1: Float = Float((side + 1.0) * Float.pi * 2.0 / Float(lensSides) + lensRotationRadians)
            
            eyeX = (cos(a0) * (1.0 - offs) + cos(a1) * offs) * dist
            eyeY = (sin(a0) * (1.0 - offs) + sin(a1) * offs) * dist
            
            eyeX *= lensRadius
            eyeY *= lensRadius
        }
        
        let eyeZ: Float = 0
        
        //  point on the image plane
        let dirX: Float = du
        let dirY: Float = dv
        let dirZ: Float = -focusDistance
        
        //  ray
        return Ray(eyeX, eyeY, eyeZ, dirX - eyeX, dirY - eyeY, dirZ - eyeZ)
    }
}
