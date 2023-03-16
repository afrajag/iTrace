//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

import Foundation

final class ProgressiveRenderer: ImageSampler {
    var scene: Scene?
    var smallBucketQueue: [SmallBucket]?
    var display: Display?
    var imageWidth: Int32 = 0
    var imageHeight: Int32 = 0
    var counter: Int32 = 0
    var counterMax: Int32 = 0

    var numThreads: Int = ProcessInfo().processorCount
    
    let lockQueue = DispatchQueue(label: "progressiverender.lock.serial.queue")
    
    required init() {
        imageWidth = 640
        imageHeight = 480
        
        smallBucketQueue = nil
    }

    func prepare(_: Options, _ scene: Scene, _ w: Int32, _ h: Int32) -> Bool {
        self.scene = scene
        
        imageWidth = w
        imageHeight = h
        
        //  prepare table used by deterministic anti-aliasing
        return true
    }

    func render(_ display: Display) {
        self.display = display
        
        display.imageBegin(imageWidth, imageHeight, 0)
        
        //  create first bucket
        let b: SmallBucket = SmallBucket()
        
        b.x = 0
        b.y = 0
        
        let s: Int32 = max(imageWidth, imageHeight)
        
        b.size = 1
        
        while b.size < s {
            b.size <<= 1
        }
        
        smallBucketQueue = [SmallBucket]()

        smallBucketQueue!.append(b)
        
        UI.taskStart("Progressive Render", 0, imageWidth * imageHeight)
        
        let t: TraceTimer = TraceTimer()
        
        t.start()
        
        counter = 0
        
        counterMax = imageWidth * imageHeight
        
        let renderQueue = DispatchQueue(label: "progressiverender.queue", qos: .userInitiated, attributes: .concurrent)

        let threadGroup = DispatchGroup()
        
        print("created thread group")
        
        for _ in 0 ..< numThreads {
            print("entering group ...")
            threadGroup.enter()
              
            print("entered")
            
            renderQueue.async {
                let istate: IntersectionState = IntersectionState()
                
                while true {
                    let n: Int32 = self.progressiveRenderNext(istate)
                    
                    if self.counter >= self.counterMax {
                        break
                    }
                    
                    self.lockQueue.sync { // synchronized block
                        self.counter += n
                    }
                    
                    UI.taskUpdate(self.counter)

                    if UI.taskCanceled() {
                        return
                    }
                }
                
                self.updateStats(istate)
                
                print("leaving group ...")
                
                threadGroup.leave()
            }
            
            print("leaved")
        }

        print("waiting for group ...")
        
        renderQueue.sync {
            threadGroup.wait()
        }
        
        /*
         func run() {
             ByteUtil.InitByteUtil()
             
             while true {
                 var n: Int32 = renderer.progressiveRenderNext(istate)
                 
                 // FIXME: copiare da SimpleRender e rivedere la parte di lock
                 if renderer.counter >= renderer.counterMax {
                     return
                 }
                 
                 renderer.counter = renderer.counter + n
                 
                 UI.taskUpdate(renderer.counter)

                 if UI.taskCanceled() {
                     return
                 }
             }
         }
         
        var renderThreads: [SmallBucketThread] = [SmallBucketThread](repeating: 0, count: scene.getThreads())
        
        for i in 0 ..< renderThreads.count {
            renderThreads[i] = SmallBucketThread(self)
            renderThreads[i].setPriority(scene.getThreadPriority())
            renderThreads[i].start()
        }
        
        for i in 0 ... renderThreads.count - 1 {
            renderThreads[i].join()

            renderThreads[i].updateStats()

            // UI.printError(.IPR, "Thread \(xxx) of \(xxx) was interrupted", i + 1, renderThreads.count)
        }
        */
        
        UI.taskStop()
        
        t.end()
        
        UI.printInfo(.IPR, "Rendering time: \(t.toString())")
        
        display.imageEnd()
    }

    func progressiveRenderNext(_ istate: IntersectionState) -> Int32 {
        let TASK_SIZE: Int32 = 16
        var first: SmallBucket?
        
        self.lockQueue.sync { // synchronized block
            first = (smallBucketQueue!.count > 0 ? smallBucketQueue!.popLast() : nil)
        }
        
        if first == nil {
            return 0
        }
        
        let ds: Int32 = first!.size / TASK_SIZE
        let useMask: Bool = smallBucketQueue!.count != 0
        let mask: Int32 = 2 * first!.size / TASK_SIZE - 1
        var pixels: Int32 = 0
        
        var y = first!.y
        var i: Int = 0
        
        while i < TASK_SIZE && y < imageHeight {
            var x = first!.x
            var j: Int = 0
            
            while j < TASK_SIZE && x < imageWidth {
                //  check to see if this is a pixel from a higher level tile
                if useMask && (x & mask) == 0 && (y & mask) == 0 {
                    j += 1
                    x += ds
                    
                    continue
                }
                
                let instance: Int32 = ((x & ((1 << QMC.MAX_SIGMA_ORDER) - 1)) << QMC.MAX_SIGMA_ORDER) + QMC.sigma(y & ((1 << QMC.MAX_SIGMA_ORDER) - 1), QMC.MAX_SIGMA_ORDER)
                let time: Double = QMC.halton(1, instance)
                let lensU: Double = QMC.halton(2, instance)
                let lensV: Double = QMC.halton(3, instance)
                let state: ShadingState? = scene!.getRadiance(istate, Float(x), Float(imageHeight) - 1 - Float(y), lensU, lensV, time, instance, 4, nil)
                let c: Color = state != nil ? state!.getResult()! : Color.BLACK
                
                pixels += 1
                
                //  fill region
                display!.imageFill(x, y, min(ds, imageWidth - x), min(ds, imageHeight - y), c, state == nil ? 0 : 1)
                
                j += 1
                x += ds
            }
            
            i += 1
            y += ds
        }
        
        if first!.size >= 2 * TASK_SIZE {
            //  generate child buckets
            let size: Int32 = first!.size >>> 1
            
            for i in 0 ..< 2 {
                if first!.y + Int32(i) * size < imageHeight {
                    for j in 0 ..< 2 {
                        if first!.x + Int32(j) * size < imageWidth {
                            let b: SmallBucket = SmallBucket()
                            
                            b.x = first!.x + Int32(j) * size
                            b.y = first!.y + Int32(i) * size
                            
                            b.size = size
                            
                            b.constrast = 1.0 / Float(size)
                            
                            smallBucketQueue!.append(b)
                        }
                    }
                }
            }
        }
        
        return pixels
    }

    func updateStats(_ istate: IntersectionState) {
        scene!.accumulateStats(istate)
    }
    
    /*
    final class SmallBucketThread {
        var renderer: ProgressiveRenderer
        var thread: Thread
        var istate: IntersectionState = IntersectionState()

        init(_ renderer: ProgressiveRenderer) {
            self.renderer = renderer
            
            thread = Thread(ThreadStart(run))
            
            thread.IsBackground = true
        }

        func run() {
            ByteUtil.InitByteUtil()
            
            while true {
                var n: Int32 = renderer.progressiveRenderNext(istate)
                
                // FIXME: copiare da SimpleRender e rivedere la parte di lock
                if renderer.counter >= renderer.counterMax {
                    return
                }
                
                renderer.counter = renderer.counter + n
                
                UI.taskUpdate(renderer.counter)

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

        func join() {
            thread.Join()
        }

        func updateStats() {
            renderer.scene.accumulateStats(istate)
        }
    }
    */
    
    final class SmallBucket: Comparable {
        var constrast: Float = 0.0
        var x: Int32 = 0
        var y: Int32 = 0
        var size: Int32 = 0

        static func < (lhs: ProgressiveRenderer.SmallBucket, rhs: ProgressiveRenderer.SmallBucket) -> Bool {
            if lhs.constrast < rhs.constrast {
                return true
            }
            
            return false
        }
        
        static func == (lhs: ProgressiveRenderer.SmallBucket, rhs: ProgressiveRenderer.SmallBucket) -> Bool {
            if lhs.constrast == rhs.constrast {
                return true
            }
            
            return false
        }
    }
}
