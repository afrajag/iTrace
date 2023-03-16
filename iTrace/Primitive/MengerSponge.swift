//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class MengerSponge: PrimitiveList {
    var bounds: BoundingBox?
    var nx: Int32 = 0
    var ny: Int32 = 0
    var nz: Int32 = 0
    var voxelwx: Float = 0.0
    var voxelwy: Float = 0.0
    var voxelwz: Float = 0.0
    var invVoxelwx: Float = 0.0
    var invVoxelwy: Float = 0.0
    var invVoxelwz: Float = 0.0
    var depth: Int32 = 3

    init() {
        nx = 1
        ny = 1
        nz = 1
        
        bounds = BoundingBox(1)
    }

    func update(_ pl: ParameterList) -> Bool {
        depth = pl.getInt("depth", depth)!
        
        var n: Int32 = 1
        
        for _ in 0 ..< depth {
            n *= 3
        }
        
        nx = pl.getInt("resolutionX", n)!
        ny = pl.getInt("resolutionY", n)!
        nz = pl.getInt("resolutionZ", n)!
        
        voxelwx = 2.0 / Float(n)
        voxelwy = 2.0 / Float(n)
        voxelwz = 2.0 / Float(n)
        
        invVoxelwx = 1 / voxelwx
        invVoxelwy = 1 / voxelwy
        invVoxelwz = 1 / voxelwz
        
        return true
    }

    func inside(_ _x: Int32, _ _y: Int32, _ _z: Int32) -> Bool {
        var x = _x
        var y = _y
        var z = _z
        
        for _ in 0 ..< depth {
            
            if ((x % 3) == 1 ? (y % 3) == 1 || (z % 3) == 1 : (y % 3) == 1 && (z % 3) == 1) {
                return false
            }
            
            x /= 3
            y /= 3
            z /= 3
        }
        
        return true
    }

    func getBounds() -> BoundingBox? {
        return bounds
    }

    func prepareShadingState(_ state: ShadingState) {
        state.initState()
        
        state.getRay()!.getPoint(state.getPoint())
        
        let parent: Instance = state.getInstance()!
        var normal: Vector3
        
        switch state.getPrimitiveID() {
            case 0:
                normal = Vector3(-1, 0, 0)
            case 1:
                normal = Vector3(1, 0, 0)
            case 2:
                normal = Vector3(0, -1, 0)
            case 3:
                normal = Vector3(0, 1, 0)
            case 4:
                normal = Vector3(0, 0, -1)
            case 5:
                normal = Vector3(0, 0, 1)
            default:
                normal = Vector3(0, 0, 0)
        }
        
        state.getNormal()!.set(state.transformNormalObjectToWorld(normal))
        
        state.getGeoNormal()!.set(state.getNormal()!)
        
        state.setBasis(OrthoNormalBasis.makeFromW(state.getNormal()!))
        
        state.setShader(parent.getShader(0))
        
        state.setModifier(parent.getModifier(0))
    }

    func intersectPrimitive(_ r: Ray, _: Int32, _ state: IntersectionState) {
        var intervalMin: Float = r.getMin()
        var intervalMax: Float = r.getMax()
        var orgX: Float = r.ox
        var orgY: Float = r.oy
        var orgZ: Float = r.oz
        let dirX: Float = r.dx
        let invDirX: Float = 1 / dirX
        let dirY: Float = r.dy
        let invDirY: Float = 1 / dirY
        let dirZ: Float = r.dz
        let invDirZ: Float = 1 / dirZ
        var t1: Float
        var t2: Float
        
        t1 = (-1 - orgX) * invDirX
        t2 = (+1 - orgX) * invDirX
        
        var curr: Int32 = -1
        
        if invDirX > 0 {
            if t1 > intervalMin {
                intervalMin = t1
                
                curr = 0
            }
            
            if t2 < intervalMax {
                intervalMax = t2
            }
            
            if intervalMin > intervalMax {
                return
            }
        } else {
            if t2 > intervalMin {
                intervalMin = t2
                
                curr = 1
            }
            
            if t1 < intervalMax {
                intervalMax = t1
            }
            
            if intervalMin > intervalMax {
                return
            }
        }
        
        t1 = (-1 - orgY) * invDirY
        t2 = (+1 - orgY) * invDirY
        
        if invDirY > 0 {
            if t1 > intervalMin {
                intervalMin = t1
                
                curr = 2
            }
            
            if t2 < intervalMax {
                intervalMax = t2
            }
            
            if intervalMin > intervalMax {
                return
            }
        } else {
            if t2 > intervalMin {
                intervalMin = t2
                
                curr = 3
            }
            
            if t1 < intervalMax {
                intervalMax = t1
            }
            
            if intervalMin > intervalMax {
                return
            }
        }
        
        t1 = (-1 - orgZ) * invDirZ
        t2 = (+1 - orgZ) * invDirZ
        
        if invDirZ > 0 {
            if t1 > intervalMin {
                intervalMin = t1
                
                curr = 4
            }
            
            if t2 < intervalMax {
                intervalMax = t2
            }
            
            if intervalMin > intervalMax {
                return
            }
        } else {
            if t2 > intervalMin {
                intervalMin = t2
                
                curr = 5
            }
            
            if t1 < intervalMax {
                intervalMax = t1
            }
            
            if intervalMin > intervalMax {
                return
            }
        }
        
        //  box is hit at [intervalMin, intervalMax]
        orgX += intervalMin * dirX
        orgY += intervalMin * dirY
        orgZ += intervalMin * dirZ
        
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
        indxX = Int32((orgX + 1) * invVoxelwx)
        
        if indxX < 0 {
            indxX = 0
        } else if indxX >= nx {
                indxX = nx - 1
        }
        
        if abs(dirX) < 1e-6 {
            stepX = 0
            
            stopX = indxX
            
            deltaX = 0
            
            tnextX = Float.infinity
        } else if dirX > 0 {
            stepX = 1
            
            stopX = nx
            
            deltaX = voxelwx * invDirX
            
            tnextX = intervalMin + (((Float(indxX + 1) * voxelwx) - 1 - orgX) * invDirX)
        } else {
            stepX = -1
            
            stopX = -1
            
            deltaX = -voxelwx * invDirX
            
            tnextX = intervalMin + (((Float(indxX) * voxelwx) - 1 - orgX) * invDirX)
        }
        
        //  stepping factors along Y
        indxY = Int32((orgY + 1) * invVoxelwy)
        
        if indxY < 0 {
            indxY = 0
        } else if indxY >= ny {
                indxY = ny - 1
        }
        
        if abs(dirY) < 1e-6 {
            stepY = 0
            
            stopY = indxY
            
            deltaY = 0
            
            tnextY = Float.infinity
        } else if dirY > 0 {
            stepY = 1
            
            stopY = ny
            
            deltaY = voxelwy * invDirY
            
            tnextY = intervalMin + (((Float(indxY + 1) * voxelwy) - 1 - orgY) * invDirY)
        } else {
            stepY = -1
            
            stopY = -1
            
            deltaY = -voxelwy * invDirY
            
            tnextY = intervalMin + (((Float(indxY) * voxelwy) - 1 - orgY) * invDirY)
        }
        
        //  stepping factors along Z
        indxZ = Int32((orgZ + 1) * invVoxelwz)
        if indxZ < 0 {
            indxZ = 0
        } else if indxZ >= nz {
            indxZ = nz - 1
        }
        
        if abs(dirZ) < 1e-6 {
            stepZ = 0
            
            stopZ = indxZ
            
            deltaZ = 0
            
            tnextZ = Float.infinity
        } else if dirZ > 0 {
            stepZ = 1
            
            stopZ = nz
            
            deltaZ = voxelwz * invDirZ
            
            tnextZ = intervalMin + (((Float(indxZ + 1) * voxelwz) - 1 - orgZ) * invDirZ)
        } else {
            stepZ = -1
            
            stopZ = -1
            
            deltaZ = -voxelwz * invDirZ
            
            tnextZ = intervalMin + (((Float(indxZ) * voxelwz) - 1 - orgZ) * invDirZ)
        }
        
        //  are we starting inside the cube
        let isInside: Bool = inside(indxX, indxY, indxZ) && bounds!.contains(r.ox, r.oy, r.oz)
        
        //  trace through the grid
        while true {
            if inside(indxX, indxY, indxZ) != isInside {
                //  we hit a boundary
                r.setMax(intervalMin)
                
                //  if we are inside, the last bit needs to be flipped
                if isInside {
                    curr ^= 1
                }
                
                state.setIntersection(curr)
                
                return
            }
            
            if (tnextX < tnextY) && (tnextX < tnextZ) {
                curr = (dirX > 0 ? 0 : 1)
                
                intervalMin = tnextX
                
                if intervalMin > intervalMax {
                    return
                }
                
                indxX += stepX
                
                if indxX == stopX {
                    return
                }
                
                tnextX += deltaX
            } else if tnextY < tnextZ {
                curr = (dirY > 0 ? 2 : 3)
                
                intervalMin = tnextY
                
                if intervalMin > intervalMax {
                    return
                }
                
                indxY += stepY
                
                if indxY == stopY {
                    return
                }
                
                tnextY += deltaY
            } else {
                curr = (dirZ > 0 ? 4 : 5)
                
                intervalMin = tnextZ
                
                if intervalMin > intervalMax {
                    return
                }
                
                indxZ += stepZ
                
                if indxZ == stopZ {
                    return
                }
                
                tnextZ += deltaZ
            }
        }
    }

    func getNumPrimitives() -> Int32 {
        return 1
    }

    func getPrimitiveBound(_: Int32, _ i: Int32) -> Float {
        return (i & 1) == 0 ? -1 : 1
    }

    func getWorldBounds(_ o2w: AffineTransform?) -> BoundingBox? {
        if o2w == nil {
            return bounds
        }
        
        return o2w!.transform(bounds!)
    }

    func getBakingPrimitives() -> PrimitiveList? {
        return nil
    }
}
