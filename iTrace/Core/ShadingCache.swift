//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class ShadingCache {
    var samples: [Sample] = [Sample](repeating: Sample(), count: 256)
    var depth: Int32 = 0
    var hits: Int64 = 0
    var misses: Int64 = 0
    var sumDepth: Int64 = 0
    var numCaches: Int64 = 0

    var dirTolerance: Float = 0
    var normalTolerance: Float = 0
    
    init(_ dirTolerance: Float, _ normalTolerance: Float) {
        reset()
        
        hits = 0
        misses = 0
        
        self.dirTolerance = dirTolerance
        self.normalTolerance = normalTolerance
    }

    func reset() {
        sumDepth = sumDepth + Int64(depth)

        if depth > 0 {
            numCaches += 1
        }

        samples.removeAll()

        depth = 0
    }

    func lookup(_ state: ShadingState, _: Shader) -> Color? {
        if state.getNormal() == nil {
            return nil
        }

        for s in samples {
            // FIXME: ripristinare e anche qui utilizzare equatable
            /*
             if s!.i != state.getInstance() {
             	continue
             }

             if s!.s != shader {
             	continue
             }
             */
            
            if state.getRay()!.dot(s.dx, s.dy, s.dz) < 1 - dirTolerance {
                continue
            }

            if state.getNormal()!.dot(s.nx, s.ny, s.nz) < 1 - normalTolerance {
                continue
            }

            //  we have a match
            hits += 1

            return s.c
        }

        misses += 1

        return nil
    }

    func add(_ state: ShadingState, _ shader: Shader, _ c: Color) {
        if state.getNormal() == nil || depth >= samples.count {
            return
        }

        var s: Sample = Sample(i: state.getInstance()!, s: shader, c: c)

        s.i = state.getInstance()
        s.s = shader
        s.c = c
        
        s.dx = state.getRay()!.dx
        s.dy = state.getRay()!.dy
        s.dz = state.getRay()!.dz

        s.nx = state.getNormal()!.x
        s.ny = state.getNormal()!.y
        s.nz = state.getNormal()!.z

        samples.insert(s, at: Int(depth))

        depth += 1
    }

    struct Sample {
        var i: Instance?
        var s: Shader?
        var c: Color?

        var nx: Float = 0.0
        var ny: Float = 0.0
        var nz: Float = 0.0
        var dx: Float = 0.0
        var dy: Float = 0.0
        var dz: Float = 0.0
    }
}
