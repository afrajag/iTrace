//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

import Foundation

final class GridPhotonMap: GlobalPhotonMapInterface {
    var numGather: Int32 = 0
    var gatherRadius: Float = 0.0
    var numStoredPhotons: Int32 = 0
    var bounds: BoundingBox?
    var cellHash: [PhotonGroup?]?
    var hashSize: Int32 = 0
    var hashPrime: Int32 = 0
    var _numEmit: Int32 = 0
    
    static var NORMAL_THRESHOLD: Float = Float(cos((10.0 * Double.pi) / 180.0))
    static var PRIMES: [Int32] = [11, 19, 37, 109, 163, 251, 367, 557,
    823, 1237, 1861, 2777, 4177, 6247, 9371, 21089, 31627, 47431,
    71143, 106721, 160073, 240101, 360163, 540217, 810343, 1215497,
    1823231, 2734867, 4102283, 6153409, 9230113, 13845163]
    
    var nx: Int32 = 0
    var ny: Int32 = 0
    var nz: Int32 = 0

    let lockQueue = DispatchQueue(label: "gridphotonmap.lock.serial.queue")

    required init() {
        numStoredPhotons = 0
        
        hashSize = 0 //  number of unique IDs in the hash
        
        // FIXME: togliere questo tipo di commenti
        // rwl = new ReentrantReadWriteLock();
        _numEmit = 100000
    }

    func prepare(_ options: Options, _ sceneBounds: BoundingBox) {
        //  get settings
        _numEmit = options.getInt("gi.irr-cache.gmap.emit", 100000)!
        
        numGather = options.getInt("gi.irr-cache.gmap.gather", 50)!
        
        gatherRadius = options.getFloat("gi.irr-cache.gmap.radius", 0.5)!
        
        //  init
        bounds = BoundingBox(sceneBounds)
        
        bounds!.enlargeUlps()
        
        let w: Vector3 = bounds!.getExtents()
        
        nx = max(Int32((w.x / gatherRadius) + 0.5), 1)
        ny = max(Int32((w.y / gatherRadius) + 0.5), 1)
        nz = max(Int32((w.z / gatherRadius) + 0.5), 1)
        
        let numCells: Int32 = nx * ny * nz
        
        UI.printInfo(.LIGHT, "Initializing grid photon map:")
        UI.printInfo(.LIGHT, "  * Resolution:  \(nx)x\(ny)x\(nz)")
        UI.printInfo(.LIGHT, "  * Total cells: \(numCells)")
        
        while hashPrime < Self.PRIMES.count {
            hashPrime = 0
            
            if Self.PRIMES[Int(hashPrime)] > (numCells / 5) {
                break
            }
            
            hashPrime += 1
        }
        
        cellHash = [PhotonGroup?](repeating: nil, count: Int(Self.PRIMES[Int(hashPrime)]))
        
        UI.printInfo(.LIGHT, "  * Initial hash size: \(cellHash!.count)")
    }

    func size() -> Int32 {
        return numStoredPhotons
    }

    func store(_ state: ShadingState, _ dir: Vector3, _ power: Color, _ diffuse: Color) {
        //  don't store on the wrong side of a surface
        if Vector3.dot(state.getNormal()!, dir) > 0 {
            return
        }
        
        let pt: Point3 = state.getPoint()
        
        //  outside grid bounds
        if !bounds!.contains(pt) {
            return
        }
        
        let ext: Vector3 = bounds!.getExtents()
        
        var ix: Int32 = Int32((pt.x - bounds!.getMinimum().x)) * nx / Int32(ext.x)
        var iy: Int32 = Int32((pt.y - bounds!.getMinimum().y)) * ny / Int32(ext.y)
        var iz: Int32 = Int32((pt.z - bounds!.getMinimum().z)) * nz / Int32(ext.z)
        
        ix = ix.clamp(0, nx - 1)
        iy = iy.clamp(0, ny - 1)
        iz = iz.clamp(0, nz - 1)
        
        let id: Int32 = ix + iy * nx + iz * nx * ny

        lockQueue.sync { // synchronized block
            let hid: Int32 = id % Int32(cellHash!.count)
            var g: PhotonGroup? = cellHash![Int(hid)]
            var last: PhotonGroup? = nil
            var hasID: Bool = false
            
            while g != nil {
                if g!.id == id {
                    hasID = true
                    
                    if Vector3.dot(state.getNormal()!, g!.normal!) > Self.NORMAL_THRESHOLD {
                        break
                    }
                }
                
                last = g
                
                g = g?.next!
            }
            
            if g == nil {
                g = PhotonGroup(id, state.getNormal()!)
                
                if last == nil {
                    cellHash![Int(hid)] = g
                } else {
                    last!.next = g
                }
                
                if !hasID {
                    hashSize += 1 //  we have not seen this ID before
                    
                    //  resize hash if we have grown too large
                    if hashSize > cellHash!.count {
                        growPhotonHash()
                    }
                }
            }
            
            g!.count += 1
            
            g!.flux!.add(power)
            
            g!.diffuse!.add(diffuse)
            
            numStoredPhotons += 1
        }
    }

    func initStore() {
        UI.printInfo(.LIGHT, "Initializing photon grid ...")
        UI.printInfo(.LIGHT, "  * Photon hits:      \(numStoredPhotons)")
        UI.printInfo(.LIGHT, "  * hash size:  \(cellHash!.count)")
        
        var cells: Int32 = 0
        
        for i in 0 ..< cellHash!.count {
            var g: PhotonGroup? = cellHash![i]
            
            while g != nil {
                g!.diffuse!.mul(1.0 / Float(g!.count))
                
                cells += 1
                
                g = g!.next
            }
        }
        
        UI.printInfo(.LIGHT, "  * Num photon cells: \(cells)")
    }

    func precomputeRadiance(_: Bool, _: Bool) {}

    func growPhotonHash() {
        //  enlarge the hash size:
        if hashPrime >= (Self.PRIMES.count - 1) {
            return
        }
        
        hashPrime += 1
        
        var temp: [PhotonGroup?]? = [PhotonGroup?](repeating: nil, count: Int(Self.PRIMES[Int(hashPrime)]))
        
        for i in 0 ..< cellHash!.count {
            var g: PhotonGroup? = cellHash![i]
            
            while g != nil {
                //  re-hash into the new table
                let hid: Int32 = g!.id % Int32(temp!.count)
                var last: PhotonGroup? = nil
                
                var gn: PhotonGroup? = temp![Int(hid)]
                
                while gn != nil {
                    last = gn
                    
                    gn = gn!.next
                }
                
                if last == nil {
                    temp![Int(hid)] = g
                } else {
                    last!.next = g
                }
                
                let next: PhotonGroup = g!.next!
                
                g!.next = nil
                
                g = next
            }
        }
        
        cellHash = temp
    }

    func getRadiance(_ p: Point3, _ n: Vector3) -> Color {
        lockQueue.sync { // synchronized block
            if !bounds!.contains(p) {
                return Color.BLACK
            }
            
            let ext: Vector3 = bounds!.getExtents()
            
            var ix: Int32 = (Int32((p.x - bounds!.getMinimum().x)) * nx) / Int32(ext.x)
            var iy: Int32 = (Int32((p.y - bounds!.getMinimum().y)) * ny) / Int32(ext.y)
            var iz: Int32 = (Int32((p.z - bounds!.getMinimum().z)) * nz) / Int32(ext.z)
            
            ix = ix.clamp(0, nx - 1)
            iy = iy.clamp(0, ny - 1)
            iz = iz.clamp(0, nz - 1)
            
            let id: Int32 = ix + iy * nx + iz * nx * ny
            
            // rwl.readLock().lockwoot();//fixme:
            var center: PhotonGroup? = nil
            var g: PhotonGroup? = get(ix, iy, iz)
            
            while g != nil {
                if (g!.id == id) && (Vector3.dot(n, g!.normal!) > Self.NORMAL_THRESHOLD) {
                    if g!.radiance == nil {
                        center = g
                        
                        break
                    }
                    
                    let r: Color = g!.radiance!.copy()
                    // rwl.readLock().unlock();
                    
                    return r
                }
                
                g = g!.next
            }
            
            var vol: Int32 = 1
            
            while true {
                var numPhotons: Int32 = 0
                var ndiff: Int32 = 0
                let irr: Color = Color.black()
                let diff: Color? = center == nil ? Color.black() : nil
                
                for z in iz - (vol - 1) ... iz + (vol - 1) {
                    for y in iy - (vol - 1) ... iy + (vol - 1) {
                        for x in ix - (vol - 1) ... ix + (vol - 1) {
                            let vid: Int32 = x + y * nx + z * nx * ny
                            var g: PhotonGroup? = get(x, y, z)
                            
                            while g != nil {
                                if (g!.id == vid) && (Vector3.dot(n, g!.normal!) > Self.NORMAL_THRESHOLD) {
                                    numPhotons += g!.count
                                    
                                    irr.add(g!.flux!)
                                    
                                    if diff != nil {
                                        diff!.add(g!.diffuse!)
                                        
                                        ndiff += 1
                                    }
                                    
                                    break  //  only one valid group can be found, skip the others
                                }
                                
                                g = g!.next
                            }
                        }
                    }
                }
                
                if (numPhotons >= numGather) || (vol >= 3) {
                    //  we have found enough photons
                    //  cache irradiance and return
                    var area: Float = ((2 * Float(vol)) - 1) / 3.0 * ((ext.x / Float(nx)) + (ext.y / Float(ny)) + (ext.z / Float(nz)))
                    
                    area *= area
                    
                    area *= Float.pi
                    
                    irr.mul(1.0 / area)
                    
                    //  upgrade lock manually
                    // rwl.readLock().unlock();
                    // rwl.writeLock().lockwoot();//fixme:
                    if center == nil {
                        if ndiff > 0 {
                            diff!.mul(1.0 / Float(ndiff))
                        }
                        
                        center = PhotonGroup(id, n)
                        
                        center!.diffuse!.set(diff!)
                        
                        center!.next = cellHash![Int(id) % cellHash!.count]
                        
                        cellHash![Int(id) % cellHash!.count] = center
                    }
                    
                    irr.mul(center!.diffuse!)
                    
                    center!.radiance = irr.copy()
                    
                    // rwl.writeLock().unlock(); // unlock write - done
                    return irr
                }
                
                vol += 1
            }
        }
    }

    func get(_ x: Int32, _ y: Int32, _ z: Int32) -> PhotonGroup? {
        //  returns the list associated with the specified location
        if (x < 0) || (x >= nx) {
            return nil
        }
        if (y < 0) || (y >= ny) {
            return nil
        }
        if (z < 0) || (z >= nz) {
            return nil
        }
        
        return cellHash![Int(x + y * nx + z * nx * ny) % Int(cellHash!.count)]
    }

    func allowDiffuseBounced() -> Bool {
        return true
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

    final class PhotonGroup {
        var id: Int32 = 0
        var count: Int32 = 0
        var normal: Vector3?
        var flux: Color?
        var radiance: Color?
        var diffuse: Color?
        var next: PhotonGroup?

        init(_ id: Int32, _ n: Vector3) {
            normal = Vector3(n)
            
            flux = Color.black()
            
            diffuse = Color.black()
            
            radiance = nil
            
            count = 0
            
            self.id = id
            
            next = nil
        }
    }
}
