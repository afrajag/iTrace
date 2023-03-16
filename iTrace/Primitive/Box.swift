//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

class Box: PrimitiveList {
    var minX: Float = 0.0
    var minY: Float = 0.0
    var minZ: Float = 0.0
    var maxX: Float = 0.0
    var maxY: Float = 0.0
    var maxZ: Float = 0.0

    required init() {
        minZ = -1
        minY = -1
        minX = -1
        maxZ = +1
        maxY = +1
        maxX = +1
    }

    func update(_ pl: ParameterList) -> Bool {
        let min: Point3? = pl.getPoint("min", nil)
        let max: Point3? = pl.getPoint("max", nil)
        
        minX = min!.x
        minY = min!.y
        minZ = min!.z
        maxX = max!.x
        maxY = max!.y
        maxZ = max!.z
        
        return true
    }

    func prepareShadingState(_ state: ShadingState) {
        state.initState()
        
        state.getRay()!.getPoint(state.getPoint())
        
        let n: Int32 = state.getPrimitiveID()
        
        switch n {
            case 0:
                state.getNormal()!.set(Vector3(1, 0, 0))
            case 1:
                state.getNormal()!.set(Vector3(-1, 0, 0))
            case 2:
                state.getNormal()!.set(Vector3(0, 1, 0))
            case 3:
                state.getNormal()!.set(Vector3(0, -1, 0))
            case 4:
                state.getNormal()!.set(Vector3(0, 0, 1))
            case 5:
                state.getNormal()!.set(Vector3(0, 0, -1))
            default:
                state.getNormal()!.set(Vector3(0, 0, 0))
        }
        
        state.getGeoNormal()!.set(state.getNormal()!)
        
        state.setBasis(OrthoNormalBasis.makeFromW(state.getNormal()!))
        
        state.setShader(state.getInstance()!.getShader(0))
        
        state.setModifier(state.getInstance()!.getModifier(0))
    }

    func intersectPrimitive(_ r: Ray, _ primID: Int32, _ state: IntersectionState) {
        var intervalMin: Float = -Float.infinity
        var intervalMax: Float = Float.infinity
        let orgX: Float = r.ox
        let invDirX: Float = 1 / r.dx
        var t1: Float
        var t2: Float
        
        t1 = (minX - orgX) * invDirX
        t2 = (maxX - orgX) * invDirX
        
        var sideIn: Int32 = -1
        var sideOut: Int32 = -1
        
        if invDirX > 0 {
            if t1 > intervalMin {
                intervalMin = t1
                
                sideIn = 0
            }
            
            if t2 < intervalMax {
                intervalMax = t2
                
                sideOut = 1
            }
        } else {
            if t2 > intervalMin {
                intervalMin = t2
                
                sideIn = 1
            }
            if t1 < intervalMax {
                intervalMax = t1
                
                sideOut = 0
            }
        }
        
        if intervalMin > intervalMax {
            return
        }
        
        let orgY: Float = r.oy
        let invDirY: Float = 1 / r.dy
        
        t1 = (minY - orgY) * invDirY
        t2 = (maxY - orgY) * invDirY
        
        if invDirY > 0 {
            if t1 > intervalMin {
                intervalMin = t1
                
                sideIn = 2
            }
            
            if t2 < intervalMax {
                intervalMax = t2
                
                sideOut = 3
            }
        } else {
            if t2 > intervalMin {
                intervalMin = t2
                
                sideIn = 3
            }
            
            if t1 < intervalMax {
                intervalMax = t1
                
                sideOut = 2
            }
        }
        
        if intervalMin > intervalMax {
            return
        }
        
        let orgZ: Float = r.oz
        let invDirZ: Float = 1 / r.dz
        
        t1 = (minZ - orgZ) * invDirZ //  no front wall
        t2 = (maxZ - orgZ) * invDirZ
        
        if invDirZ > 0 {
            if t1 > intervalMin {
                intervalMin = t1
                
                sideIn = 4
            }
            
            if t2 < intervalMax {
                intervalMax = t2
                
                sideOut = 5
            }
        } else {
            if t2 > intervalMin {
                intervalMin = t2
                
                sideIn = 5
            }
            
            if t1 < intervalMax {
                intervalMax = t1
                
                sideOut = 4
            }
        }
        
        if intervalMin > intervalMax {
            return
        }
        
        if r.isInside(intervalMin) {
            r.setMax(intervalMin)
            
            state.setIntersection(sideIn)
        } else if r.isInside(intervalMax) {
            r.setMax(intervalMax)
            
            state.setIntersection(sideOut)
        }
    }

    func getNumPrimitives() -> Int32 {
        return 1
    }

    func getPrimitiveBound(_: Int32, _ i: Int32) -> Float {
        switch i {
            case 0:
                return minX
            case 1:
                return maxX
            case 2:
                return minY
            case 3:
                return maxY
            case 4:
                return minZ
            case 5:
                return maxZ
            default:
                return 0
        }
    }

    func getWorldBounds(_ o2w: AffineTransform?) -> BoundingBox? {
        let bounds: BoundingBox! = BoundingBox(minX, minY, minZ)
        
        bounds.include(maxX, maxY, maxZ)
        
        if o2w == nil {
            return bounds
        }
        
        return o2w!.transform(bounds)
    }

    func getBakingPrimitives() -> PrimitiveList? {
        return nil
    }
}
