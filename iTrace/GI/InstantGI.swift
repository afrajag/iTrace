//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

import Foundation

final class InstantGI: GIEngine {
    var numPhotons: Int32 = 0
    var numSets: Int32 = 0
    var c: Float = 0.0
    var numBias: Int32 = 0
    var virtualLights: [[PointLight]]? = []

    let lockQueue = DispatchQueue(label: "instangi.lock.serial.queue")

    required init() {}
    
    func getGlobalRadiance(_ state: ShadingState) -> Color {
        let p: Point3 = state.getPoint()
        let n: Vector3 = state.getNormal()!
        let set: Int = Int(state.getRandom(0, 1, 1) * Double(numSets))
        var maxAvgPow: Float = 0
        var minDist: Float = 1
        var pow: Color? = nil
        
        for vpl in virtualLights![set] {
            maxAvgPow = max(maxAvgPow, vpl.power!.getAverage())
            
            if Vector3.dot(n, vpl.n!) > 0.9 {
                let d: Float = vpl.p!.distanceToSquared(p)
                
                if d < minDist {
                    pow = vpl.power
                    
                    minDist = d
                }
            }
        }
        
        return (pow == nil ? Color.BLACK : pow!.copy().mul(1.0 / maxAvgPow))
    }

    func initGI(_ options: Options, _ scene: Scene) -> Bool {
        numPhotons = options.getInt(InstantGIParameter.PARAM_SAMPLES, 64)!
        
        numSets = options.getInt(InstantGIParameter.PARAM_SETS, 1)!
        
        c = options.getFloat(InstantGIParameter.PARAM_BIAS, 0.00003)!
        
        numBias = options.getInt(InstantGIParameter.PARAM_BIAS_SAMPLES, 0)!
        
        virtualLights = nil
        
        if numSets < 1 {
            numSets = 1
        }
        
        UI.printInfo(.LIGHT, "Instant Global Illumination settings:")
        UI.printInfo(.LIGHT, "  * Samples:     \(numPhotons)")
        UI.printInfo(.LIGHT, "  * Sets:        \(numSets)")
        UI.printInfo(.LIGHT, "  * Bias bound:  \(c)")
        UI.printInfo(.LIGHT, "  * Bias rays:   \(numBias)")
        
        virtualLights = [[PointLight]](repeating: [], count: Int(numSets))
        
        if numPhotons > 0 {
            var seed: Int32 = 0
            
            for i in 0 ..< virtualLights!.count {
                let map: PointLightStore = PointLightStore(self)
                
                if !scene.calculatePhotons(map, "virtual", seed, options) {
                    return false
                }
                
                virtualLights![i] = map.virtualLights
                
                UI.printInfo(.LIGHT, "Stored \(virtualLights![i].count) virtual point lights for set \(i + 1) of \(numSets)")
                
                seed += numPhotons
            }
        } else {
            //  create an empty array
            for i in 0 ..< virtualLights!.count {
                virtualLights![i] = [PointLight](repeating: PointLight(), count: 0)
            }
        }
        
        return true
    }

    func getIrradiance(_ state: ShadingState, _ diffuseReflectance: Color) -> Color {
        let b: Float = Float.pi * c / diffuseReflectance.getMax()
        let irr: Color = Color.black()
        let p: Point3 = state.getPoint()
        let n: Vector3 = state.getNormal()!
        let set: Int = Int(state.getRandom(0, 1, 1) * Double(numSets))
        
        for vpl in virtualLights![set] {
            let r: Ray = Ray(p, vpl.p!)
            let dotNlD: Float = -(r.dx * vpl.n!.x + r.dy * vpl.n!.y + r.dz * vpl.n!.z)
            let dotND: Float = r.dx * n.x + r.dy * n.y + r.dz * n.z
            
            if (dotNlD > 0) && (dotND > 0) {
                let r2: Float = r.getMax() * r.getMax()
                let opacity: Color = state.traceShadow(r)
                let power: Color = Color.blend(vpl.power!, Color.BLACK, opacity)
                let g: Float = (dotND * dotNlD) / r2
                
                irr.madd(0.25 * min(g, b), power)
            }
        }
        
        //  bias compensation
        let nb: Int32 = (state.getDiffuseDepth() == 0 || numBias <= 0) ? numBias : 1
        
        if nb <= 0 {
            return irr
        }
        
        let onb: OrthoNormalBasis = state.getBasis()!
        let w: Vector3 = Vector3()
        let scale: Float = Float.pi / Float(nb)
        
        for i in 0 ..< nb {
            let xi: Float = Float(state.getRandom(i, 0, nb))
            let xj: Float = Float(state.getRandom(i, 1, nb))
            let phi: Float = xi * 2 * Float.pi
            let cosPhi: Float = Float(cos(phi))
            let sinPhi: Float = Float(sin(phi))
            let sinTheta: Float = sqrt(xj)
            let cosTheta: Float = sqrt(1.0 - xj)
            
            w.x = cosPhi * sinTheta
            w.y = sinPhi * sinTheta
            w.z = cosTheta
            
            onb.transform(w)
            
            let r: Ray = Ray(state.getPoint(), w)
            
            r.setMax(sqrt(cosTheta / b))
            
            let temp: ShadingState? = state.traceFinalGather(r, i)
            
            if temp != nil {
                temp!.getInstance()!.prepareShadingState(temp!)
                
                if temp!.getShader() != nil {
                    let dist: Float = temp!.getRay()!.getMax()
                    let r2: Float = dist * dist
                    let cosThetaY: Float = -Vector3.dot(w, temp!.getNormal()!)
                    
                    if cosThetaY > 0 {
                        let g: Float = (cosTheta * cosThetaY) / r2
                        
                        //  was this path accounted for yet
                        if g > b {
                            irr.madd(scale * (g - b) / g, temp!.getShader()!.getRadiance(temp!))
                        }
                    }
                }
            }
        }
        
        return irr
    }

    final class PointLight {
        var p: Point3?
        var n: Vector3?
        var power: Color?
    }

    final class PointLightStore: PhotonStore {
        var virtualLights: [PointLight] = [PointLight]()
        var gi: InstantGI?
        
        let lockQueue = DispatchQueue(label: "pointlightstore.lock.serial.queue")

        required init() {}
        
        init(_ gi: InstantGI) {
            self.gi = gi
        }

        func initStore() {}
        
        func numEmit() -> Int32 {
            return gi!.numPhotons
        }

        func prepare(_: Options, _: BoundingBox) {}

        func store(_ state: ShadingState, _: Vector3, _ power: Color, _: Color) {
            state.faceforward()
            
            let vpl: PointLight = PointLight()
            
            vpl.p = state.getPoint()
            vpl.n = state.getNormal()!
            vpl.power = power

            lockQueue.sync { // synchronized block
                virtualLights.append(vpl)
            }
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
    }
}
