//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//
import Foundation

final class LightServer {
    var scene: Scene?
    var lights: [LightSource]
    var shaderOverride: Shader?
    var shaderOverridePhotons: Bool = false
    var maxDiffuseDepth: Int32 = 0
    var maxReflectionDepth: Int32 = 0
    var maxRefractionDepth: Int32 = 0
    var causticPhotonMap: CausticPhotonMapInterface?
    var giEngine: GIEngine?
    var photonCounter: Int32 = 0

    let lockQueue = DispatchQueue(label: "lightserver.lock.serial.queue")

    init(_ scene: Scene?) {
        self.scene = scene
        lights = [LightSource]()
        causticPhotonMap = nil
        shaderOverride = nil
        shaderOverridePhotons = false
        maxDiffuseDepth = 1
        maxReflectionDepth = 4
        maxRefractionDepth = 4
        causticPhotonMap = nil
        giEngine = nil
    }

    func setLights(_ lights: [LightSource]) {
        self.lights = lights
    }

    func getScene() -> Scene? {
        return scene
    }

    func setShaderOverride(_ shader: Shader?, _ photonOverride: Bool) {
        shaderOverride = shader
        shaderOverridePhotons = photonOverride
    }

    func build(_ options: Options) -> Bool {
        //  read options
        maxDiffuseDepth = options.getInt("depths.diffuse", maxDiffuseDepth)!
        maxReflectionDepth = options.getInt("depths.reflection", maxReflectionDepth)!
        maxRefractionDepth = options.getInt("depths.refraction", maxRefractionDepth)!

        let giEngineType: String? = options.getString("gi.engine", nil)
        giEngine = PluginRegistry.giEnginePlugins.createInstance(giEngineType)

        let caustics: String? = options.getString("caustics", nil)
        causticPhotonMap = PluginRegistry.causticPhotonMapPlugins.createInstance(caustics)

        //  validate options
        maxDiffuseDepth = max(0, maxDiffuseDepth)
        maxReflectionDepth = max(0, maxReflectionDepth)
        maxRefractionDepth = max(0, maxRefractionDepth)

        let t: TraceTimer = TraceTimer()

        t.start()

        //  count total number of light samples
        var numLightSamples: Int32 = 0

        for i in 0 ..< lights.count {
            numLightSamples = numLightSamples + lights[i].getNumSamples()
        }

        //  initialize gi engine
        if giEngine != nil {
            if !giEngine!.initGI(options, scene!) {
                return false
            }
        }

        if !calculatePhotons(causticPhotonMap, "caustic", 0, options) {
         	return false
        }

        t.end()

        UI.printInfo(.LIGHT, "Light Server stats:")
        UI.printInfo(.LIGHT, "  * Light sources found: \(lights.count)")
        UI.printInfo(.LIGHT, "  * Light samples:       \(numLightSamples)")
        UI.printInfo(.LIGHT, "  * Max raytrace depth:")
        UI.printInfo(.LIGHT, "      - Diffuse          \(maxDiffuseDepth)")
        UI.printInfo(.LIGHT, "      - Reflection       \(maxReflectionDepth)")
        UI.printInfo(.LIGHT, "      - Refraction       \(maxRefractionDepth)")
        UI.printInfo(.LIGHT, "  * GI engine            \(giEngineType != nil ? giEngineType! : "none")")
        UI.printInfo(.LIGHT, "  * Caustics:            \(caustics != nil ? caustics! : "none")")
        UI.printInfo(.LIGHT, "  * Shader override:     \(shaderOverride != nil ? shaderOverride!.description : "none")")
        UI.printInfo(.LIGHT, "  * Photon override:     \(shaderOverridePhotons)")
        UI.printInfo(.LIGHT, "  * Build time:          \(t.toString())")

        return true
    }

    func showStats() {}

    func calculatePhotons(_ map: PhotonStore?, _ type: String, _ seed: Int32, _ options: Options) -> Bool {
        if map == nil {
            return true
        }

        if lights.isEmpty {
            UI.printError(.LIGHT, "Unable to trace \(type) photons, no lights in scene")
            
            return false
        }

        var histogram: [Float] = [Float](repeating: 0, count: lights.count)

        histogram[0] = lights[0].getPower()

        for i in 1 ..< lights.count {
            histogram[i] = histogram[i - 1] + lights[i].getPower()
        }

        UI.printInfo(.LIGHT, "Tracing \(type) photons ...")

        map!.prepare(options, scene!.getBounds())

        let numEmittedPhotons: Int32 = map!.numEmit()

        if (numEmittedPhotons <= 0) || (histogram[histogram.count - 1] <= 0) {
            UI.printError(.LIGHT, "Photon mapping enabled, but no \(type) photons to emit")
            
            return false
        }

        UI.taskStart("Tracing " + type + " photons", 0, numEmittedPhotons)

        // var photonThreads: [Thread] = [Thread](repeating: 0, count: xxx)
        let photonThreads_count = scene!.getThreads()
        let scale: Float = 1.0 / Float(numEmittedPhotons)
        let delta: Float = Float(numEmittedPhotons / photonThreads_count) // photonThreads.count

        photonCounter = 0

        let photonTraceTimer: TraceTimer = TraceTimer()

        photonTraceTimer.start()
        /*
         let photonQueue = DispatchQueue(label: "PhotonQueue")
         let photonGroup = DispatchGroup()

         for i in 0 ... photonThreads_count - 1 {
         let threadID: Int32 = Int32(i)

         let start: Int32 = threadID * Int32(delta)
         let end: Int32 = (threadID == (photonThreads_count - 1) ? numEmittedPhotons : (threadID + 1) * Int32(delta))

         /*
          photonThreads[i] = Thread(ThreadStart(CalculatePhotons(start, end, self, seed, histogram, scale, map).Run))
          photonThreads[i].priority = scene.getThreadPriority()
          photonThreads[i].start()
          */

         let renderQueue = DispatchQueue(label: "render.queue", qos: .background, attributes: .concurrent)
         renderQueue.async {
         DispatchQueue.concurrentPerform(iterations: Int(self.numBuckets)) { bucketCounter in

         photonQueue.async(group: photonGroup) {
         PhotonThread(start, end, self, seed, histogram, scale, map!).run()
         }
         }

         /*
          for i in 0 ... photonThreads.count - 1 {
          		photonThreads[i].Join()
          		//UI.printError(.LIGHT, "Photon thread \(xxx) of \(xxx) was interrupted", i + 1, photonThreads.count)
          		return false
          }
          */

         photonGroup.wait()
         */
        let renderQueue = DispatchQueue(label: "photon.queue", qos: .userInitiated, attributes: .concurrent)
        
        renderQueue.sync {
            DispatchQueue.concurrentPerform(iterations: Int(photonThreads_count - 1)) { threadID in
                var start: Int32 = 0
                var end: Int32 = 0

                self.lockQueue.sync { // synchronized block
                    start = Int32(threadID) * Int32(delta)
                    end = (threadID == (photonThreads_count - 1) ? numEmittedPhotons : Int32(threadID + 1) * Int32(delta))
                }
                
                PhotonThread(start, end, self, seed, histogram, scale, map!).run()
                
                if UI.taskCanceled() {
                    UI.taskStop() //  shut down task cleanly
                    
                    return
                }
            }
        }

        photonTraceTimer.end()

        UI.taskStop()

        UI.printInfo(.LIGHT, "Tracing time for \(type) photons: \(photonTraceTimer.toString())")

        map!.initStore()

        return true
    }

    func shadePhoton(_ state: ShadingState, _ power: Color) {
        state.getInstance()!.prepareShadingState(state)

        let shader: Shader? = getPhotonShader(state)

        //  scatter photon
        if shader != nil {
            shader!.scatterPhoton(state, power)
        }
    }

    func traceDiffusePhoton(_ previous: ShadingState, _ r: Ray, _ power: Color) {
        if previous.getDiffuseDepth() >= maxDiffuseDepth {
            return
        }

        let istate: IntersectionState? = previous.getIntersectionState()

        scene!.trace(r, istate!)

        if previous.getIntersectionState()!.hit() {
            //  create a new shading context
            let state: ShadingState = ShadingState.createDiffuseBounceState(previous, r, 0)

            shadePhoton(state, power)
        }
    }

    func traceReflectionPhoton(_ previous: ShadingState, _ r: Ray, _ power: Color) {
        if previous.getReflectionDepth() >= maxReflectionDepth {
            return
        }

        let istate: IntersectionState = previous.getIntersectionState()!

        scene!.trace(r, istate)

        if previous.getIntersectionState()!.hit() {
            //  create a new shading context
            let state: ShadingState = ShadingState.createReflectionBounceState(previous, r, 0)

            shadePhoton(state, power)
        }
    }

    func traceRefractionPhoton(_ previous: ShadingState, _ r: Ray, _ power: Color) {
        if previous.getRefractionDepth() >= maxRefractionDepth {
            return
        }

        let istate: IntersectionState = previous.getIntersectionState()!

        scene!.trace(r, istate)

        if previous.getIntersectionState()!.hit() {
            //  create a new shading context
            let state: ShadingState = ShadingState.createRefractionBounceState(previous, r, 0)

            shadePhoton(state, power)
        }
    }

    func getShader(_ state: ShadingState) -> Shader? {
        return shaderOverride != nil ? shaderOverride! : state.getShader()
    }

    func getPhotonShader(_ state: ShadingState) -> Shader? {
        return shaderOverride != nil && shaderOverridePhotons ? shaderOverride! : state.getShader()
    }

    func getRadiance(_ rx: Float, _ ry: Float, _ time: Float, _ i: Int32, _ d: Int32, _ r: Ray, _ istate: IntersectionState, _ cache: ShadingCache?) -> ShadingState? {
        istate.time = time

        scene!.trace(r, istate)

        if istate.hit() {
            let state: ShadingState = ShadingState.createState(istate, rx, ry, time, r, i, d, self)

            state.getInstance()!.prepareShadingState(state)

            let shader: Shader? = getShader(state)

            if shader == nil {
                state.setResult(Color.BLACK)

                return state
            }

            if cache != nil {
                let c: Color? = cache!.lookup(state, shader!)

                if c != nil {
                    state.setResult(c!)

                    return state
                }
            }

            state.setResult(shader!.getRadiance(state))

            if cache != nil {
                cache!.add(state, shader!, state.getResult()!)
            }

            Self.checkNanInf(state.getResult()!)

            return state
        } else {
            return nil
        }
    }

    static func checkNanInf(_ c: Color) {
        if c.isNan() {
            UI.printWarning(.LIGHT, "NaN shading sample")
        } else {
            if c.isInf() {
                UI.printWarning(.LIGHT, "Inf shading sample")
            }
        }
    }

    func shadeBakeResult(_ state: ShadingState) {
        let shader: Shader? = getShader(state)

        if shader != nil {
            state.setResult(shader!.getRadiance(state))
        } else {
            state.setResult(Color.BLACK)
        }
    }

    func shadeHit(_ state: ShadingState) -> Color {
        state.getInstance()!.prepareShadingState(state)

        let shader: Shader? = getShader(state)

        return (shader != nil ? shader!.getRadiance(state) : Color.BLACK)
    }

    func traceGlossy(_ previous: ShadingState, _ r: Ray, _ i: Int32) -> Color {
        //  limit path depth and disable caustic paths
        if (previous.getReflectionDepth() >= maxReflectionDepth) || (previous.getDiffuseDepth() > 0) {
            return Color.BLACK
        }

        let istate: IntersectionState = previous.getIntersectionState()!

        istate.numGlossyRays += 1

        scene!.trace(r, istate)

        return (istate.hit() ? shadeHit(ShadingState.createGlossyBounceState(previous, r, i)) : Color.BLACK)
    }

    func traceReflection(_ previous: ShadingState, _ r: Ray, _ i: Int32) -> Color {
        //  limit path depth and disable caustic paths
        if (previous.getReflectionDepth() >= maxReflectionDepth) || (previous.getDiffuseDepth() > 0) {
            return Color.BLACK
        }

        let istate: IntersectionState = previous.getIntersectionState()!

        istate.numReflectionRays += 1

        scene!.trace(r, istate)

        return (istate.hit() ? shadeHit(ShadingState.createReflectionBounceState(previous, r, i)) : Color.BLACK)
    }

    func traceRefraction(_ previous: ShadingState, _ r: Ray, _ i: Int32) -> Color {
        //  limit path depth and disable caustic paths
        if (previous.getRefractionDepth() >= maxRefractionDepth) || (previous.getDiffuseDepth() > 0) {
            return Color.BLACK
        }

        let istate: IntersectionState = previous.getIntersectionState()!

        istate.numRefractionRays += 1

        scene!.trace(r, istate)

        return (istate.hit() ? shadeHit(ShadingState.createRefractionBounceState(previous, r, i)) : Color.BLACK)
    }

    func traceFinalGather(_ previous: ShadingState, _ r: Ray, _ i: Int32) -> ShadingState? {
        if previous.getDiffuseDepth() >= maxDiffuseDepth {
            return nil
        }

        let istate: IntersectionState = previous.getIntersectionState()!

        scene!.trace(r, istate)

        return (istate.hit() ? ShadingState.createFinalGatherState(previous, r, i) : nil)
    }

    func getGlobalRadiance(_ state: ShadingState) -> Color {
        if giEngine == nil {
            return Color.BLACK
        }

        return giEngine!.getGlobalRadiance(state)
    }

    func getIrradiance(_ state: ShadingState, _ diffuseReflectance: Color) -> Color {
        //  no gi engine, or we have already exceeded number of available bounces
        if (giEngine == nil) || (state.getDiffuseDepth() >= maxDiffuseDepth) {
            return Color.BLACK
        }

        return giEngine!.getIrradiance(state, diffuseReflectance)
    }

    func initLightSamples(_ state: ShadingState) {
        for l in lights {
            l.getSamples(state)
        }
    }

    func initCausticSamples(_ state: ShadingState) {
        if causticPhotonMap != nil {
            causticPhotonMap!.getSamples(state)
        }
    }

    final class PhotonThread {
        var server: LightServer
        var histogram: [Float]
        var scale: Float = 0.0
        var map: PhotonStore
        var start: Int32 = 0
        var end: Int32 = 0
        var seed: Int32 = 0

        let lockQueue = DispatchQueue(label: "photonthread.lock.serial.queue")
        
        init(_ start: Int32, _ end: Int32, _ server: LightServer, _ seed: Int32, _ histogram: [Float], _ scale: Float, _ map: PhotonStore) {
            self.start = start
            self.end = end
            self.server = server
            self.seed = seed
            self.histogram = histogram
            self.scale = scale
            self.map = map
        }

        func run() {
            let istate: IntersectionState = IntersectionState()

            for i in start ..< end {
                lockQueue.sync { // synchronized block
                    UI.taskUpdate(server.photonCounter)

                    server.photonCounter += 1

                    if UI.taskCanceled() {
                        return
                    }
                }
                
                let qmcI: Int32 = i + seed
                let rand: Double = QMC.halton(0, qmcI) * Double(histogram[histogram.count - 1])
                
                var j: Int = 0
                while rand >= Double(histogram[j]), j < histogram.count {
                    j += 1
                }

                //  make sure we didn't pick a zero-probability light
                if j == histogram.count {
                    continue
                }

                let randX1: Double = j == 0 ? rand / Double(histogram[0]) : Double((Float(rand) - histogram[Int(j)]) / (histogram[Int(j)] - histogram[Int(j) - 1]))
                let randY1: Double = QMC.halton(1, qmcI)
                let randX2: Double = QMC.halton(2, qmcI)
                let randY2: Double = QMC.halton(3, qmcI)

                let pt: Point3 = Point3()
                let dir: Vector3 = Vector3()

                let power: Color = Color()

                server.lights[j].getPhoton(randX1, randY1, randX2, randY2, pt, dir, power)

                power.mul(scale)

                let r: Ray = Ray(pt, dir)

                server.scene!.trace(r, istate)

                if istate.hit() {
                    server.shadePhoton(ShadingState.createPhotonState(r, istate, qmcI, map, server), power)
                }
            }
        }
    }
}
