//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class UniformGrid: AccelerationStructure {
    var primitives: PrimitiveList?
    var bounds: BoundingBox?
    var cells: [[Int32]?]?
    var nx: Int32 = 0
    var ny: Int32 = 0
    var nz: Int32 = 0
    var voxelwx: Float = 0.0
    var voxelwy: Float = 0.0
    var voxelwz: Float = 0.0
    var invVoxelwx: Float = 0.0
    var invVoxelwy: Float = 0.0
    var invVoxelwz: Float = 0.0
    
    required init() {
        nx = 0
        ny = 0
        nz = 0
        bounds = nil
        cells = nil
        voxelwx = 0
        voxelwy = 0
        voxelwz = 0
        invVoxelwx = 0
        invVoxelwy = 0
        invVoxelwz = 0
    }
    
    func build(_ primitives: PrimitiveList) {
        let t: TraceTimer = TraceTimer()
        
        t.start()
        
        self.primitives = primitives
        
        let n: Int32 = primitives.getNumPrimitives()
        
        //  compute bounds
        bounds = primitives.getWorldBounds(nil)
        
        //  create grid from number of objects
        bounds!.enlargeUlps()
        
        let w: Vector3 = bounds!.getExtents()
        let s: Double = pow(Double(w.x * w.y * w.z) / Double(n), 1 / 3.0)
        
        nx = Int32((Double(w.x) / s) + 0.5).clamp(1, 128)
        ny = Int32((Double(w.y) / s) + 0.5).clamp(1, 128)
        nz = Int32((Double(w.z) / s) + 0.5).clamp(1, 128)
        
        voxelwx = w.x / Float(nx)
        voxelwy = w.y / Float(ny)
        voxelwz = w.z / Float(nz)
        
        invVoxelwx = 1 / voxelwx
        invVoxelwy = 1 / voxelwy
        invVoxelwz = 1 / voxelwz
        
        UI.printDetailed(.ACCEL, "Creating grid: \(nx)x\(ny)x\(nz) ...")
        
        var buildCells: [[Int32]?] = [[Int32]](repeating: [0], count: Int(nx * ny * nz))
        
        //  add all objects into the grid cells they overlap
        var imin: [Int32] = [Int32](repeating: 0, count: 3)
        var imax: [Int32] = [Int32](repeating: 0, count: 3)
        var numCellsPerObject: Int32 = 0
        
        for i in 0 ..< n {
            getGridIndex(primitives.getPrimitiveBound(i, 0), primitives.getPrimitiveBound(i, 2), primitives.getPrimitiveBound(i, 4), &imin)
            
            getGridIndex(primitives.getPrimitiveBound(i, 1), primitives.getPrimitiveBound(i, 3), primitives.getPrimitiveBound(i, 5), &imax)
            
            for ix in imin[0] ... imax[0] {
                for iy in imin[1] ... imax[1] {
                    for iz in imin[2] ... imax[2] {
                        let idx: Int32 = ix + (nx * iy) + (nx * ny * iz)
                        
                        if buildCells[Int(idx)] == nil {
                            buildCells[Int(idx)]! = [Int32]()
                        }
                        
                        buildCells[Int(idx)]!.append(i)
                        
                        numCellsPerObject += 1
                    }
                }
            }
        }
        
        UI.printDetailed(.ACCEL, "Building cells ...")
        
        var numEmpty: Int32 = 0
        var numInFull: Int32 = 0
        
        cells = [[Int32]](repeating: [0], count: Int(nx * ny * nz))
        
        for i in 0 ..< buildCells.count {
            if buildCells[i] != nil {
                if buildCells[i]!.isEmpty {
                    numEmpty += 1
                    
                    buildCells[i] = nil
                } else {
                    cells![i] = buildCells[i]
                    
                    numInFull += Int32(buildCells[i]!.count)
                }
            } else {
                numEmpty += 1
            }
        }
        
        t.end()
        
        UI.printDetailed(.ACCEL, "Uniform grid statistics:")
        UI.printDetailed(.ACCEL, "  * Grid cells:          \(cells!.count)")
        UI.printDetailed(.ACCEL, "  * Used cells:          \(Int32(cells!.count) - numEmpty)")
        UI.printDetailed(.ACCEL, "  * Empty cells:         \(numEmpty)")
        UI.printDetailed(.ACCEL, "  * Occupancy:           \((100.0 * Float(cells!.count - Int(numEmpty))) / Float(cells!.count))")
        UI.printDetailed(.ACCEL, "  * Objects/Cell:        \(Double(numInFull) / Double(cells!.count))")
        UI.printDetailed(.ACCEL, "  * Objects/Used Cell:   \(Double(numInFull) / Double(cells!.count - Int(numEmpty)))")
        UI.printDetailed(.ACCEL, "  * Cells/Object:        \(Double(numCellsPerObject) / Double(n))")
        UI.printDetailed(.ACCEL, "  * Build time:          \(t.toString())")
    }
    
    func intersect(_ r: Ray, _ state: IntersectionState) {
        var intervalMin: Float = r.getMin()
        var intervalMax: Float = r.getMax()
        var orgX: Float = r.ox
        let dirX: Float = r.dx
        let invDirX: Float = 1 / dirX
        var t1: Float
        var t2: Float
        
        t1 = (bounds!.getMinimum().x - orgX) * invDirX
        t2 = (bounds!.getMaximum().x - orgX) * invDirX
        
        if invDirX > 0 {
            if t1 > intervalMin {
                intervalMin = t1
            }
            if t2 < intervalMax {
                intervalMax = t2
            }
        } else {
            if t2 > intervalMin {
                intervalMin = t2
            }
            if t1 < intervalMax {
                intervalMax = t1
            }
        }
        
        if intervalMin > intervalMax {
            return
        }
        
        var orgY: Float = r.oy
        let dirY: Float = r.dy
        let invDirY: Float = 1 / dirY
        
        t1 = (bounds!.getMinimum().y - orgY) * invDirY
        t2 = (bounds!.getMaximum().y - orgY) * invDirY
        
        if invDirY > 0 {
            if t1 > intervalMin {
                intervalMin = t1
            }
            if t2 < intervalMax {
                intervalMax = t2
            }
        } else {
            if t2 > intervalMin {
                intervalMin = t2
            }
            if t1 < intervalMax {
                intervalMax = t1
            }
        }
        
        if intervalMin > intervalMax {
            return
        }
        
        var orgZ: Float = r.oz
        let dirZ: Float = r.dz
        let invDirZ: Float = 1 / dirZ
        
        t1 = (bounds!.getMinimum().z - orgZ) * invDirZ
        t2 = (bounds!.getMaximum().z - orgZ) * invDirZ
        
        if invDirZ > 0 {
            if t1 > intervalMin {
                intervalMin = t1
            }
            if t2 < intervalMax {
                intervalMax = t2
            }
        } else {
            if t2 > intervalMin {
                intervalMin = t2
            }
            if t1 < intervalMax {
                intervalMax = t1
            }
        }
        
        if intervalMin > intervalMax {
            return
        }
        
        //  box is hit at [intervalMin, intervalMax]
        orgX += intervalMin * dirX
        orgY += intervalMin * dirY
        orgZ += intervalMin * dirZ
        
        // locate starting point inside the grid
        // and set up 3D-DDA vars
        var indxX: Int32
        var indxY: Int32
        var indxZ: Int32
        var stepX: Int32
        var stepY: Int32
        var stepZ: Int32
        var stopX: Int32
        var stopY: Int32
        var stopZ: Int32
        var deltaX: Float
        var deltaY: Float
        var deltaZ: Float
        var tnextX: Float
        var tnextY: Float
        var tnextZ: Float
        
        //  stepping factors along X
        indxX = Int32(((orgX - bounds!.getMinimum().x) * invVoxelwx).isNaN ? 0 : (orgX - bounds!.getMinimum().x) * invVoxelwx)
        
        if indxX < 0 {
            indxX = 0
        } else {
            if indxX >= nx {
                indxX = nx - 1
            }
        }
        
        if abs(dirX) < 1e-6 {
            stepX = 0
            
            stopX = indxX
            
            deltaX = 0
            
            tnextX = Float.infinity
        } else {
            if dirX > 0 {
                stepX = 1
                
                stopX = nx
                
                deltaX = voxelwx * invDirX
                
                tnextX = intervalMin + ((((Float(indxX + 1) * voxelwx) + bounds!.getMinimum().x) - orgX) * invDirX)
            } else {
                stepX = -1
                
                stopX = -1
                
                deltaX = -voxelwx * invDirX
                
                tnextX = intervalMin + ((((Float(indxX) * voxelwx) + bounds!.getMinimum().x) - orgX) * invDirX)
            }
        }
        
        //  stepping factors along Y
        indxY = Int32( ((orgY - bounds!.getMinimum().y) * invVoxelwy).isNaN ? 0 : (orgY - bounds!.getMinimum().y) * invVoxelwy)
        
        if indxY < 0 {
            indxY = 0
        } else {
            if indxY >= ny {
                indxY = ny - 1
            }
        }
        
        if abs(dirY) < 1e-6 {
            stepY = 0
            
            stopY = indxY
            
            deltaY = 0
            
            tnextY = Float.infinity
        } else {
            if dirY > 0 {
                stepY = 1
                
                stopY = ny
                
                deltaY = voxelwy * invDirY
                
                tnextY = intervalMin + ((((Float(indxY + 1) * voxelwy) + bounds!.getMinimum().y) - orgY) * invDirY)
            } else {
                stepY = -1
                
                stopY = -1
                
                deltaY = -voxelwy * invDirY
                
                tnextY = intervalMin + ((((Float(indxY) * voxelwy) + bounds!.getMinimum().y) - orgY) * invDirY)
            }
        }
        
        //  stepping factors along Z
        indxZ = Int32( ((orgZ - bounds!.getMinimum().z) * invVoxelwz).isNaN ? 0 : (orgZ - bounds!.getMinimum().z) * invVoxelwz)
        
        if indxZ < 0 {
            indxZ = 0
        } else {
            if indxZ >= nz {
                indxZ = nz - 1
            }
        }
        
        if abs(dirZ) < 1e-6 {
            stepZ = 0
            
            stopZ = indxZ
            
            deltaZ = 0
            
            tnextZ = Float.infinity
        } else {
            if dirZ > 0 {
                stepZ = 1
                
                stopZ = nz
                
                deltaZ = voxelwz * invDirZ
                
                tnextZ = intervalMin + ((((Float(indxZ + 1) * voxelwz) + bounds!.getMinimum().z) - orgZ) * invDirZ)
            } else {
                stepZ = -1
                
                stopZ = -1
                
                deltaZ = -voxelwz * invDirZ
                
                tnextZ = intervalMin + ((((Float(indxZ) * voxelwz) + bounds!.getMinimum().z) - orgZ) * invDirZ)
            }
        }
        
        let cellstepX: Int32 = stepX
        let cellstepY: Int32 = stepY * nx
        let cellstepZ: Int32 = stepZ * ny * nx
        var cell: Int32 = indxX + (indxY * nx) + (indxZ * ny * nx)
        
        //  trace through the grid
        while true {
            if tnextX < tnextY, tnextX < tnextZ {
                if cells![Int(cell)] != nil {
                    for i in cells![Int(cell)]! {
                        primitives!.intersectPrimitive(r, i, state)
                    }
                    
                    if state.hit(), r.getMax() < tnextX, r.getMax() < intervalMax {
                        return
                    }
                }
                
                intervalMin = tnextX
                
                if intervalMin > intervalMax {
                    return
                }
                
                indxX = indxX + stepX
                
                if indxX == stopX {
                    return
                }
                
                tnextX += deltaX
                
                cell += cellstepX
            } else {
                if tnextY < tnextZ {
                    if cells![Int(cell)] != nil {
                        for i in cells![Int(cell)]! {
                            primitives!.intersectPrimitive(r, i, state)
                        }
                        
                        if state.hit(), r.getMax() < tnextY, r.getMax() < intervalMax {
                            return
                        }
                    }
                    
                    intervalMin = tnextY
                    
                    if intervalMin > intervalMax {
                        return
                    }
                    
                    indxY = indxY + stepY
                    
                    if indxY == stopY {
                        return
                    }
                    
                    tnextY += deltaY
                    
                    cell += cellstepY
                } else {
                    if cells![Int(cell)] != nil {
                        for i in cells![Int(cell)]! {
                            primitives!.intersectPrimitive(r, i, state)
                        }
                        
                        if state.hit(), r.getMax() < tnextZ, r.getMax() < intervalMax {
                            return
                        }
                    }
                    
                    intervalMin = tnextZ
                    
                    if intervalMin > intervalMax {
                        return
                    }
                    
                    indxZ = indxZ + stepZ
                    
                    if indxZ == stopZ {
                        return
                    }
                    
                    tnextZ += deltaZ
                    
                    cell += cellstepZ
                }
            }
        }
    }
    
    func getGridIndex(_ x: Float, _ y: Float, _ z: Float, _ i: inout [Int32]) {
        i[0] = Int32((x - bounds!.getMinimum().x) * invVoxelwx).clamp(0, nx - 1)
        i[1] = Int32((y - bounds!.getMinimum().y) * invVoxelwy).clamp(0, ny - 1)
        i[2] = Int32((z - bounds!.getMinimum().z) * invVoxelwz).clamp(0, nz - 1)
    }
}
