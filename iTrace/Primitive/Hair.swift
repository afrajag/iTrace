//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class Hair: PrimitiveList, Shader {
    var numSegments: Int32 = 0
    var points: [Float]?
    var widths: ParameterList.FloatParameter?

    required init() {
        numSegments = 1
        
        points = nil
        
        widths = ParameterList.FloatParameter(1.0)
    }

    func getNumPrimitives() -> Int32 {
        return numSegments * (Int32(points!.count) / (3 * (numSegments + 1)))
    }

    func getPrimitiveBound(_ primID: Int32, _ i: Int32) -> Float {
        let hair: Int32 = primID / numSegments
        let line: Int32 = primID % numSegments
        let vn: Int32 = hair * (numSegments + 1) + line
        let vRoot: Int32 = hair * 3 * (numSegments + 1)
        let v0: Int32 = vRoot + (line * 3)
        let v1: Int32 = v0 + 3
        let axis: Int32 = i >>> 1
        
        if (i & 1) == 0 {
            return min(points![Int(v0 + axis)] - 0.5 * getWidth(vn), points![Int(v1 + axis)] - 0.5 * getWidth(vn + 1))
        } else {
            return max(points![Int(v0 + axis)] + 0.5 * getWidth(vn), points![Int(v1 + axis)] + 0.5 * getWidth(vn + 1))
        }
    }

    func getWorldBounds(_ o2w: AffineTransform?) -> BoundingBox? {
        var bounds: BoundingBox? = BoundingBox()
        var i: Int32 = 0
        var j: Int32 = 0
        
        while i < points!.count {
            let w: Float = 0.5 * getWidth(j)
            
            bounds!.include(points![Int(i)] - w, points![Int(i) + 1] - w, points![Int(i) + 2] - w)
            bounds!.include(points![Int(i)] + w, points![Int(i) + 1] + w, points![Int(i) + 2] + w)
            
            i += 3
            
            j += 1
        }
        
        if o2w != nil {
            bounds = o2w!.transform(bounds!)
        }
        
        return bounds
    }

    func getWidth(_ i: Int32) -> Float {
        switch widths!.interp {
            case .NONE:
                return widths!.data![0]
            case .VERTEX:
                return widths!.data![Int(i)]
            default:
                return 0
        }
    }

    func getTangent(_ line: Int32, _ v0: Int32, _ v: Float) -> Vector3 {
        let vcurr: Vector3 = Vector3(points![Int(v0) + 3] - points![Int(v0) + 0], points![Int(v0) + 4] - points![Int(v0) + 1], points![Int(v0) + 5] - points![Int(v0) + 2])
        
        vcurr.normalize()
        
        if (line == 0 || line == numSegments - 1) {
            return vcurr
        }
        
        if v <= 0.5 {
            //  get previous segment
            let vprev: Vector3 = Vector3(points![Int(v0) + 0] - points![Int(v0) - 3], points![Int(v0) + 1] - points![Int(v0) - 2], points![Int(v0) + 2] - points![Int(v0) - 1])
            
            vprev.normalize()
            
            let t: Float = v + 0.5
            let s: Float = 1 - t
            let vx: Float = vprev.x * s + vcurr.x * t
            let vy: Float = vprev.y * s + vcurr.y * t
            let vz: Float = vprev.z * s + vcurr.z * t
            
            return Vector3(vx, vy, vz)
        } else {
            //  get next segment
            let _v0 = v0 + 3
            
            let vnext: Vector3 = Vector3(points![Int(_v0) + 3] - points![Int(_v0) + 0], points![Int(_v0) + 4] - points![Int(_v0) + 1], points![Int(_v0) + 5] - points![Int(_v0) + 2])
            
            vnext.normalize()
            
            let t: Float = 1.5 - v
            let s: Float = 1 - t
            let vx: Float = vnext.x * s + vcurr.x * t
            let vy: Float = vnext.y * s + vcurr.y * t
            let vz: Float = vnext.z * s + vcurr.z * t
            
            return Vector3(vx, vy, vz)
        }
    }

    func intersectPrimitive(_ r: Ray, _ primID: Int32, _ state: IntersectionState) {
        let hair: Int32 = primID / numSegments
        let line: Int32 = primID % numSegments
        let vRoot: Int32 = hair * 3 * (numSegments + 1)
        let v0: Int32 = vRoot + line * 3
        let v1: Int32 = v0 + 3
        let vx: Float = points![Int(v1) + 0] - points![Int(v0) + 0]
        let vy: Float = points![Int(v1) + 1] - points![Int(v0) + 1]
        let vz: Float = points![Int(v1) + 2] - points![Int(v0) + 2]
        let ux: Float = r.dy * vz - r.dz * vy
        let uy: Float = r.dz * vx - r.dx * vz
        let uz: Float = r.dx * vy - r.dy * vx
        let nx: Float = uy * vz - uz * vy
        let ny: Float = uz * vx - ux * vz
        let nz: Float = ux * vy - uy * vx
        let tden: Float = 1 / (nx * r.dx + ny * r.dy + nz * r.dz)
        let tnum: Float = (nx * (points![Int(v0) + 0] - r.ox)) + (ny * (points![Int(v0) + 1] - r.oy)) + (nz * (points![Int(v0) + 2] - r.oz))
        let t: Float = tnum * tden
        
        if r.isInside(t) {
            let vn: Int32 = hair * (numSegments + 1) + line
            let px: Float = r.ox + t * r.dx
            let py: Float = r.oy + t * r.dy
            let pz: Float = r.oz + t * r.dz
            let qx: Float = px - points![Int(v0) + 0]
            let qy: Float = py - points![Int(v0) + 1]
            let qz: Float = pz - points![Int(v0) + 2]
            let q: Float = (vx * qx + vy * qy + vz * qz) / (vx * vx + vy * vy + vz * vz)
            
            if q <= 0 {
                //  don't included rounded tip at root
                if line == 0 {
                    return
                }
                
                let dx: Float = points![Int(v0) + 0] - px
                let dy: Float = points![Int(v0) + 1] - py
                let dz: Float = points![Int(v0) + 2] - pz
                let d2: Float = dx * dx + dy * dy + dz * dz
                let width: Float = getWidth(vn)
                
                if d2 < (width * width * 0.25) {
                    r.setMax(t)
                    
                    state.setIntersection(primID, 0, 0)
                }
            } else if q >= 1 {
                let dx: Float = points![Int(v1) + 0] - px
                let dy: Float = points![Int(v1) + 1] - py
                let dz: Float = points![Int(v1) + 2] - pz
                let d2: Float = dx * dx + dy * dy + dz * dz
                let width: Float = getWidth(vn + 1)
                
                if d2 < (width * width * 0.25) {
                    r.setMax(t)
                    
                    state.setIntersection(primID, 0, 1)
                }
            } else {
                let dx: Float = points![Int(v0) + 0] + q * vx - px
                let dy: Float = points![Int(v0) + 1] + q * vy - py
                let dz: Float = points![Int(v0) + 2] + q * vz - pz
                let d2: Float = dx * dx + dy * dy + dz * dz
                let width: Float = (1 - q) * getWidth(vn) + q * getWidth(vn + 1)
                
                if d2 < (width * width * 0.25) {
                    r.setMax(t)
                    
                    state.setIntersection(primID, 0, q)
                }
            }
        }
    }

    func prepareShadingState(_ state: ShadingState) {
        state.initState()
        
        let i: Instance = state.getInstance()!
        
        state.getRay()!.getPoint(state.getPoint())
        
        let r: Ray? = state.getRay()
        let s: Shader? = i.getShader(0)
        
        state.setShader(s != nil ? s : self)
        
        let primID: Int32 = state.getPrimitiveID()
        let hair: Int32 = primID / numSegments
        let line: Int32 = primID % numSegments
        let vRoot: Int32 = hair * 3 * (numSegments + 1)
        let v0: Int32 = vRoot + line * 3
        
        //  tangent vector
        var v: Vector3 = getTangent(line, v0, state.getV())
        
        v = state.transformVectorObjectToWorld(v)
        
        state.setBasis(OrthoNormalBasis.makeFromWV(v, Vector3(-r!.dx, -r!.dy, -r!.dz)))
        
        state.getBasis()!.swapVW()
        
        //  normal
        state.getNormal()!.set(0, 0, 1)
        
        state.getBasis()!.transform(state.getNormal()!)
        
        state.getGeoNormal()!.set(state.getNormal()!)
        
        state.getUV()!.set(0, Float((line + Int32(state.getV())) / numSegments))
    }

    func update(_ pl: ParameterList) -> Bool {
        numSegments = pl.getInt("segments", numSegments)!
        
        if numSegments < 1 {
            UI.printError(.HAIR, "Invalid number of segments: \(numSegments)")
            
            return false
        }
        
        let pointsP: ParameterList.FloatParameter? = pl.getPointArray("points")
        
        if pointsP != nil {
            if pointsP!.interp != .VERTEX {
                UI.printError(.HAIR, "Point interpolation type must be set to \"vertex\" - was \"\(pointsP!.interp)\"")
            } else {
                points = pointsP!.data
            }
        }
        
        if points == nil {
            UI.printError(.HAIR, "Unabled to update hair - vertices are missing")
            
            return false
        }
        
        pl.setVertexCount(Int32(points!.count / 3))
        
        let widthsP: ParameterList.FloatParameter? = pl.getFloatArray("widths")
        
        if widthsP != nil {
            if (widthsP!.interp == .NONE) || (widthsP!.interp == .VERTEX) {
                widths = widthsP
            } else {
                UI.printWarning(.HAIR, "Width interpolation type \(widthsP!.interp) is not supported -- ignoring")
            }
        }
        
        return true
    }

    func getRadiance(_ state: ShadingState) -> Color {
        //  don't use these - gather lights for sphere of directions
        //  gather lights
        state.initLightSamples()
        
        state.initCausticSamples()
        
        let v: Vector3 = state.getRay()!.getDirection()
        
        v.negate()
        
        let h: Vector3 = Vector3()
        let t: Vector3 = state.getBasis()!.transform(Vector3(0, 1, 0))
        let diff: Color = Color.black()
        let spec: Color = Color.black()
        
        for ls in state.lightSampleList {
            let l: Vector3 = ls.getShadowRay().getDirection()
            let dotTL: Float = Vector3.dot(t, l)
            let sinTL: Float = sqrt(1 - dotTL * dotTL)
            
            //  float dotVL = Vector3.dot(v, l);
            diff.madd(sinTL, ls.getDiffuseRadiance())
            
            h.set(v + l)
            
            h.normalize()
            
            let dotTH: Float = Vector3.dot(t, h)
            let sinTH: Float = sqrt(1 - dotTH * dotTH)
            let s: Float = pow(sinTH, 10.0)
            
            spec.madd(s, ls.getSpecularRadiance())
        }
        
        let c: Color = Color.add(diff, spec)
        
        //  transparency
        return Color.blend(c, state.traceTransparency(), state.getV())
    }

    func scatterPhoton(_: ShadingState, _: Color) {}

    func getBakingPrimitives() -> PrimitiveList? {
        return nil
    }
}
