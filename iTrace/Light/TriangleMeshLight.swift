//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class TriangleMeshLight: TriangleMesh, Shader, LightSource {
    var radiance: Color?
    var numSamples: Int32 = 0
    var areas: [Float]?
    var totalArea: Float = 0.0
    var ngs: [Vector3]?

    required init() {
        radiance = Color.WHITE
        
        numSamples = 4
    }

    override func update(_ pl: ParameterList) -> Bool {
        radiance = pl.getColor("radiance", radiance)
        
        numSamples = pl.getInt("samples", numSamples)!
        
        if super.update(pl) {
            //  precompute triangle areas and normals
            areas = [Float](repeating: 0, count: Int(getNumPrimitives()))
            
            ngs = [Vector3](repeating: Vector3(), count: Int(getNumPrimitives()))
            
            totalArea = 0
            
            var tri3: Int32 = 0
            var i: Int32 = 0
            
            while tri3 < triangles!.count {
                let a: Int32 = triangles![Int(tri3) + 0]
                let b: Int32 = triangles![Int(tri3) + 1]
                let c: Int32 = triangles![Int(tri3) + 2]
                
                let v0p: Point3 = getPoint(a)
                let v1p: Point3 = getPoint(b)
                let v2p: Point3 = getPoint(c)
                
                ngs![Int(i)] = Point3.normal(v0p, v1p, v2p)
                
                areas![Int(i)] = 0.5 * ngs![Int(i)].length
                
                ngs![Int(i)].normalize()
                
                totalArea = totalArea + areas![Int(i)]
                
                tri3 += 3
                
                i += 1
            }
        } else {
            return false
        }
        
        return true
    }

    func intersectTriangleKensler(_ tri3: Int32, _ r: Ray) -> Bool {
        let a: Int32 = 3 * triangles![Int(tri3) + 0]
        let b: Int32 = 3 * triangles![Int(tri3) + 1]
        let c: Int32 = 3 * triangles![Int(tri3) + 2]
        let edge0x: Float = points![Int(b) + 0] - points![Int(a) + 0]
        let edge0y: Float = points![Int(b) + 1] - points![Int(a) + 1]
        let edge0z: Float = points![Int(b) + 2] - points![Int(a) + 2]
        let edge1x: Float = points![Int(a) + 0] - points![Int(c) + 0]
        let edge1y: Float = points![Int(a) + 1] - points![Int(c) + 1]
        let edge1z: Float = points![Int(a) + 2] - points![Int(c) + 2]
        let nx: Float = (edge0y * edge1z) - (edge0z * edge1y)
        let ny: Float = (edge0z * edge1x) - (edge0x * edge1z)
        let nz: Float = (edge0x * edge1y) - (edge0y * edge1x)
        let v: Float = r.dot(nx, ny, nz)
        let iv: Float = 1 / v
        let edge2x: Float = points![Int(a) + 0] - r.ox
        let edge2y: Float = points![Int(a) + 1] - r.oy
        let edge2z: Float = points![Int(a) + 2] - r.oz
        let va: Float = (nx * edge2x) + (ny * edge2y) + (nz * edge2z)
        let t: Float = iv * va
        
        if t <= 0 {
            return false
        }
        
        let ix: Float = (edge2y * r.dz) - (edge2z * r.dy)
        let iy: Float = (edge2z * r.dx) - (edge2x * r.dz)
        let iz: Float = (edge2x * r.dy) - (edge2y * r.dx)
        let v1: Float = (ix * edge1x) + (iy * edge1y) + (iz * edge1z)
        let beta: Float = iv * v1
        
        if beta < 0 {
            return false
        }
        
        let v2: Float = (ix * edge0x) + (iy * edge0y) + (iz * edge0z)
        
        if (v1 + v2) * v > v * v {
            return false
        }
        
        let gamma: Float = iv * v2
        
        if gamma < 0 {
            return false
        }
        
        //  FIXME: arbitrary bias, should handle as in other places
        r.setMax(t - 1e-3)
        
        return true
    }

    func getRadiance(_ state: ShadingState) -> Color {
        if !state.includeLights {
            return Color.BLACK
        }
        
        state.faceforward()
        
        //  emit constant radiance
        return state.isBehind() ? Color.BLACK : radiance!
    }

    func scatterPhoton(_ state: ShadingState, _ power: Color) {
        //  do not scatter photons
    }

    func createInstance() -> Instance? {
        return Instance.createTemporary(self, nil, self)
    }

    func getNumSamples() -> Int32 {
        return numSamples * getNumPrimitives()
    }

    func getPhoton(_ randX1: Double, _ randY1: Double, _ randX2: Double, _ randY2: Double, _ p: Point3, _ dir: Vector3, _ power: Color) {
        var rnd: Double = randX1 * Double(totalArea)
        var j: Int32 = Int32(areas!.count - 1)
        
        for i in 0 ..< areas!.count {
            if rnd < Double(areas![i]) {
                j = Int32(i)
                
                break
            }
            
            rnd -= Double(areas![i]) //  try next triangle
        }
        
        rnd /= Double(areas![Int(j)])
        
        let _randX1 = rnd
        
        var s: Double = sqrt(1 - randX2)
        var u: Float = Float(randY2 * s)
        let v: Float = 1 - Float(s)
        let w: Float = 1 - u - v
        let tri3: Int32 = j * 3
        
        let index0: Int32 = 3 * triangles![Int(tri3) + 0]
        let index1: Int32 = 3 * triangles![Int(tri3) + 1]
        let index2: Int32 = 3 * triangles![Int(tri3) + 2]
        
        p.x = w * points![Int(index0) + 0] + u * points![Int(index1) + 0] + v * points![Int(index2) + 0]
        p.y = w * points![Int(index0) + 1] + u * points![Int(index1) + 1] + v * points![Int(index2) + 1]
        p.z = w * points![Int(index0) + 2] + u * points![Int(index1) + 2] + v * points![Int(index2) + 2]
        
        p.x += 0.001 * ngs![Int(j)].x
        p.y += 0.001 * ngs![Int(j)].y
        p.z += 0.001 * ngs![Int(j)].z
        
        let onb: OrthoNormalBasis = OrthoNormalBasis.makeFromW(ngs![Int(j)])
        
        u = 2 * Float.pi * Float(_randX1)
        
        s = sqrt(randY1)
        
        onb.transform(Vector3(cos(u) * Float(s), sin(u) * Float(s), sqrt(1 - Float(randY1))), dir)
        
        power.set(Color.mul(Float.pi * areas![Int(j)], radiance!))
    }

    func getPower() -> Float {
        return radiance!.copy().mul(Float.pi * totalArea).getLuminance()
    }

    func getSamples(_ state: ShadingState) {
        if numSamples == 0 {
            return
        }
        
        let n: Vector3 = state.getNormal()!
        let p: Point3 = state.getPoint()
        
        var tri3: Int32 = 0
        var i: Int32 = 0
        
        while tri3 < triangles!.count {
            //  vector towards each vertex of the light source
            let p0: Vector3 = Point3.sub(getPoint(triangles![Int(tri3) + 0]), p)
            
            //  cull triangle if it is facing the wrong way
            if Vector3.dot(p0, ngs![Int(i)]) >= 0 {
                continue
            }
            
            let p1: Vector3 = Point3.sub(getPoint(triangles![Int(tri3) + 1]), p)
            let p2: Vector3 = Point3.sub(getPoint(triangles![Int(tri3) + 2]), p)
            
            //  if all three vertices are below the hemisphere, stop
            if (Vector3.dot(p0, n) <= 0) && (Vector3.dot(p1, n) <= 0) && (Vector3.dot(p2, n) <= 0) {
                continue
            }
            
            p0.normalize()
            p1.normalize()
            p2.normalize()
            
            var dot: Float = Vector3.dot(p2, p0)
            let h: Vector3 = Vector3()
            
            h.x = p2.x - dot * p0.x
            h.y = p2.y - dot * p0.y
            h.z = p2.z - dot * p0.z
            
            let hlen: Float = h.length
            
            if hlen > 1e-6 {
                h.div(hlen)
            } else {
                continue
            }
            
            let n0: Vector3 = Vector3.cross(p0, p1)
            let len0: Float = n0.length
            
            if len0 > 1e-6 {
                n0.div(len0)
            } else {
                continue
            }
            
            let n1: Vector3 = Vector3.cross(p1, p2)
            let len1: Float = n1.length
            
            if len1 > 1e-6 {
                n1.div(len1)
            } else {
                continue
            }
            
            let n2: Vector3 = Vector3.cross(p2, p0)
            let len2: Float = n2.length
            
            if len2 > 1e-6 {
                n2.div(len2)
            } else {
                continue
            }
            
            let cosAlpha: Float = (-Vector3.dot(n2, n0)).clamp(-1.0, 1.0)
            let cosBeta: Float = (-Vector3.dot(n0, n1)).clamp(-1.0, 1.0)
            let cosGamma: Float = (-Vector3.dot(n1, n2)).clamp(-1.0, 1.0)
           
            let alpha: Float = acos(cosAlpha)
            let beta: Float = acos(cosBeta)
            let gamma: Float = acos(cosGamma)
            
            let area: Float = (alpha + beta + gamma) - Float.pi
            
            let cosC: Float = (Vector3.dot(p0, p1)).clamp(-1.0, 1.0)
            let salpha: Float = sin(alpha)
            let product: Float = salpha * cosC
            
            //  use lower sampling depth for diffuse bounces
            let samples: Int32 = state.getDiffuseDepth() > 0 ? 1 : numSamples
            let c: Color = Color.mul(area / Float(samples), radiance!)
            
            for j in 0 ..< samples {
                //  random offset on unit square
                let randX: Double = state.getRandom(j, 0, samples)
                let randY: Double = state.getRandom(j, 1, samples)
                
                let phi: Float = ((Float(randX) * area) - alpha) + Float.pi
                let sinPhi: Float = sin(phi)
                let cosPhi: Float = cos(phi)
                
                let u: Float = cosPhi + cosAlpha
                let v: Float = sinPhi - product
                
                let q: Float = (-v + (cosAlpha * ((cosPhi * -v) + (sinPhi * u)))) / (salpha * ((sinPhi * -v) - (cosPhi * u)))
                var q1: Float = 1.0 - (q * q)
                
                if q1 < 0.0 {
                    q1 = 0.0
                }
                
                let sqrtq1: Float = sqrt(q1)
                let ncx: Float = q * p0.x + sqrtq1 * h.x
                let ncy: Float = q * p0.y + sqrtq1 * h.y
                let ncz: Float = q * p0.z + sqrtq1 * h.z
                
                dot = p1.dot(ncx, ncy, ncz)
                
                let z: Float = 1.0 - (Float(randY) * (1.0 - dot))
                var z1: Float = 1.0 - (z * z)
                
                if z1 < 0.0 {
                    z1 = 0.0
                }
                
                let nd: Vector3 = Vector3()
                
                nd.x = ncx - dot * p1.x
                nd.y = ncy - dot * p1.y
                nd.z = ncz - dot * p1.z
                
                nd.normalize()
                
                let sqrtz1: Float = sqrt(z1)
                let result: Vector3 = Vector3()
                
                result.x = z * p1.x + sqrtz1 * nd.x
                result.y = z * p1.y + sqrtz1 * nd.y
                result.z = z * p1.z + sqrtz1 * nd.z
                
                //  make sure the sample is in the right hemisphere - facing in
                //  the right direction
                if (Vector3.dot(result, n) > 0) && (Vector3.dot(result, state.getGeoNormal()!) > 0) && (Vector3.dot(result, ngs![Int(i)]) < 0) {
                    //  compute intersection with triangle (if any)
                    let shadowRay: Ray = Ray(state.getPoint(), result)
                    
                    if !intersectTriangleKensler(tri3, shadowRay) {
                        continue
                    }
                    
                    let dest: LightSample = LightSample()
                    
                    dest.setShadowRay(shadowRay)
                    
                    //  prepare sample
                    dest.setRadiance(c, c)
                    
                    dest.traceShadow(state)
                    
                    state.addSample(dest)
                }
            }
            
            tri3 += 3
            
            i += 1
        }
    }
}
