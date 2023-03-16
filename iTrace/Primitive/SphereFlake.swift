//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class SphereFlake: PrimitiveList {
    static var MAX_LEVEL: Int32 = 20
    static var boundingRadiusOffset: [Float] = [Float](repeating: 0, count: Int(MAX_LEVEL) + 1)
    static var recursivePattern: [Float] = [Float](repeating: 0, count: 9 * 3)
    
    var level: Int32 = 2
    var axis: Vector3? = Vector3(0, 0, 1)
    var baseRadius: Float = 1

    required init() {
        var r = 3
        
        //  geometric series table, to compute bounding radius quickly
        for i in 0 ..< Self.boundingRadiusOffset.count {
            Self.boundingRadiusOffset[Int(i)] = (Float(r) - 3.0) / Float(r)
            
            r *= 3
        }
        
        var a: Double = 0
        let daL: Double = 2 * Double.pi / 6
        let daU: Double = 2 * Double.pi / 3
        
        for i in 0 ..< 6 {
            Self.recursivePattern[(3 * i) + 0] = -0.3
            Self.recursivePattern[(3 * i) + 1] = Float(sin(a))
            Self.recursivePattern[(3 * i) + 2] = Float(cos(a))
            
            a += daL
        }
        
        a -= daL / 2 //  tweak
        
        for i in 6 ..< 9 {
            Self.recursivePattern[(3 * i) + 0] = +0.7
            Self.recursivePattern[(3 * i) + 1] = Float(sin(a))
            Self.recursivePattern[(3 * i) + 2] = Float(cos(a))
            
            a = a + daU
        }
        
        var i: Int32 = 0
        
        while i < Self.recursivePattern.count {
            let x: Float = Self.recursivePattern[Int(i) + 0]
            let y: Float = Self.recursivePattern[Int(i) + 1]
            let z: Float = Self.recursivePattern[Int(i) + 2]
            
            let n: Float = 1 / sqrt(x * x + y * y + z * z)
            
            Self.recursivePattern[Int(i) + 0] = x * n
            Self.recursivePattern[Int(i) + 1] = y * n
            Self.recursivePattern[Int(i) + 2] = z * n
            
            i += 3
        }
    }

    func update(_ pl: ParameterList) -> Bool {
        level = (pl.getInt("level", level)!).clamp(0, 20)
        
        axis = pl.getVector("axis", axis)
        
        axis!.normalize()
        
        baseRadius = abs(pl.getFloat("radius", baseRadius)!)
        
        return true
    }

    func getWorldBounds(_ o2w: AffineTransform?) -> BoundingBox? {
        var bounds: BoundingBox? = BoundingBox(getPrimitiveBound(0, 1))
        
        if o2w != nil {
            bounds = o2w!.transform(bounds!)
        }
        
        return bounds
    }

    func getPrimitiveBound(_: Int32, _ i: Int32) -> Float {
        let br: Float = 1 + Self.boundingRadiusOffset[Int(level)]
        
        return (i & 1) == 0 ? -br : br
    }

    func getNumPrimitives() -> Int32 {
        return 1
    }

    func prepareShadingState(_ state: ShadingState) {
        state.initState()
        
        state.getRay()!.getPoint(state.getPoint())
        
        let parent: Instance? = state.getInstance()
        
        let localPoint: Point3? = state.transformWorldToObject(state.getPoint())
        
        let cx: Float = state.getU()
        let cy: Float = state.getV()
        let cz: Float = state.getW()
        
        state.getNormal()!.set(localPoint!.x - cx, localPoint!.y - cy, localPoint!.z - cz)
        
        state.getNormal()!.normalize()
        
        var phi: Float = atan2(state.getNormal()!.y, state.getNormal()!.x)
        
        if phi < 0 {
            phi += 2.0 * Float.pi
        }
        
        let theta: Float = acos(state.getNormal()!.z)
        
        state.getUV()!.y = theta / Float.pi
        state.getUV()!.x = phi / (2 * Float.pi)
        
        var v: Vector3 = Vector3()
        
        v.x = -2 * Float.pi * state.getNormal()!.y
        v.y = 2 * Float.pi * state.getNormal()!.x
        v.z = 0
        
        state.setShader(parent!.getShader(0))
        
        state.setModifier(parent!.getModifier(0))
        
        //  into world space
        let worldNormal: Vector3 = state.transformNormalObjectToWorld(state.getNormal()!)
        
        v = state.transformVectorObjectToWorld(v)
        
        state.getNormal()!.set(worldNormal)
        
        state.getNormal()!.normalize()
        
        state.getGeoNormal()!.set(state.getNormal()!)
        
        //  compute basis in world space
        state.setBasis(OrthoNormalBasis.makeFromWV(state.getNormal()!, v))
    }

    func intersectPrimitive(_ r: Ray, _: Int32, _ state: IntersectionState) {
        //  intersect in local space
        let qa: Float = r.dx * r.dx + r.dy * r.dy + r.dz * r.dz
        
        intersectFlake(r, state, level, qa, 1 / qa, 0, 0, 0, axis!.x, axis!.y, axis!.z, baseRadius)
    }

    func intersectFlake(_ r: Ray, _ state: IntersectionState, _ level: Int32, _ qa: Float, _ qaInv: Float, _ cx: Float, _ cy: Float, _ cz: Float, _ dx: Float, _ dy: Float, _ dz: Float, _ radius: Float) {
        if level <= 0 {
            //  we reached the bottom - intersect sphere and bail out
            let vcx: Float = cx - r.ox
            let vcy: Float = cy - r.oy
            let vcz: Float = cz - r.oz
            
            let b: Float = r.dx * vcx + r.dy * vcy + r.dz * vcz
            let disc: Float = b * b - qa * ((vcx * vcx + vcy * vcy + vcz * vcz) - radius * radius)
            
            if disc > 0 {
                //  intersects - check t values
                let d: Float = sqrt(disc)
                let t1: Float = (b - d) * qaInv
                let t2: Float = (b + d) * qaInv
                
                if (t1 >= r.getMax()) || (t2 <= r.getMin()) {
                    return
                }
                
                if t1 > r.getMin() {
                    r.setMax(t1)
                } else {
                    r.setMax(t2)
                }
                
                state.setIntersection(0, cx, cy, cz)
            }
        } else {
            let boundRadius: Float = radius * (1 + SphereFlake.boundingRadiusOffset[Int(level)])
            
            let vcx: Float = cx - r.ox
            let vcy: Float = cy - r.oy
            let vcz: Float = cz - r.oz
            
            let b: Float = r.dx * vcx + r.dy * vcy + r.dz * vcz
            let vcd: Float = (vcx * vcx + vcy * vcy + vcz * vcz)
            var disc: Float = b * b - qa * (vcd - boundRadius * boundRadius)
            
            if disc > 0 {
                //  intersects - check t values
                var d: Float = sqrt(disc)
                var t1: Float = (b - d) * qaInv
                var t2: Float = (b + d) * qaInv
                
                if (t1 >= r.getMax()) || (t2 <= r.getMin()) {
                    return
                }
                
                //  we hit the bounds, now compute intersection with the actual
                //  leaf sphere
                disc = b * b - qa * (vcd - radius * radius)
                
                if disc > 0 {
                    d = sqrt(disc)
                    
                    t1 = (b - d) * qaInv
                    t2 = (b + d) * qaInv
                    
                    if (t1 >= r.getMax()) || (t2 <= r.getMin()) {
                        //  no hit
                    } else {
                        if t1 > r.getMin() {
                            r.setMax(t1)
                        } else {
                            r.setMax(t2)
                        }
                        
                        state.setIntersection(0, cx, cy, cz)
                    }
                }
                
                var b1x: Float
                var b1y: Float
                var b1z: Float
                
                if (dx * dx < dy * dy && dx * dx < dz * dz) {
                    b1x = 0
                    b1y = dz
                    b1z = -dy
                } else {
                    if (dy * dy < dz * dz) {
                        b1x = dz
                        b1y = 0
                        b1z = -dx
                    } else {
                        b1x = dy
                        b1y = -dx
                        b1z = 0
                    }
                }
                
                let n: Float = 1 / sqrt(b1x * b1x + b1y * b1y + b1z * b1z)
                
                b1x *= n
                b1y *= n
                b1z *= n
                
                let b2x: Float = dy * b1z - dz * b1y
                let b2y: Float = dz * b1x - dx * b1z
                let b2z: Float = dx * b1y - dy * b1x
                
                b1x = dy * b2z - dz * b2y
                b1y = dz * b2x - dx * b2z
                b1z = dx * b2y - dy * b2x
                
                // step2: generate 9 children recursively
                let nr: Float = radius * (1 / 3.0)
                let scale: Float = radius + nr
                
                var i: Int32 = 0
                
                while i < (9 * 3) {
                    //  transform by basis
                    let ndx: Float = Self.recursivePattern[Int(i)] * dx + Self.recursivePattern[Int(i + 1)] * b1x + Self.recursivePattern[Int(i + 2)] * b2x
                    let ndy: Float = Self.recursivePattern[Int(i)] * dy + Self.recursivePattern[Int(i + 1)] * b1y + Self.recursivePattern[Int(i + 2)] * b2y
                    let ndz: Float = Self.recursivePattern[Int(i)] * dz + Self.recursivePattern[Int(i + 1)] * b1z + Self.recursivePattern[Int(i + 2)] * b2z
                    
                    //  recurse
                    intersectFlake(r, state, level - 1, qa, qaInv, cx + scale * ndx, cy + scale * ndy, cz + scale * ndz, ndx, ndy, ndz, nr)
                    
                    i += 3
                }
            }
        }
    }

    func getBakingPrimitives() -> PrimitiveList? {
        return nil
    }
}
