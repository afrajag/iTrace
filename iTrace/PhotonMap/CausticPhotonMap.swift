//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

import Foundation

final class CausticPhotonMap: CausticPhotonMapInterface {
    var photonList: [Photon?]?
    var photons: [Photon?]?
    var storedPhotons: Int32 = 0
    var halfStoredPhotons: Int32 = 0
    var log2n: Int32 = 0
    var gatherNum: Int32 = 0
    var gatherRadius: Float = 0.0
    var bounds: BoundingBox?
    var filterValue: Float = 0.0
    var maxPower: Float = 0.0
    var maxRadius: Float = 0.0
    var _numEmit: Int32 = 0

    let lockQueue = DispatchQueue(label: "causticphotonmap.lock.serial.queue")

    required init() {}
    
    func prepare(_ options: Options, _ sceneBounds: BoundingBox) {
        //  get options
        _numEmit = options.getInt("caustics.emit", 10000)!
        gatherNum = options.getInt("caustics.gather", 50)!
        gatherRadius = options.getFloat("caustics.radius", 0.5)!
        filterValue = options.getFloat("caustics.filter", 1.1)!
        
        bounds = BoundingBox()
        
        //  init
        maxPower = 0
        maxRadius = 0
        
        photonList = [Photon?]()
        
        photonList!.append(nil)
        
        photons = nil
        
        storedPhotons = 0
        halfStoredPhotons = 0
    }

    func locatePhotons(_ np: NearestPhotons) {
        var dist1d2: [Float] = [Float](repeating: 0, count: Int(log2n))
        var chosen: [Int32] = [Int32](repeating: 0, count: Int(log2n))
        var i: Int32 = 1
        var level: Int32 = 0
        var cameFrom: Int32
        
        while true {
            while i < halfStoredPhotons {
                let dist1d: Float = photons![Int(i)]!.getDist1(np.px, np.py, np.pz)
                
                dist1d2[Int(level)] = dist1d * dist1d
                
                i += i
                
                if dist1d > 0.0 {
                    i += 1
                }
                
                chosen[Int(level)] = i
                
                level += 1
            }
            
            np.checkAddNearest(photons![Int(i)]!)
            
            repeat {
                cameFrom = i
                
                i >>= 1
                
                level -= 1
                
                if i == 0 {
                    return
                }
            } while (dist1d2[Int(level)] >= np.dist2[0]) || (cameFrom != chosen[Int(level)])
            
            np.checkAddNearest(photons![Int(i)]!)
            
            i = chosen[Int(level)] ^ 1
            
            level += 1
        }
    }

    func balance() {
        if storedPhotons == 0 {
            return
        }
        
        photons = photonList
        
        photonList = nil
        
        var temp: [Photon?] = [Photon?](repeating: nil, count: Int(storedPhotons) + 1)
        
        balanceSegment(&temp, 1, 1, storedPhotons)
        
        photons = temp
  
        halfStoredPhotons = storedPhotons / 2
        
        log2n = Int32(ceil(log(Double(storedPhotons)) / log(2.0)))
    }

    func balanceSegment(_ temp: inout [Photon?], _ index: Int32, _ start: Int32, _ end: Int32) {
        var median: Int32 = 1
        
        while (4 * median) <= (end - start + 1) {
            median += median
        }
        
        if (3 * median) <= (end - start + 1) {
            median += median
            
            median += start - 1
        } else {
            median = end - median + 1
        }
        
        var axis: Int32 = Photon.SPLIT_Z
        let extents: Vector3 = bounds!.getExtents()
        
        if (extents.x > extents.y) && (extents.x > extents.z) {
            axis = Photon.SPLIT_X
        } else if extents.y > extents.z {
            axis = Photon.SPLIT_Y
        }
        
        var left: Int32 = start
        var right: Int32 = end
        
        while right > left {
            let v: Double = Double(photons![Int(right)]!.getCoord(axis))
            var i: Int32 = left - 1
            var j: Int32 = right
            
            while true {
                i += 1
                
                while photons![Int(i)]!.getCoord(axis) < Float(v) {
                    i += 1
                }
                
                j -= 1
                
                while (photons![Int(j)]!.getCoord(axis) > Float(v)) && (j > left) {
                    j -= 1
                }
                
                if i >= j {
                    break
                }
                
                // FIXME: controllare se si puo' togliere (utilizzato swapAt())
                //swap(i, j)
                photons!.swapAt(Int(i), Int(j))
            }
            
            // FIXME: controllare se si puo' togliere (utilizzato swapAt())
            //swap(i, right)
            photons!.swapAt(Int(i), Int(right))
            
            if i >= median {
                right = i - 1
            }
            
            if i <= median {
                left = i + 1
            }
        }
        
        temp[Int(index)] = photons![Int(median)]!
        
        temp[Int(index)]!.setSplitAxis(axis)
        
        if median > start {
            if start < (median - 1) {
                var tmp: Float
                
                switch axis {
                    case Photon.SPLIT_X:
                        tmp = bounds!.getMaximum().x
                        bounds!.getMaximum().x = temp[Int(index)]!.x
                        balanceSegment(&temp, 2 * index, start, median - 1)
                        bounds!.getMaximum().x = tmp
                    case Photon.SPLIT_Y:
                        tmp = bounds!.getMaximum().y
                        bounds!.getMaximum().y = temp[Int(index)]!.y
                        balanceSegment(&temp, 2 * index, start, median - 1)
                        bounds!.getMaximum().y = tmp
                    default:
                        tmp = bounds!.getMaximum().z
                        bounds!.getMaximum().z = temp[Int(index)]!.z
                        balanceSegment(&temp, 2 * index, start, median - 1)
                        bounds!.getMaximum().z = tmp
                }
            } else {
                temp[2 * Int(index)] = photons![Int(start)]!
            }
        }
        
        if median < end {
            if (median + 1) < end {
                var tmp: Float
                
                switch axis {
                    case Photon.SPLIT_X:
                        tmp = bounds!.getMinimum().x
                        bounds!.getMinimum().x = temp[Int(index)]!.x
                        balanceSegment(&temp, (2 * index) + 1, median + 1, end)
                        bounds!.getMinimum().x = tmp
                    case Photon.SPLIT_Y:
                        tmp = bounds!.getMinimum().y
                        bounds!.getMinimum().y = temp[Int(index)]!.y
                        balanceSegment(&temp, (2 * index) + 1, median + 1, end)
                        bounds!.getMinimum().y = tmp
                    default:
                        tmp = bounds!.getMinimum().z
                        bounds!.getMinimum().z = temp[Int(index)]!.z
                        balanceSegment(&temp, (2 * index) + 1, median + 1, end)
                        bounds!.getMinimum().z = tmp
                }
            } else {
                temp[(2 * Int(index)) + 1] = photons![Int(end)]!
            }
        }
    }

    // FIXME: controllare se si puo' togliere (utilizzato swapAt())
    func swap(_ i: Int32, _ j: Int32) {
        let tmp: Photon = photons![Int(i)]!
        
        photons![Int(i)] = photons![Int(j)]
        
        photons![Int(j)] = tmp
    }

    func store(_ state: ShadingState, _ dir: Vector3, _ power: Color, _ diffuse: Color) {
        if (((state.getDiffuseDepth() == 0) && (state.getReflectionDepth() > 0) || (state.getRefractionDepth() > 0))) {
            //  this is a caustic photon
            let p: Photon = Photon(state.getPoint(), dir, power)

            lockQueue.sync { // synchronized block
                storedPhotons += 1
                
                photonList!.append(p)
                
                bounds!.include(Point3(p.x, p.y, p.z))
                
                maxPower = max(maxPower, power.getMax())
            }
        }
    }

    func initStore() {
        UI.printInfo(.LIGHT, "Balancing caustics photon map ...")
        
        let t: TraceTimer = TraceTimer()
        
        t.start()
        
        balance()
        
        t.end()
        
        UI.printInfo(.LIGHT, "Caustic photon map:")
        UI.printInfo(.LIGHT, "  * Photons stored:   \(storedPhotons)" )
        UI.printInfo(.LIGHT, "  * Photons/estimate: \(gatherNum)" )
        
        maxRadius = 1.4 * sqrt(maxPower * Float(gatherNum))
        
        UI.printInfo(.LIGHT, "  * Estimate radius:  \(gatherRadius)" )
        UI.printInfo(.LIGHT, "  * Maximum radius:   \(maxRadius)" )
        UI.printInfo(.LIGHT, "  * Balancing time:   \(t.toString())")
        
        if gatherRadius > maxRadius {
            gatherRadius = maxRadius
        }
    }

    func getSamples(_ state: ShadingState) {
        if storedPhotons == 0 {
            return
        }
        
        let np: NearestPhotons = NearestPhotons(state.getPoint(), gatherNum, gatherRadius * gatherRadius)
        
        locatePhotons(np)
        
        if np.found < 8 {
            return
        }
        
        let ppos: Point3 = Point3()
        let pdir: Vector3 = Vector3()
        let pvec: Vector3 = Vector3()
        let invArea: Float = 1.0 / (Float.pi * np.dist2[0])
        let maxNDist: Float = np.dist2[0] * 0.05
        let f2r2: Float = 1.0 / (filterValue * filterValue * np.dist2[0])
        let fInv: Float = 1.0 / (1.0 - 2.0 / (3.0 * filterValue))
        
        for i in 1 ... np.found {
            let phot: Photon = np.index[Int(i)]!
            
            pdir.set(Vector3.decode(phot.dir))
            
            let cos: Float = -Vector3.dot(pdir, state.getNormal()!)
            
            if cos > 0.001 {
                ppos.set(phot.x, phot.y, phot.z)
                
                pvec.set(Point3.sub(ppos, state.getPoint()))
                
                let pcos: Float = Vector3.dot(pvec, state.getNormal()!)
                
                if (pcos < maxNDist) && (pcos > -maxNDist) {
                    let sample: LightSample = LightSample()
                    
                    sample.setShadowRay(Ray(state.getPoint(), pdir.negate()))
                    
                    sample.setRadiance(Color().setRGBE(np.index[Int(i)]!.power).mul(invArea / cos), Color.BLACK)
                    
                    sample.getDiffuseRadiance().mul((1.0 - sqrt(np.dist2[Int(i)] * f2r2)) * fInv)
                    
                    state.addSample(sample)
                }
            }
        }
    }

    func allowDiffuseBounced() -> Bool {
        return false
    }

    func allowReflectionBounced() -> Bool {
        return true
    }

    func allowRefractionBounced() -> Bool {
        return true
    }

    func numEmit() -> Int32 {
        return _numEmit
    }
}
