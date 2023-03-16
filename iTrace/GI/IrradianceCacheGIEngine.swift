//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

import Foundation

final class IrradianceCacheGIEngine: GIEngine {
    var samples: Int32 = 0
    var tolerance: Float = 0.0
    var invTolerance: Float = 0.0
    var minSpacing: Float = 0.0
    var maxSpacing: Float = 0.0
    var root: Node?
    var globalPhotonMap: GlobalPhotonMapInterface?

    let lockQueue = DispatchQueue(label: "irradiancecachegi.lock.serial.queue")
    
    required init() {}
    
    func initGI(_ options: Options, _ scene: Scene) -> Bool {
        //  get settings
        samples = options.getInt(IrrCacheGIParameter.PARAM_SAMPLES, 256)!
        tolerance = options.getFloat(IrrCacheGIParameter.PARAM_TOLERANCE, 0.05)!
        
        invTolerance = 1.0 / tolerance
        
        minSpacing = options.getFloat(IrrCacheGIParameter.PARAM_MIN_SPACING, 0.05)!
        maxSpacing = options.getFloat(IrrCacheGIParameter.PARAM_MAX_SPACING, 5.0)!
        
        root = nil
        // rwl = new ReentrantReadWriteLock();
        globalPhotonMap = PluginRegistry.globalPhotonMapPlugins.createInstance(options.getString(IrrCacheGIParameter.PARAM_GLOBAL, nil))
        
        //  check settings
        samples = max(0, samples)
        
        minSpacing = max(0.001, minSpacing)
        maxSpacing = max(0.001, maxSpacing)
        
        //  display settings
        UI.printInfo(.LIGHT, "Irradiance cache settings:")
        UI.printInfo(.LIGHT, "  * Samples: \(samples)")
        
        if tolerance <= 0 {
            UI.printInfo(.LIGHT, "  * Tolerance: off")
        } else {
            UI.printInfo(.LIGHT, "  * Tolerance: \(tolerance)")
        }
        
        UI.printInfo(.LIGHT, "  * Spacing: \(minSpacing) to \(maxSpacing)")
        
        //  prepare root node
        let ext: Vector3 = scene.getBounds().getExtents()
        
        root = Node(scene.getBounds().getCenter(), 1.0001 * max(ext.x, ext.y, ext.z), self)
        
        //  init global photon map
        return globalPhotonMap != nil ? scene.calculatePhotons(globalPhotonMap!, "global", 0, options) : true
    }

    func getGlobalRadiance(_ state: ShadingState) -> Color {
        if globalPhotonMap == nil {
            if state.getShader() != nil {
                return state.getShader()!.getRadiance(state)
            } else {
                return Color.BLACK
            }
        } else {
            return globalPhotonMap!.getRadiance(state.getPoint(), state.getNormal()!)
        }
    }

    func getIrradiance(_ state: ShadingState, _: Color) -> Color {
        if samples <= 0 {
            return Color.BLACK
        }
        
        if state.getDiffuseDepth() > 0 {
            //  do simple path tracing for additional bounces (single ray)
            let xi: Float = Float(state.getRandom(0, 0, 1))
            let xj: Float = Float(state.getRandom(0, 1, 1))
            let phi: Float = xi * 2 * Float.pi
            let cosPhi: Float = cos(phi)
            let sinPhi: Float = sin(phi)
            let sinTheta: Float = sqrt(xj)
            let cosTheta: Float = sqrt(1.0 - xj)
            let w: Vector3 = Vector3()
            
            w.x = cosPhi * sinTheta
            w.y = sinPhi * sinTheta
            w.z = cosTheta
            
            let onb: OrthoNormalBasis? = state.getBasis()
            
            onb!.transform(w)
            
            let r: Ray = Ray(state.getPoint(), w)
            let temp: ShadingState? = state.traceFinalGather(r, 0)
            
            return temp != nil ? getGlobalRadiance(temp!).copy().mul(Float.pi) : Color.BLACK
        }
        
        // rwl.readLock().lockwoot();//fixme
        var irr: Color? = nil
        
        lockQueue.sync { // synchronized block
            irr = getIrradiance(state.getPoint(), state.getNormal()!)
        }
        // rwl.readLock().unlock();
        
        if irr == nil {
            //  compute new sample
            irr = Color.black()
            
            let onb: OrthoNormalBasis = state.getBasis()!
            var invR: Float = 0
            var minR: Float = Float.infinity
            let w: Vector3 = Vector3()
            
            for i in 0 ..< samples {
                let xi: Float = Float(state.getRandom(i, 0, samples))
                let xj: Float = Float(state.getRandom(i, 1, samples))
                let phi: Float = xi * 2 * Float.pi
                let cosPhi: Float = cos(phi)
                let sinPhi: Float = sin(phi)
                let sinTheta: Float = sqrt(xj)
                let cosTheta: Float = sqrt(1.0 - xj)
                
                w.x = cosPhi * sinTheta
                w.y = sinPhi * sinTheta
                w.z = cosTheta
                
                onb.transform(w)
                
                let r: Ray = Ray(state.getPoint(), w)
                let temp: ShadingState? = state.traceFinalGather(r, i)!
                
                if temp != nil {
                    minR = min(r.getMax(), minR)
                    
                    invR += 1.0 / r.getMax()
                    
                    temp!.getInstance()!.prepareShadingState(temp!)
                    
                    irr!.add(getGlobalRadiance(temp!))
                }
            }
            
            irr!.mul(Float.pi / Float(samples))
            
            invR = Float(samples) / invR
            
            // rwl.writeLock().lockwoot();//fixme
            lockQueue.sync { // synchronized block
                insert(state.getPoint(), state.getNormal()!, invR, irr!)
            }
            // rwl.writeLock().unlock();
            
            //  view irr-cache points
            //  irr = Color.YELLOW.copy().mul(1e6f);
        }
        
        return irr!
    }

    func insert(_ p: Point3, _ n: Vector3, _ r0: Float, _ irr: Color) {
        if tolerance <= 0 {
            return
        }

        var node: Node = root!
        
        let _r0 = ((r0 * tolerance).clamp(minSpacing, maxSpacing)) * invTolerance
        
        if root!.isInside(p) {
            while node.sideLength >= (4.0 * _r0 * tolerance) {
                var k: Int32 = 0
                
                k |= (p.x > node.center!.x) ? 1 : 0
                k |= (p.y > node.center!.y) ? 2 : 0
                k |= (p.z > node.center!.z) ? 4 : 0
                
                if node.children![Int(k)] == nil {
                    let c: Point3 = Point3(node.center!)
                    
                    c.x += (k & 1) == 0 ? -node.quadSideLength : node.quadSideLength
                    c.y += (k & 2) == 0 ? -node.quadSideLength : node.quadSideLength
                    c.z += (k & 4) == 0 ? -node.quadSideLength : node.quadSideLength
                    
                    node.children![Int(k)] = Node(c, node.halfSideLength, self)
                }
                
                node = node.children![Int(k)]!
            }
        }
        
        let s: Sample = Sample(p, n, _r0, irr)
        
        s.next = node.first
        
        node.first = s
    }

    func getIrradiance(_ p: Point3, _ n: Vector3) -> Color? {
        if tolerance <= 0 {
            return nil
        }
        
        let x: Sample = Sample(p, n)
        let w: Float = root!.find(x)
        
        return (x.irr == nil) ? nil : x.irr!.mul(1.0 / w)
    }

    final class Node {
        var children: [Node?]?
        var first: Sample?
        var center: Point3?
        var sideLength: Float = 0.0
        var halfSideLength: Float = 0.0
        var quadSideLength: Float = 0.0
        var engine: IrradianceCacheGIEngine

        init(_ center: Point3, _ sideLength: Float, _ engine: IrradianceCacheGIEngine) {
            self.engine = engine
            
            children = [Node?](repeating: nil, count: 8)
            
            // FIXME: c'e' ancora bisogno ?
            /*
            for i in 0 ..< 8 {
                children[i] = nil
            }
            */
            
            self.center = Point3(center)
            
            self.sideLength = sideLength
            
            halfSideLength = 0.5 * sideLength
            
            quadSideLength = 0.5 * halfSideLength
            
            first = nil
        }

        func isInside(_ p: Point3) -> Bool {
            return (abs(p.x - center!.x) < halfSideLength) && (abs(p.y - center!.y) < halfSideLength) && (abs(p.z - center!.z) < halfSideLength)
        }

        func find(_ x: Sample) -> Float {
            var weight: Float = 0
            var s: Sample? = first
            
            while s != nil {
                let c2: Float = 1.0 - (x.nix * s!.nix + x.niy * s!.niy + x.niz * s!.niz)
                let d2: Float = (x.pix - s!.pix) * (x.pix - s!.pix) + (x.piy - s!.piy) * (x.piy - s!.piy) + (x.piz - s!.piz) * (x.piz - s!.piz)
                
                if (c2 > (engine.tolerance * engine.tolerance)) || (d2 > (engine.maxSpacing * engine.maxSpacing)) {
                    continue
                }
                
                let invWi: Float = sqrt(d2) * s!.invR0 + sqrt(max(c2, 0))
                
                if (invWi < engine.tolerance) || (d2 < (engine.minSpacing * engine.minSpacing)) {
                    let wi: Float = min(1e10, 1.0 / invWi)
                    
                    if x.irr != nil {
                        x.irr!.madd(wi, s!.irr!)
                    } else {
                        x.irr = s!.irr!.copy().mul(wi)
                    }
                    
                    weight = weight + wi
                }
                
                s = s?.next!
            }
            
            for i in 0 ..< 8 {
                if children![i] != nil && (abs(children![i]!.center!.x - x.pix) <= halfSideLength) && (abs(children![i]!.center!.y - x.piy) <= halfSideLength) && (abs(children![i]!.center!.z - x.piz) <= halfSideLength) {
                    weight += children![i]!.find(x)
                }
            }
            
            return weight
        }
    }

    final class Sample {
        var invR0: Float = 0.0
        var irr: Color?
        var next: Sample?
        var pix: Float = 0.0
        var piy: Float = 0.0
        var piz: Float = 0.0
        var nix: Float = 0.0
        var niy: Float = 0.0
        var niz: Float = 0.0

        init(_ p: Point3, _ n: Vector3) {
            pix = p.x
            piy = p.y
            piz = p.z
            
            let ni: Vector3 = Vector3(n).normalize()
            
            nix = ni.x
            niy = ni.y
            niz = ni.z
            
            irr = nil
            
            next = nil
        }

        init(_ p: Point3, _ n: Vector3, _ r0: Float, _ irr: Color) {
            pix = p.x
            piy = p.y
            piz = p.z
            
            let ni: Vector3 = Vector3(n).normalize()
            
            nix = ni.x
            niy = ni.y
            niz = ni.z
            
            invR0 = 1.0 / r0
            
            self.irr = irr
            
            next = nil
        }
    }
}
