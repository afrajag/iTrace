//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//
import Foundation

final class SimpleRenderer: ImageSampler {
    var scene: Scene?
    var display: Display?
    var imageWidth: Int32 = 0
    var imageHeight: Int32 = 0
    var numBucketsX: Int32 = 0
    var numBucketsY: Int32 = 0
    var bucketCounter: Int32 = 0
    var numBuckets: Int32 = 0

    let lockQueue = DispatchQueue(label: "simplerender.lock.serial.queue")

    required init() {}

    func prepare(_: Options, _ scene: Scene, _ w: Int32, _ h: Int32) -> Bool {
        self.scene = scene

        imageWidth = w
        imageHeight = h

        numBucketsX = (imageWidth + 31) >>> 5
        numBucketsY = (imageHeight + 31) >>> 5

        numBuckets = numBucketsX * numBucketsY

        UI.printInfo(.BCKT, "  * buckets \(numBucketsX)x\(numBucketsY) - total \(numBuckets)")
        
        return true
    }

    func render(_ display: Display) {
        self.display = display

        display.imageBegin(imageWidth, imageHeight, 32)

        //  set members variables
        bucketCounter = 0

        let bucketTraceTimer: TraceTimer = TraceTimer()

        UI.taskStart("Rendering", 0, numBuckets)

        bucketTraceTimer.start()

        // var renderThreads: [BucketThread] = [BucketThread](repeating: 0, count: Int(scene!.getThreads()))

        let renderQueue = DispatchQueue(label: "simplerender.queue", qos: .userInitiated, attributes: .concurrent)

        renderQueue.sync {
            DispatchQueue.concurrentPerform(iterations: Int(self.numBuckets)) { bucketCounter in
        //for bucketCounter in 0 ..< self.numBuckets {
                var bx: Int32 = 0
                var by: Int32 = 0

                self.lockQueue.sync { // synchronized block
                    by = Int32(bucketCounter) / self.numBucketsX
                    bx = Int32(bucketCounter) % self.numBucketsX

                    UI.taskUpdate(Int32(bucketCounter))
                }

                let istate: IntersectionState = IntersectionState()

                self.renderBucket(bx, by, Int32(bucketCounter), istate)

                if UI.taskCanceled() {
                    return
                }

                self.updateStats(istate)
            }
        }

        UI.taskStop()

        bucketTraceTimer.end()

        UI.printInfo(.BCKT, "Render time: \(bucketTraceTimer.toString())")

        display.imageEnd()
    }

    func renderBucket(_ bx: Int32, _ by: Int32, _ threadID: Int32, _ istate: IntersectionState) {
        //  pixel sized extents
        let x0: Int32 = bx * 32
        let y0: Int32 = by * 32
        let bw: Int32 = min(32, imageWidth - x0)
        let bh: Int32 = min(32, imageHeight - y0)

        //  prepare bucket
        display!.imagePrepare(x0, y0, bw, bh, threadID)
        
        var bucketRGB: [Color] = [Color](repeating: Color(), count: Int(bw * bh))
        var bucketAlpha: [Float] = [Float](repeating: 0, count: Int(bw * bh))

        var i = 0
        
        for y in 0 ..< bh {
            for x in sequence(first: 0, next: { current in
                let next = current + 1
                
                i += 1
                
                return next < bw ? next : nil
            }) {
                let state: ShadingState? = scene!.getRadiance(istate, Float(Int(x0) + x), Float(imageHeight - 1 - (y0 + y)), 0.0, 0.0, 0.0, 0, 0, nil)

                bucketRGB[i] = (state != nil ? state!.getResult() : Color.BLACK)!

                bucketAlpha[i] = (state != nil ? 1 : 0)
            }
        }
        /*
        for y in 0 ..< bh {
            for x in 0 ..< bw {
                let state: ShadingState? = scene!.getRadiance(istate, Float(x0 + x), Float(imageHeight - 1 - (y0 + y)), 0.0, 0.0, 0.0, 0, 0, nil)

                bucketRGB[i] = (state != nil ? state!.getResult() : Color.BLACK)!

                bucketAlpha[i] = (state != nil ? 1 : 0)

                i += 1
            }
        }
        */

        //  update pixels
        display!.imageUpdate(x0, y0, bw, bh, bucketRGB, bucketAlpha)
    }

    func updateStats(_ istate: IntersectionState) {
        scene!.accumulateStats(istate)
    }

    /*
     final class BucketThread {
     	var renderer: SimpleRenderer
     	var istate: IntersectionState = IntersectionState()

     	init(_ renderer: SimpleRenderer) {
     		self.renderer = renderer
     	}

     	func run() {
     ByteUtil.InitByteUtil()

     while true {
     			var bx: UInt32
     			var by: UInt32

     			if renderer.bucketCounter >= renderer.numBuckets {
     				return
     			}

     by = UInt32(renderer.bucketCounter / renderer.numBucketsX)
     bx = UInt32(renderer.bucketCounter % renderer.numBucketsX)

     UI.printInfo(.ACCEL, "\trendering bucket num. \(renderer.bucketCounter) [\(bx)x\(by)]")

     renderer.bucketCounter += 1

     //renderer.renderBucket(bx, by, istate)
     		}
     }

     	func updateStats() {
     		renderer.scene!.accumulateStats(istate)
     	}

     func renderBucket(_ bx: UInt32, _ by: UInt32, _ istate: IntersectionState) {
     //  pixel sized extents
     let x0: Int32 = Int32(bx * 32)
     let y0: Int32 = Int32(by * 32)
     let bw: Int32 = min(32, renderer.imageWidth - x0)
     let bh: Int32 = min(32, renderer.imageHeight - y0)
     var bucketRGB: [Color] = [Color](repeating: Color(), count: Int(bw * bh))
     var bucketAlpha: [Float] = [Float](repeating: 0, count: Int(bw * bh))

     var i = 0
     for y in 0 ... bh - 1 {
     for x in 0 ... bw - 1 {
     let state: ShadingState? = renderer.scene!.getRadiance(istate, Float(x0 + x), Float(renderer.imageHeight - 1 - (y0 + y)), 0.0, 0.0, 0.0, 0, 0, nil)

     bucketRGB[i] = (state != nil ? state!.getResult() : Color.BLACK)!

     bucketAlpha[i] = (state != nil ? 1 : 0)

     i += 1
     }
     }

     //  update pixels
     renderer.display!.imageUpdate(x0, y0, bw, bh, bucketRGB, bucketAlpha)
     }
     }
     */
}
