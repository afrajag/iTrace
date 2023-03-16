//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

import Foundation

final class MultipassRenderer: ImageSampler {
    var scene: Scene?
    var display: Display?
    
    // resolution
    var imageWidth: Int32 = 0
    var imageHeight: Int32 = 0
    
    // bucketing
    var bucketOrderName: String?
    var bucketOrder: BucketOrder?
    var bucketSize: Int32 = 0
    var bucketCounter: Int32 = 0
    var bucketCoords: [Int32]?
    var numBuckets: Int32 = 0
    
    // anti-aliasing
    var numSamples: Int32 = 0
    var invNumSamples: Float = 0.0
    var shadingCache: Bool = false
    var cacheDirTolerance: Float = 1e-5
    var cacheNormalTolerance: Float = 1e-4

    let lockQueue = DispatchQueue(label: "multipassrender.lock.serial.queue")
    
    required init() {
        bucketSize = 32
        bucketOrderName = "hilbert"
        numSamples = 16
        shadingCache = false
    }

    func prepare(_ options: Options, _ scene: Scene, _ w: Int32, _ h: Int32) -> Bool {
        self.scene = scene
        
        imageWidth = w
        imageHeight = h
        
        //  fetch options
        bucketSize = options.getInt("bucket.size", bucketSize)!
        
        bucketOrderName = options.getString("bucket.order", bucketOrderName)
        
        numSamples = options.getInt("aa.samples", numSamples)!
        
        shadingCache = options.getBool("aa.cache", shadingCache)!
        
        //  limit bucket size and compute number of buckets in each direction
        bucketSize = bucketSize.clamp(16, 512)
        
        let numBucketsX: Int32 = ((imageWidth + bucketSize) - 1) / bucketSize
        let numBucketsY: Int32 = ((imageHeight + bucketSize) - 1) / bucketSize
        
        numBuckets = numBucketsX * numBucketsY
        
        bucketOrder = BucketOrderFactory.create(bucketOrderName!)
        
        bucketCoords = bucketOrder!.getBucketSequence(numBucketsX, numBucketsY)
        
        //  validate AA options
        numSamples = max(1, numSamples)
        
        invNumSamples = 1.0 / Float(numSamples)
        
        //  prepare QMC sampling
        UI.printInfo(.BCKT, "Multipass renderer settings:")
        UI.printInfo(.BCKT, " * Resolution: \(imageWidth)x\(imageHeight)")
        UI.printInfo(.BCKT, " * Bucket size: \(bucketSize)")
        UI.printInfo(.BCKT, " * Number of buckets: \(numBucketsX)x\(numBucketsY)")
        UI.printInfo(.BCKT, " * Samples / pixel: \(numSamples)")
        UI.printInfo(.BCKT, " * Shading cache: \(shadingCache ? "enabled" : "disabled")")
        
        return true
    }

    func render(_ display: Display) {
        self.display = display
        
        display.imageBegin(imageWidth, imageHeight, bucketSize)
        
        //  set members variables
        bucketCounter = 0
        
        //  start task
        let timer: TraceTimer = TraceTimer()
        
        timer.start()
        
        UI.taskStart("Rendering", 0, Int32(bucketCoords!.count))
        
        let renderQueue = DispatchQueue(label: "multipassrender.queue", qos: .userInitiated, attributes: .concurrent)

        renderQueue.sync {
            DispatchQueue.concurrentPerform(iterations: Int(self.numBuckets)) { threadCounter in
        //for threadCounter in 0 ..< self.numBuckets {
                var bx: Int32 = 0
                var by: Int32 = 0

                self.lockQueue.sync { // synchronized block
                    bx = bucketCoords![Int(bucketCounter) + 0]
                    by = bucketCoords![Int(bucketCounter) + 1]
                    
                    bucketCounter += 2

                    UI.taskUpdate(Int32(bucketCounter))
                }

                let istate: IntersectionState = IntersectionState()
                let cache: ShadingCache? = shadingCache ? ShadingCache(cacheDirTolerance, cacheNormalTolerance) : nil
                
                self.renderBucket(display, bx, by, Int32(threadCounter), istate, cache)

                if UI.taskCanceled() {
                    return
                }

                self.updateStats(istate, cache)
            }
        }
        
        /*
        var renderThreads: [BucketThread] = [BucketThread](repeating: 0, count: scene.getThreads())
        
        for i in 0 ... renderThreads.count - 1 {
            renderThreads[i] = BucketThread(i, self)
            renderThreads[i].setPriority(scene.getThreadPriority())
            renderThreads[i].start()
        }
        for i in 0 ... renderThreads.count - 1 {
            renderThreads[i].join()
            renderThreads[i].updateStats()
            // UI.printError(.BCKT, "Bucket processing thread \(xxx) of \(xxx) was interrupted", i + 1, renderThreads.count)
        }
        */
        
        UI.taskStop()
        
        timer.end()
        
        UI.printInfo(.BCKT, "Render time: \(timer.toString())")
        
        display.imageEnd()
    }

    func renderBucket(_ display: Display, _ bx: Int32, _ by: Int32, _ threadID: Int32, _ istate: IntersectionState, _ cache: ShadingCache?) {
        //  pixel sized extents
        let x0: Int32 = bx * bucketSize
        let y0: Int32 = by * bucketSize
        
        let bw: Int32 = min(bucketSize, imageWidth - x0)
        let bh: Int32 = min(bucketSize, imageHeight - y0)
        
        //  prepare bucket
        display.imagePrepare(x0, y0, bw, bh, threadID)
        
        var bucketRGB: [Color] = [Color](repeating: Color(), count: Int(bw * bh))
        var bucketAlpha: [Float] = [Float](repeating: 0, count: Int(bw * bh))
        
        var cy = imageHeight - 1 - y0
        var i: Int = 0
        
        for _ in 0 ..< bh {
            var cx = x0
            
            for _ in 0 ..< bw {
                //  sample pixel
                let c: Color = Color.black()
                
                var a: Float = 0
                let instance: Int32 = ((cx & ((1 << QMC.MAX_SIGMA_ORDER) - 1)) << QMC.MAX_SIGMA_ORDER) + QMC.sigma(cy & ((1 << QMC.MAX_SIGMA_ORDER) - 1), QMC.MAX_SIGMA_ORDER)
                let jitterX: Double = QMC.halton(0, instance)
                let jitterY: Double = QMC.halton(1, instance)
                let jitterT: Double = QMC.halton(2, instance)
                let jitterU: Double = QMC.halton(3, instance)
                let jitterV: Double = QMC.halton(4, instance)
                
                for s in 0 ..< numSamples {
                    let rx: Float = Float(cx) + 0.5 + Float(MultipassRenderer.warpCubic(QMC.mod1(jitterX + Double((Float(s) * invNumSamples)))))
                    let ry: Float = Float(cy) + 0.5 + Float(MultipassRenderer.warpCubic(QMC.mod1(jitterY + QMC.halton(0, s))))
                    let time: Double = QMC.mod1(jitterT + QMC.halton(1, s))
                    let lensU: Double = QMC.mod1(jitterU + QMC.halton(2, s))
                    let lensV: Double = QMC.mod1(jitterV + QMC.halton(3, s))
                    
                    let state: ShadingState? = scene!.getRadiance(istate, rx, ry, lensU, lensV, time, instance + s, 5, cache)
                    
                    if state != nil {
                        c.add(state!.getResult()!)
                        
                        a += 1
                    }
                }
                
                bucketRGB[i] = c.mul(invNumSamples)
                bucketAlpha[i] = a * invNumSamples
                
                if cache != nil {
                    cache!.reset()
                }
                
                i += 1
                
                cx += 1
            }
            
            cy -= 1
        }
        
        //  update pixels
        display.imageUpdate(x0, y0, bw, bh, bucketRGB, bucketAlpha)
    }

    func updateStats(_ istate: IntersectionState, _ cache: ShadingCache?) {
        scene!.accumulateStats(istate)
        
        if shadingCache {
            scene!.accumulateStats(cache!)
        }
    }
    
    // Tent filter warping function.
    //
    // @param x sample in the [0,1) range
    // @return warped sample in the [-1,+1) range
    static func warpTent(_ x: Float) -> Float {
        if x < 0.5 {
            return -1 + sqrt(2 * x)
        } else {
            return +1 - sqrt(2 - 2 * x)
        }
    }

    // Cubic BSpline warping functions. Formulas from: "Generation of Stratified
    // Samples for B-Spline Pixel Filtering"
    // http://www.cs.utah.edu/~mstark/papers/
    //
    // @param x samples in the [0,1) range
    // @return warped sample in the [-2,+2) range
    static func warpCubic(_ x: Double) -> Double {
        if x < (1.0 / 24) {
            return qpow(24 * x) - 2
        }
        
        if x < 0.5 {
            return distb1((24.0 / 11.0) * (x - (1.0 / 24.0))) - 1
        }
        
        if x < (23.0 / 24) {
            return 1 - distb1((24.0 / 11.0) * ((23.0 / 24.0) - x))
        }
        
        return 2 - qpow(24 * (1 - x))
    }

    static func qpow(_ x: Double) -> Double {
        return sqrt(sqrt(x))
    }

    static func distb1(_ x: Double) -> Double {
        var u: Double = x
        
        for _ in 0 ..< 5 {
            u = (11 * x + u * u * (6 + u * (8 - 9 * u))) / (4 + 12 * u * (1 + u * (1 - u)))
        }
        
        return u
    }

    /*
    final class BucketThread {
        var threadID: Int32 = 0
        var istate: IntersectionState
        var cache: ShadingCache
        var thread: Thread
        var renderer: MultipassRenderer

        init(_ threadID: Int32, _ renderer: MultipassRenderer) {
            self.threadID = threadID
            istate = IntersectionState()
            cache = (renderer.shadingCache ? ShadingCache() : nil)
            self.renderer = renderer
            thread = Thread(ThreadStart(run))
            thread.IsBackground = true
            self.renderer = renderer
        }

        func run() {
            ByteUtil.InitByteUtil()
            while true {
                var bx: Int32
                var by: Int32
                if renderer.bucketCounter >= renderer.bucketCoords.count {
                    return
                }
                UI.taskUpdate(renderer.bucketCounter)
                bx = renderer.bucketCoords[renderer.bucketCounter + 0]
                by = renderer.bucketCoords[renderer.bucketCounter + 1]
                renderer.bucketCounter = renderer.bucketCounter + 2

                renderer.renderBucket(renderer.display, bx, by, threadID, istate, cache)
            }
        }

        func setPriority(_ prior: ThreadPriority) {
            thread.Priority = prior
        }

        func start() {
            thread.Start()
        }

        func stop() {
            thread.Abort()
        }

        func join() {
            thread.Join()
        }

        func updateStats() {
            renderer.scene.accumulateStats(istate)
            if renderer.shadingCache {
                renderer.scene.accumulateStats(cache)
            }
        }
    }
    */
}
