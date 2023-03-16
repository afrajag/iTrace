//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class ImageBasedLight: PrimitiveList, LightSource, Shader {
    var texture: Texture?
    var basis: OrthoNormalBasis?
    var numSamples: Int32 = 0
    var numLowSamples: Int32 = 0
    var jacobian: Float = 0.0
    var colHistogram: [Float]?
    var imageHistogram: [[Float]]?
    var samples: [Vector3]?
    var lowSamples: [Vector3]?
    var colors: [Color]?
    var lowColors: [Color]?

    required init() {
        texture = nil
        
        updateBasis(Vector3(0, 0, -1), Vector3(0, 1, 0))
        
        numSamples = 64
        
        numLowSamples = 8
    }

    func updateBasis(_ center: Vector3?, _ up: Vector3?) {
        if center != nil && up != nil {
            basis = OrthoNormalBasis.makeFromWV(center!, up!)
            
            basis!.swapWU()
            
            basis!.flipV()
        }
    }

    func update(_ pl: ParameterList) -> Bool {
        let t: TraceTimer = TraceTimer()

        t.start()
        
        updateBasis(pl.getVector(ImageBasedLightParameter.PARAM_CENTER, nil), pl.getVector(ImageBasedLightParameter.PARAM_UP, nil))
        
        numSamples = pl.getInt(LightParameter.PARAM_SAMPLES, numSamples)!
        
        numLowSamples = pl.getInt(ImageBasedLightParameter.PARAM_LOW_SAMPLES, numLowSamples)!
        
        let filename: String? = pl.getString(ImageBasedLightParameter.PARAM_TEXTURE, nil)
        
        if filename != nil {
            texture = TextureCache.getTexture(API.shared.resolveTextureFilename(filename!), false)
        }
        
        //  no texture provided
        if texture == nil {
            return false
        }
        
        let b: Bitmap? = texture!.getBitmap()
        
        if b == nil {
            return false
        }

        //  rebuild histograms if this is a new texture
        if filename != nil {
            let _width: Int = Int(b!.getWidth())
            let _height: Int = Int(b!.getHeight())
            
            var colHistogram: [Float]? = [Float](repeating: 0, count: _width)
            var imageHistogram: [[Float]]? = [[Float]](repeating: [Float](repeating: 0, count: _height), count: _width)
            
            let du: Float = 1.0 / Float(b!.getWidth())
            let dv: Float = 1.0 / Float(b!.getHeight())
            
            for x in 0 ..< _width {
                for y in 0 ..< _height {
                    let u: Float = (Float(x) + 0.5) * du
                    let v: Float = (Float(y) + 0.5) * dv
                    let c: Color = texture!.getPixel(u, v)
                    
                    imageHistogram![x][y] = c.getLuminance() * Float(sin(Float.pi * v))
                    
                    if y > 0 {
                        imageHistogram![x][y] += imageHistogram![x][y - 1]
                    }
                }
                
                colHistogram![x] = imageHistogram![x][_height - 1]
                
                if x > 0 {
                    colHistogram![x] += colHistogram![x - 1]
                }
                
                for y in 0 ..< _height {
                    imageHistogram![x][y] /= imageHistogram![x][_height - 1]
                }
            }
            
            for x in 0 ..< _width {
                colHistogram![x] /= colHistogram![_width - 1]
            }
            
            jacobian = (2 * Float.pi * Float.pi) / Float((b!.getWidth() * b!.getHeight()))
            
            self.colHistogram = colHistogram
            self.imageHistogram = imageHistogram
        }

        //  take fixed samples
        if pl.getBool(ImageBasedLightParameter.PARAM_FIXED, samples != nil)! {
            //  high density samples
            samples = [Vector3](repeating: Vector3(), count: Int(numSamples))
            
            colors = [Color](repeating: Color(), count: Int(numSamples))
            
            generateFixedSamples(&(samples!), &(colors!))

            //  low density samples
            lowSamples = [Vector3](repeating: Vector3(), count: Int(numLowSamples))
            
            lowColors = [Color](repeating: Color(), count: Int(numLowSamples))
            
            generateFixedSamples(&(lowSamples!), &(lowColors!))
        } else {
            //  turn off
            samples = nil
            lowSamples = nil
            colors = nil
            lowColors = nil
        }

        t.end()

        UI.printDetailed(.IMG, "  * IBL histogram creation time:  \(t.toString())")
        
        return true
    }

    func generateFixedSamples(_ samples: inout [Vector3], _ colors: inout [Color]) {
        for i in 0 ..< samples.count {
            let randX: Double = Double(i) / Double(samples.count)
            let randY: Double = QMC.halton(0, Int32(i))
            var x: Int = 0
            
            while (randX >= Double(colHistogram![x]) && x < colHistogram!.count - 1) {
                x += 1
            }
            
            let rowHistogram: [Float] = imageHistogram![x]
            var y: Int = 0
            
            while (randY >= Double(rowHistogram[y]) && y < rowHistogram.count - 1) {
                y += 1
            }
            
            //  sample from (x, y)
            let u: Float = x == 0 ? Float(randX / Double(colHistogram![0])) : Float(randX - Double(colHistogram![x - 1])) / (colHistogram![x] - colHistogram![x - 1])
            let v: Float = y == 0 ? Float(randY / Double(rowHistogram[0])) : Float(randY - Double(rowHistogram[y - 1])) / (rowHistogram[y] - rowHistogram[y - 1])
            
            let px: Float = x == 0 ? colHistogram![0] : colHistogram![x] - colHistogram![x - 1]
            let py: Float = y == 0 ? rowHistogram[0] : rowHistogram[y] - rowHistogram[y - 1]
            
            let su: Float = (Float(x) + u) / Float(colHistogram!.count)
            let sv: Float = (Float(y) + v) / Float(rowHistogram.count)
            
            let invP: Float = Float(sin(sv * Float.pi)) * jacobian / (Float(numSamples) * px * py)
            
            samples[i] = getDirection(su, sv)
            
            basis!.transform(samples[i])
            
            colors[i] = texture!.getPixel(su, sv).mul(invP)
        }
    }

    func prepareShadingState(_ state: ShadingState) {
        if state.includeLights {
            state.setShader(self)
        }
    }

    func intersectPrimitive(_ r: Ray, _: Int32, _ state: IntersectionState) {
        if r.getMax() == Float.infinity {
            state.setIntersection(0)
        }
    }

    func getNumPrimitives() -> Int32 {
        return 1
    }

    func getPrimitiveBound(_: Int32, _: Int32) -> Float {
        return 0
    }

    func getWorldBounds(_ o2w: AffineTransform?) -> BoundingBox? {
        return nil
    }

    func getBakingPrimitives() -> PrimitiveList? {
        return nil
    }

    func getNumSamples() -> Int32 {
        return numSamples
    }

    func getSamples(_ state: ShadingState) {
        if samples == nil {
            let n: Int32 = state.getDiffuseDepth() > 0 ? 1 : numSamples
            
            for i in 0 ..< n {
                //  random offset on unit square, we use the infinite version of
                //  getRandom because the light sampling is adaptive
                let randX: Double = state.getRandom(i, 0, n)
                let randY: Double = state.getRandom(i, 1, n)
                var x: Int = 0
                
                while (randX >= Double(colHistogram![x]) && x < colHistogram!.count - 1) {
                    x += 1
                }
                
                let rowHistogram: [Float] = imageHistogram![x]
                var y: Int = 0
                
                while (randY >= Double(rowHistogram[y]) && y < rowHistogram.count - 1) {
                    y += 1
                }
                
                //  sample from (x, y)
                let u: Float = x == 0 ? Float(randX / Double(colHistogram![0])) : Float(randX - Double(colHistogram![x - 1])) / (colHistogram![x] - colHistogram![x - 1])
                let v: Float = y == 0 ? Float(randY / Double(rowHistogram[0])) : Float(randY - Double(rowHistogram[y - 1])) / (rowHistogram[y] - rowHistogram[y - 1])
                
                let px: Float = x == 0 ? colHistogram![0] : colHistogram![x] - colHistogram![x - 1]
                let py: Float = y == 0 ? rowHistogram[0] : rowHistogram[y] - rowHistogram[y - 1]
                
                let su: Float = (Float(x) + u) / Float(colHistogram!.count)
                let sv: Float = (Float(y) + v) / Float(rowHistogram.count)
                
                let invP: Float = Float(sin(sv * Float.pi)) * jacobian / (Float(n) * px * py)
                
                let dir: Vector3 = getDirection(su, sv)
                
                basis!.transform(dir)
                
                if Vector3.dot(dir, state.getGeoNormal()!) > 0 {
                    let dest: LightSample = LightSample()
                    
                    dest.setShadowRay(Ray(state.getPoint(), dir))
                    
                    dest.getShadowRay().setMax(Float.greatestFiniteMagnitude)
                    
                    let radiance: Color = texture!.getPixel(su, sv)
                    
                    dest.setRadiance(radiance, radiance)
                    
                    dest.getDiffuseRadiance().mul(invP)
                    
                    dest.getSpecularRadiance().mul(invP)
                    
                    dest.traceShadow(state)
                    
                    state.addSample(dest)
                }
            }
        } else {
            if state.getDiffuseDepth() > 0 {
                for i in 0 ..< numLowSamples {
                    if (Vector3.dot(lowSamples![Int(i)], state.getGeoNormal()!) > 0) && (Vector3.dot(lowSamples![Int(i)], state.getNormal()!) > 0) {
                        let dest: LightSample = LightSample()
                        
                        dest.setShadowRay(Ray(state.getPoint(), lowSamples![Int(i)]))
                        
                        dest.getShadowRay().setMax(Float.greatestFiniteMagnitude)
                        
                        dest.setRadiance(lowColors![Int(i)], lowColors![Int(i)])
                        
                        dest.traceShadow(state)
                        
                        state.addSample(dest)
                    }
                }
            } else {
                for i in 0 ..< numSamples {
                    if (Vector3.dot(samples![Int(i)], state.getGeoNormal()!) > 0) && (Vector3.dot(samples![Int(i)], state.getNormal()!) > 0) {
                        let dest: LightSample = LightSample()
                        
                        dest.setShadowRay(Ray(state.getPoint(), samples![Int(i)]))
                        
                        dest.getShadowRay().setMax(Float.greatestFiniteMagnitude)
                        
                        dest.setRadiance(colors![Int(i)], colors![Int(i)])
                        
                        dest.traceShadow(state)
                        
                        state.addSample(dest)
                    }
                }
            }
        }
    }

    func getPhoton(_: Double, _: Double, _: Double, _: Double, _: Point3, _: Vector3, _: Color) {}

    func getRadiance(_ state: ShadingState) -> Color {
        //  lookup texture based on ray direction
        return state.includeLights ? getColor(basis!.untransform(state.getRay()!.getDirection(), Vector3())) : Color.BLACK
    }

    func getColor(_ dir: Vector3) -> Color {
        var u: Float
        var v: Float
        
        // assume lon/lat format
        var phi: Double = 0
        var theta: Double = 0
        
        phi = Double(acos(dir.y))
        
        theta = Double(atan2(dir.z, dir.x))
        
        u = Float(0.5 - 0.5 * theta / Double.pi)
        v = Float(phi / Double.pi)
        
        return texture!.getPixel(u, v)
    }

    func getDirection(_ u: Float, _ v: Float) -> Vector3 {
        let dest: Vector3 = Vector3()
        var phi: Double = 0
        var theta: Double = 0
        
        theta = Double(u) * 2 * Double.pi
        
        phi = Double(v) * Double.pi
        
        let sin_phi: Double = sin(phi)
        
        dest.x = Float(-sin_phi * cos(theta))
        dest.y = Float(cos(phi))
        dest.z = Float(sin_phi * sin(theta))
        
        return dest
    }

    func scatterPhoton(_: ShadingState, _: Color) {}

    func getPower() -> Float {
        return 0
    }

    func createInstance() -> Instance? {
        return Instance.createTemporary(self, nil, self)
    }
}
