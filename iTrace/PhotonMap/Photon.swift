//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class Photon {
    var x: Float = 0.0
    var y: Float = 0.0
    var z: Float = 0.0
    var dir: Int16 = 0
    var normal: Int16 = 0
    var data: Int32 = 0
    var power: Int32 = 0
    var flags: Int32 = 0
    
    static let SPLIT_X: Int32 = 0
    static let SPLIT_Y: Int32 = 1
    static let SPLIT_Z: Int32 = 2
    static let SPLIT_MASK: Int32 = 3

    init(_ p: Point3, _ dir: Vector3, _ power: Color) {
        x = p.x
        y = p.y
        z = p.z
        
        self.dir = dir.encode()
        
        self.power = power.toRGBE()
        
        flags = Self.SPLIT_X
    }

    init(_ p: Point3, _ n: Vector3, _ dir: Vector3, _ power: Color, _ diffuse: Color) {
        x = p.x
        y = p.y
        z = p.z
        
        self.dir = dir.encode()
        
        self.power = power.toRGBE()
        
        flags = Self.SPLIT_X
        
        normal = n.encode()
        
        data = diffuse.toRGB()
    }
    
    func setSplitAxis(_ axis: Int32) {
        flags &= ~Self.SPLIT_MASK
        
        flags |= axis
    }

    func getCoord(_ axis: Int32) -> Float {
        switch axis {
            case Self.SPLIT_X:
                return x
            case Self.SPLIT_Y:
                return y
            default:
                return z
        }
    }

    func getDist1(_ px: Float, _ py: Float, _ pz: Float) -> Float {
        switch flags & Self.SPLIT_MASK {
            case Self.SPLIT_X:
                return px - x
            case Self.SPLIT_Y:
                return py - y
            default:
                return pz - z
        }
    }

    func getDist2(_ px: Float, _ py: Float, _ pz: Float) -> Float {
        let dx: Float = x - px
        let dy: Float = y - py
        let dz: Float = z - pz
        
        return (dx * dx) + (dy * dy) + (dz * dz)
    }
}

final class NearestPhotons {
    var found: Int32 = 0
    var max: Int32 = 0
    var gotHeap: Bool = false
    var dist2: [Float]
    var index: [Photon?]
    var px: Float = 0.0
    var py: Float = 0.0
    var pz: Float = 0.0

    init(_ p: Point3, _ n: Int32, _ maxDist2: Float) {
        max = n
        
        found = 0
        
        gotHeap = false
        
        px = p.x
        py = p.y
        pz = p.z
        
        dist2 = [Float](repeating: 0, count: Int(n) + 1)
        
        index = [Photon?](repeating: nil, count: Int(n) + 1)
        
        dist2[0] = maxDist2
    }

    func reset(_ p: Point3, _ maxDist2: Float) {
        found = 0
        
        gotHeap = false
        
        px = p.x
        py = p.y
        pz = p.z
        
        dist2[0] = maxDist2
    }

    func checkAddNearest(_ p: Photon) {
        let fdist2: Float = p.getDist2(px, py, pz)
        
        if fdist2 < dist2[0] {
            if found < max {
                found += 1
                
                dist2[Int(found)] = fdist2
                
                index[Int(found)] = p
            } else {
                var j: Int32
                var parent: Int32
                
                if !gotHeap {
                    var dst2: Float
                    var phot: Photon
                    let halfFound: Int32 = found >> 1
                    var k: Int32 = halfFound
                    
                    while k >= 1 {
                        parent = k
                        
                        phot = index[Int(k)]!
                        
                        dst2 = dist2[Int(k)]
                        
                        while parent <= halfFound {
                            j = parent + parent
                            
                            if (j < found) && (dist2[Int(j)] < dist2[Int(j) + 1]) {
                                j += 1
                            }
                            
                            if dst2 >= dist2[Int(j)] {
                                break
                            }
                            
                            dist2[Int(parent)] = dist2[Int(j)]
                            
                            index[Int(parent)] = index[Int(j)]
                            
                            parent = j
                        }
                        
                        dist2[Int(parent)] = dst2
                        
                        index[Int(parent)] = phot
                        
                        k -= 1
                    }
                    
                    gotHeap = true
                }
                
                parent = 1
                
                j = 2
                
                while j <= found {
                    if (j < found) && (dist2[Int(j)] < dist2[Int(j) + 1]) {
                        j += 1
                    }
                    
                    if fdist2 > dist2[Int(j)] {
                        break
                    }
                    
                    dist2[Int(parent)] = dist2[Int(j)]
                    
                    index[Int(parent)] = index[Int(j)]
                    
                    parent = j
                    
                    j += j
                }
                
                dist2[Int(parent)] = fdist2
                
                index[Int(parent)] = p
                
                dist2[0] = dist2[1]
            }
        }
    }
}
