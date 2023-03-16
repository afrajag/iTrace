//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

import Foundation

final class BucketRenderer: ImageSampler {
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
    var dumpBuckets: Bool = false
    var numBuckets: Int32 = 0
    
    // anti-aliasing
    var minAADepth: Int32 = 0
    var maxAADepth: Int32 = 0
    var superSampling: Int32 = 0
    var contrastThreshold: Float = 0.0
    var jitter: Bool = false
    var displayAA: Bool = false
    
    // derived quantities
    var invSuperSampling: Double = 0.0
    var subPixelSize: Int32 = 0
    var minStepSize: Int32 = 0
    var maxStepSize: Int32 = 0
    var sigmaOrder: Int32 = 0
    var sigmaLength: Int32 = 0
    var thresh: Float = 0.0
    var useJitter: Bool = false
    
    // filtering
    var filterName: String?
    var filter: Filter?
    var fs: Int32 = 0
    var fhs: Float = 0.0

    let lockQueue = DispatchQueue(label: "bucketrender.lock.serial.queue")
    
    required init() {
        bucketSize = 32
        bucketOrderName = BucketParameter.ORDER_HILBERT
        displayAA = false
        contrastThreshold = 0.1
        filterName = "box"
        jitter = false //  off by default
        
        dumpBuckets = false //  for debugging only - not user settable
    }

    func prepare(_ options: Options, _ scene: Scene, _ w: Int32, _ h: Int32) -> Bool {
        self.scene = scene
        
        imageWidth = w
        imageHeight = h
        
        //  fetch options
        bucketSize = options.getInt(BucketParameter.PARAM_BUCKET_SIZE, bucketSize)!
        bucketOrderName = options.getString(BucketParameter.PARAM_BUCKET_ORDER, bucketOrderName)
        minAADepth = options.getInt(ImageParameter.PARAM_AA_MIN, minAADepth)!
        maxAADepth = options.getInt(ImageParameter.PARAM_AA_MAX, maxAADepth)!
        superSampling = options.getInt(ImageParameter.PARAM_AA_SAMPLES, superSampling)!
        displayAA = options.getBool(ImageParameter.PARAM_AA_DISPLAY, displayAA)!
        jitter = options.getBool(ImageParameter.PARAM_AA_JITTER, jitter)!
        contrastThreshold = options.getFloat(ImageParameter.PARAM_AA_CONTRAST, contrastThreshold)!
        
        //  limit bucket size and compute number of buckets in each direction
        bucketSize = bucketSize.clamp(16, 512)
        
        let numBucketsX: Int32 = (imageWidth + bucketSize - 1) / bucketSize
        let numBucketsY: Int32 = (imageHeight + bucketSize - 1) / bucketSize
        
        numBuckets = numBucketsX * numBucketsY
        
        bucketOrder = BucketOrderFactory.create(bucketOrderName!)
        
        bucketCoords = bucketOrder!.getBucketSequence(numBucketsX, numBucketsY)
        
        //  validate AA options
        minAADepth = minAADepth.clamp(-4, 5)
        maxAADepth = maxAADepth.clamp(minAADepth, 5)
        
        superSampling = superSampling.clamp(1, 256)
        
        invSuperSampling = 1.0 / Double(superSampling)
        
        //  compute AA stepping sizes
        subPixelSize = (maxAADepth > 0) ? (1 << maxAADepth) : 1
        
        minStepSize = maxAADepth >= 0 ? 1 : 1 << (-maxAADepth)
        
        if minAADepth == maxAADepth {
            maxStepSize = minStepSize
        } else {
            maxStepSize = minAADepth > 0 ? 1 << minAADepth : subPixelSize << (-minAADepth)
        }
        
        useJitter = jitter && maxAADepth > 0
        
        //  compute anti-aliasing contrast thresholds
        contrastThreshold = contrastThreshold.clamp(0, 1)
        
        thresh = contrastThreshold * pow(2.0, Float(minAADepth))
        
        //  read filter settings from scene
        filterName = options.getString("filter", filterName)
        
        filter = PluginRegistry.filterPlugins.createInstance(filterName)
        
        //  adjust filter
        if filter == nil {
            UI.printWarning(.BCKT, "Unrecognized filter type: \"\(filterName!)\" - defaulting to box")
            
            filter = BoxFilter()
            
            filterName = "box"
        }
        
        fhs = filter!.getSize() * 0.5
        
        fs = Int32(ceil(Float(subPixelSize) * (fhs - 0.5)))
        
        //  prepare QMC sampling
        sigmaOrder = min(QMC.MAX_SIGMA_ORDER, max(0, maxAADepth) + 13) //  FIXME: how big should the table be
        
        sigmaLength = 1 << sigmaOrder
        
        UI.printInfo(.BCKT, "Bucket renderer settings:")
        UI.printInfo(.BCKT, "  * Resolution:         \(imageWidth)x\(imageHeight)")
        UI.printInfo(.BCKT, "  * Bucket size:        \(bucketSize)")
        UI.printInfo(.BCKT, "  * Number of buckets:  \(numBucketsX)x\(numBucketsY)")
        
        if minAADepth != maxAADepth {
            UI.printInfo(.BCKT, "  * Anti-aliasing:      \(aaDepthTostring(minAADepth)) -> \(aaDepthTostring(maxAADepth)) (adaptive)")
        } else {
            UI.printInfo(.BCKT, "  * Anti-aliasing:      \(aaDepthTostring(minAADepth)) (fixed)")
        }
        
        UI.printInfo(.BCKT, "  * Rays per sample:    \(superSampling)")
        UI.printInfo(.BCKT, "  * Subpixel jitter:    \(useJitter ? "on" : (jitter ? "auto-off" : "off"))")
        UI.printInfo(.BCKT, "  * Contrast threshold: \(contrastThreshold)")
        UI.printInfo(.BCKT, "  * Filter type:        \(filterName!)")
        UI.printInfo(.BCKT, "  * Filter size:        \(filter!.getSize()) pixels")
        
        return true
    }

    func aaDepthTostring(_ depth: Int32) -> String {
        let pixelAA: Int32 = (depth) < 0 ? -(1 << (-depth)) : (1 << depth)
        
        return ("\(depth < 0 ? "1/" : "")\(pixelAA * pixelAA) sample\(depth == 0 ? "" : "s")")
    }

    func render(_ display: Display) {
        self.display = display
        
        display.imageBegin(imageWidth, imageHeight, bucketSize)
        
        //  set members variables
        bucketCounter = 0
        
        //  start task
        UI.taskStart("Rendering", 0, Int32(bucketCoords!.count))
        
        let timer: TraceTimer = TraceTimer()
        
        timer.start()
        
        // var renderThreads: [BucketThread] = [BucketThread](repeating: 0, count: Int(scene!.getThreads()))
        
        let renderQueue = DispatchQueue(label: "bucketrender.queue", qos: .userInitiated, attributes: .concurrent)

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

                self.renderBucket(display, bx, by, Int32(threadCounter), istate)

                if UI.taskCanceled() {
                    return
                }

                self.updateStats(istate)
            }
        }

        /*
        for i in 0 ..< renderThreads.count {
            renderThreads[i] = BucketThread(Int32(i), self)
            
            renderThreads[i].setPriority(scene!.getThreadPriority())
            
            renderThreads[i].start()
        }
        
        for i in 0 ..< renderThreads.count {
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

    func renderBucket(_ display: Display, _ bx: Int32, _ by: Int32, _ threadID: Int32, _ istate: IntersectionState) {
        //  pixel sized extents
        let x0: Int32 = bx * bucketSize
        let y0: Int32 = by * bucketSize
        let bw: Int32 = min(bucketSize, imageWidth - x0)
        let bh: Int32 = min(bucketSize, imageHeight - y0)
        
        //  prepare bucket
        display.imagePrepare(x0, y0, bw, bh, threadID)
        
        var bucketRGB: [Color] = [Color](repeating: Color(), count: Int(bw * bh))
        var bucketAlpha: [Float] = [Float](repeating: 0, count: Int(bw * bh))
        
        //  subpixel extents
        let sx0: Int32 = x0 * subPixelSize - fs
        let sy0: Int32 = y0 * subPixelSize - fs
        var sbw: Int32 = bw * subPixelSize + fs * 2
        var sbh: Int32 = bh * subPixelSize + fs * 2
        
        //  round up to align with maximum step size
        sbw = (sbw + (maxStepSize - 1)) & (~(maxStepSize - 1))
        sbh = (sbh + (maxStepSize - 1)) & (~(maxStepSize - 1))
        
        //  extra padding as needed
        if maxStepSize > 1 {
            sbw += 1
            sbh += 1
        }
        
        //  allocate bucket memory
        var samples: [ImageSample] = [ImageSample](repeating: ImageSample(), count: Int(sbw * sbh))
        
        //  allocate samples and compute jitter offsets
        let invSubPixelSize: Float = 1.0 / Float(subPixelSize)
        
        var index: Int = 0
        
        for y in 0 ..< sbh {
            for x in 0 ..< sbw {
                let sx: Int32 = sx0 + x
                let sy: Int32 = sy0 + y
                
                let j: Int32 = sx & (sigmaLength - 1)
                let k: Int32 = sy & (sigmaLength - 1)
                let i: Int32 = (j << sigmaOrder) + QMC.sigma(k, sigmaOrder)
                
                let dx: Float = useJitter ? Float(QMC.halton(0, k)) : 0.5
                let dy: Float = useJitter ? Float(QMC.halton(0, j)) : 0.5
                
                let rx: Float = (Float(sx) + dx) * invSubPixelSize
                var ry: Float = (Float(sy) + dy) * invSubPixelSize
                
                ry = Float(imageHeight) - ry
                
                samples[index] = ImageSample(rx, ry, i)
                
                index += 1
            }
        }
        
        var x: Int32 = 0
        
        while x < (sbw - 1) {
            var y: Int32 = 0

            while y < (sbh - 1) {
                refineSamples(&samples, sbw, x, y, &maxStepSize, &thresh, istate)
                
                y += maxStepSize
            }
            
            x += maxStepSize
        }
        
        if dumpBuckets {
            UI.printInfo(.BCKT, "Dumping bucket [\(bx), \(by)] to file ...")
            
            let bitmap: GenericBitmap = GenericBitmap(sbw, sbh)
            
            var index: Int = 0
            var y: Int32 = sbh - 1
            
            while y >= 0 {
                var x: Int32 = 0
                
                while x < sbw {
                    bitmap.writePixel(x, y, samples[index].c!, samples[index].alpha)
                    
                    x += 1
                    
                    index += 1
                }
                
                y -= 1
            }
            
            bitmap.save("bucket_\(bx)_\(by).png")
        }
        
        if displayAA {
            //  color coded image of what is visible
            let invArea: Float = invSubPixelSize * invSubPixelSize
            
            var index: Int = 0
            
            for y in 0 ..< bh {
                for x in 0 ..< bw {
                    var sampled: Int32 = 0
                    
                    for i in 0 ..< subPixelSize {
                        for j in 0 ..< subPixelSize {
                            let sx: Int32 = x * subPixelSize + fs + i
                            let sy: Int32 = y * subPixelSize + fs + j
                            let s: Int32 = sx + sy * sbw
                            
                            sampled += (samples[Int(s)].sampled() ? 1 : 0)
                        }
                    }
                    
                    bucketRGB[Int(index)] = Color(Float(sampled) * invArea)
                    
                    bucketAlpha[Int(index)] = 1.0
                    
                    index += 1
                }
            }
        } else {
            //  filter samples into pixels
            var cy: Float = Float(imageHeight - (y0 + Int32(0.5)))
            
            var index: Int = 0
            
            for y in 0 ..< bh {
                var cx: Float = Float(x0) + 0.5
                
                for x in 0 ..< bw {
                    let c: Color = Color.black()
                    var a: Float = 0.0
                    var weight: Float = 0.0
                    
                    var sy = y * subPixelSize
                    
                    for _ in -fs ... fs {
                        var sx = x * subPixelSize
                        
                        var s = sx + sy * sbw
                        
                        for _ in -fs ... fs {
                            let dx: Float = samples[Int(s)].rx - cx
                            
                            if abs(dx) > fhs {
                                continue
                            }
                            
                            let dy: Float = samples[Int(s)].ry - cy
                            
                            if abs(dy) > fhs {
                                continue
                            }
                            
                            let f: Float = filter!.get(dx, dy)
                            
                            c.madd(f, samples[Int(s)].c!)
                            
                            a += f * samples[Int(s)].alpha
                            
                            weight += f
                            
                            sx += 1
                            
                            s += 1
                        }
                        
                        sy += 1
                    }
                    
                    let invWeight: Float = 1.0 / weight
                    
                    c.mul(invWeight)
                    
                    a *= invWeight
                    
                    bucketRGB[Int(index)] = c
                    
                    bucketAlpha[Int(index)] = a
                    
                    cx += 1
                    
                    index += 1
                }
                
                cy -= 1
            }
        }
        
        //  update pixels
        display.imageUpdate(x0, y0, bw, bh, bucketRGB, bucketAlpha)
    }

    func updateStats(_ istate: IntersectionState) {
        scene!.accumulateStats(istate)
    }
    
    func computeSubPixel(_ sample: ImageSample, _ istate: IntersectionState) {
        let x: Float = sample.rx
        let y: Float = sample.ry
        
        let q0: Double = QMC.halton(1, sample.i)
        let q1: Double = QMC.halton(2, sample.i)
        let q2: Double = QMC.halton(3, sample.i)
        
        if superSampling > 1 {
            //  multiple sampling
            sample.add(scene!.getRadiance(istate, x, y, q1, q2, q0, sample.i, 4, nil))
            
            for i in 1 ..< superSampling {
                let time: Double = QMC.mod1(q0 + Double(i) * invSuperSampling)
                let lensU: Double = QMC.mod1(q1 + QMC.halton(0, i))
                let lensV: Double = QMC.mod1(q2 + QMC.halton(1, i))
                
                sample.add(scene!.getRadiance(istate, x, y, lensU, lensV, time, sample.i + i, 4, nil))
            }
            
            sample.scale(Float(invSuperSampling))
        } else {
            //  single sample
            sample.set(scene!.getRadiance(istate, x, y, q1, q2, q0, sample.i, 4, nil))
        }
    }

    func refineSamples(_ samples: inout [ImageSample], _ sbw: Int32, _ x: Int32, _ y: Int32, _ stepSize: inout Int32, _ thresh: inout Float, _ istate: IntersectionState) {
        let dx: Int32 = stepSize
        let dy: Int32 = stepSize * sbw
        
        let i00: Int32 = x + y * sbw
        
        let s00: ImageSample = samples[Int(i00)]
        let s01: ImageSample = samples[Int(i00 + dy)]
        let s10: ImageSample = samples[Int(i00 + dx)]
        let s11: ImageSample = samples[Int(i00 + dx + dy)]
        
        if !s00.sampled() {
            computeSubPixel(s00, istate)
        }
        
        if !s01.sampled() {
            computeSubPixel(s01, istate)
        }
        
        if !s10.sampled() {
            computeSubPixel(s10, istate)
        }
        
        if !s11.sampled() {
            computeSubPixel(s11, istate)
        }
        
        if stepSize > minStepSize {
            if s00.isDifferent(s01, thresh) || s00.isDifferent(s10, thresh) || s00.isDifferent(s11, thresh) || s01.isDifferent(s11, thresh) || s10.isDifferent(s11, thresh) || s01.isDifferent(s10, thresh) {
                stepSize >>= 1
                
                thresh *= 2
                
                refineSamples(&samples, sbw, x, y, &stepSize, &thresh, istate)
                refineSamples(&samples, sbw, x + stepSize, y, &stepSize, &thresh, istate)
                refineSamples(&samples, sbw, x, y + stepSize, &stepSize, &thresh, istate)
                refineSamples(&samples, sbw, x + stepSize, y + stepSize, &stepSize, &thresh, istate)
                
                return
            }
        }
        
        //  interpolate remaining samples
        let ds: Float = 1.0 / Float(stepSize)
        
        for i in 0 ... stepSize {
            for j in 0 ... stepSize {
                if !samples[Int(x + i + (y + j) * sbw)].processed() {
                    ImageSample.bilerp(samples[Int(x + i + (y + j) * sbw)], s00, s01, s10, s11, Float(i) * ds, Float(j) * ds)
                }
            }
        }
    }

    /*
    final class BucketThread {
        var threadID: Int32 = 0
        var istate: IntersectionState
        var renderer: BucketRenderer
        var thread: Thread

        init(_ threadID: Int32, _ renderer: BucketRenderer) {
            self.threadID = threadID
            
            istate = IntersectionState()
            
            self.renderer = renderer
            
            thread = Thread(ThreadStart(run))
            
            thread.IsBackground = true
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
                
                bx = renderer.bucketCoords[Int(renderer.bucketCounter) + 0]
                by = renderer.bucketCoords[Int(renderer.bucketCounter) + 1]
                
                renderer.bucketCounter += 2

                renderer.renderBucket(renderer.display, bx, by, threadID, istate)
                
                if UI.taskCanceled() {
                    return
                }
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
            renderer.scene!.accumulateStats(istate)
        }
    }
    */
    
    final class ImageSample {
        var c: Color?
        var alpha: Float = 0.0
        var instance: Instance?
        var shader: Shader?
        var rx: Float = 0.0
        var ry: Float = 0.0
        var i: Int32 = 0
        var n: Int32 = 0
        var nx: Float = 0.0
        var ny: Float = 0.0
        var nz: Float = 0.0

        init() {}
        
        init(_ rx: Float, _ ry: Float, _ i: Int32) {
            self.rx = rx
            self.ry = ry
            self.i = i
            
            n = 0
            
            c = nil
            
            alpha = 0.0
            
            instance = nil
            
            shader = nil
            
            nx = 1
            ny = 1
            nz = 1
        }

        func set(_ state: ShadingState?) {
            if state == nil {
                c = Color.BLACK
            } else {
                c = state!.getResult()
                
                shader = state!.getShader()!
                
                instance = state!.getInstance()
                
                if state!.getNormal() != nil {
                    nx = state!.getNormal()!.x
                    ny = state!.getNormal()!.y
                    nz = state!.getNormal()!.z
                }
                
                alpha = state!.getInstance() == nil ? 0 : 1
            }
            
            n = 1
        }

        func add(_ state: ShadingState?) {
            if n == 0 {
                c = Color.black()
            }
            
            if state != nil {
                c!.add(state!.getResult()!)
                
                alpha += state!.getInstance() == nil ? 0 : 1
            }
            
            n += 1
        }

        func scale(_ s: Float) {
            c!.mul(s)
            
            alpha *= s
        }

        func processed() -> Bool {
            return c != nil
        }

        func sampled() -> Bool {
            return n > 0
        }

        func isDifferent(_ sample: ImageSample, _ thresh: Float) -> Bool {
            // FIXME: va implementato Comparable su tutto ?
            /*
            if instance != sample.instance {
                return true
            }
            
            if shader != sample.shader {
                return true
            }
            */
            
            if instance == nil || sample.instance == nil {
                return true
            }
            
            if shader == nil || sample.shader == nil {
                return true
            }
            
            if Color.hasContrast(c!, sample.c!, thresh) {
                return true
            }
            
            if abs(alpha - sample.alpha) / (alpha + sample.alpha) > thresh {
                return true
            }
            
            //  only compare normals if this pixel has not been averaged
            let dot: Float = nx * sample.nx + ny * sample.ny + nz * sample.nz
            
            return dot < 0.9
        }

        @discardableResult
        static func bilerp(_ result: ImageSample, _ i00: ImageSample, _ i01: ImageSample, _ i10: ImageSample, _ i11: ImageSample, _ dx: Float, _ dy: Float) -> ImageSample {
            let k00: Float = (1.0 - dx) * (1.0 - dy)
            let k01: Float = (1.0 - dx) * dy
            let k10: Float = dx * (1.0 - dy)
            let k11: Float = dx * dy
            
            let c00: Color = i00.c!
            let c01: Color = i01.c!
            let c10: Color = i10.c!
            let c11: Color = i11.c!
            
            let c: Color = Color.mul(k00, c00)
            
            c.madd(k01, c01)
            c.madd(k10, c10)
            c.madd(k11, c11)
            
            result.c = c
            
            result.alpha = k00 * i00.alpha + k01 * i01.alpha + k10 * i10.alpha + k11 * i11.alpha
            
            return result
        }
    }
}
