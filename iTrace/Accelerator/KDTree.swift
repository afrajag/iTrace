//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

import Foundation

final class KDTree: AccelerationStructure {
    var tree: [Int32]?
    var primitives: [Int32]?
    var primitiveList: PrimitiveList?
    var bounds: BoundingBox?
    var maxPrims: Int32 = 0
    
    static var INTERSECT_COST: Float = 0.5
    static var TRAVERSAL_COST: Float = 1
    static var EMPTY_BONUS: Float = 0.2
    static var MAX_DEPTH: Int32 = 64
    
    static var dump: Bool = false
    static var dumpPrefix: String = "kdtree"
    
    static var CLOSED: Int64 = 0 << 30
    static var PLANAR: Int64 = 1 << 30
    static var OPENED: Int64 = 2 << 30
    static var TYPE_MASK: Int64 = 3 << 30
    
    required init() {}
    
    init(_ maxPrims: Int32) {
        self.maxPrims = maxPrims
    }
    
    static func setDumpMode(_ dump: Bool, _ prefix: String) {
        Self.dump = dump
        
        Self.dumpPrefix = prefix
    }
    
    func build(_ primitives: PrimitiveList) {
        UI.printDetailed(.ACCEL, "KDTree settings")
        UI.printDetailed(.ACCEL, "  * Max Leaf Size:  \(maxPrims)")
        UI.printDetailed(.ACCEL, "  * Max Depth:      \(Self.MAX_DEPTH)")
        UI.printDetailed(.ACCEL, "  * Traversal cost: \(Self.TRAVERSAL_COST)")
        UI.printDetailed(.ACCEL, "  * Intersect cost: \(Self.INTERSECT_COST)")
        UI.printDetailed(.ACCEL, "  * Empty bonus:    \(Self.EMPTY_BONUS)")
        UI.printDetailed(.ACCEL, "  * Dump leaves:    \(Self.dump ? "enabled" : "disabled")")
        
        let total: TraceTimer = TraceTimer()
        
        total.start()
        
        primitiveList = primitives
        
        //  get the object space bounds
        bounds = primitives.getWorldBounds(nil)
        
        let nPrim: Int32 = primitiveList!.getNumPrimitives()
        
        var nSplits: Int32 = 0
        
        var task: BuildTask? = BuildTask(nPrim)
        
        let prepare: TraceTimer = TraceTimer()
        
        prepare.start()
        
        for i in 0 ..< nPrim {
            for axis in 0 ..< 3 {
                let ls: Float = primitiveList!.getPrimitiveBound(i, Int32(2 * axis + 0))
                let rs: Float = primitiveList!.getPrimitiveBound(i, Int32(2 * axis + 1))
                
                if ls == rs {
                    //  flat in this dimension
                    task!.splits![Int(nSplits)] = Self.pack(ls, Self.PLANAR, Int32(axis), i)
                    
                    nSplits += 1
                } else {
                    task!.splits![Int(nSplits) + 0] = Self.pack(ls, Self.OPENED, Int32(axis), i)
                    task!.splits![Int(nSplits) + 1] = Self.pack(rs, Self.CLOSED, Int32(axis), i)
                    
                    nSplits += 2
                }
            }
        }
        
        task!.n = nSplits
        
        prepare.end()
        
        let t: TraceTimer = TraceTimer()
        
        var tempTree: [Int32] = [Int32]()
        var tempList: [Int32] = [Int32]()
        
        tempTree.append(0)
        tempTree.append(1)
        
        t.start()
        
        //  sort it
        let sorting: TraceTimer = TraceTimer()
        
        sorting.start()
        
        Self.radix12(task!, task!.n)
        //let v = task.splits.filter { $0 != 0 }.sorted()
        //task.splits = v
        
        sorting.end()
        
        //  build the actual tree
        let stats: BuildStats = BuildStats()
        
        buildTree(bounds!.getMinimum().x, bounds!.getMaximum().x, bounds!.getMinimum().y, bounds!.getMaximum().y, bounds!.getMinimum().z, bounds!.getMaximum().z, &task, 1, &tempTree, 0, &tempList, stats)
        
        t.end()
        
        //  write real arrays
        tree = tempTree

        self.primitives = tempList
        
        total.end()
        
        //  display some extra info
        stats.printStats()
        
        UI.printDetailed(.ACCEL, "  * Node memory:    \(Memory.sizeOf(tree))")
        UI.printDetailed(.ACCEL, "  * Object memory:  \(Memory.sizeOf(self.primitives))")
        UI.printDetailed(.ACCEL, "  * Prepare time:   \(prepare.toString())")
        UI.printDetailed(.ACCEL, "  * Sorting time:   \(sorting.toString())")
        UI.printDetailed(.ACCEL, "  * Tree creation:  \(t.toString())")
        UI.printDetailed(.ACCEL, "  * Build time:     \(total.toString())")
        
        if Self.dump {
            UI.printInfo(.ACCEL, "Dumping mtls to \(Self.dumpPrefix).mtl ...")
            
            var mtlFile: Data = Data() // StreamWriter(dumpPrefix + ".mtl")
            let maxN: Int32 = stats.maxObjects
            
            for n in 0 ... maxN {
                let blend: Float = Float(n) / Float(maxN)
                var nc: Color
                
                if blend < 0.25 {
                    nc = Color.blend(Color.BLUE, Color.GREEN, blend / 0.25)
                } else {
                    if blend < 0.5 {
                        nc = Color.blend(Color.GREEN, Color.YELLOW, (blend - 0.25) / 0.25)
                    } else {
                        if blend < 0.75 {
                            nc = Color.blend(Color.YELLOW, Color.RED, (blend - 0.5) / 0.25)
                        } else {
                            nc = Color.MAGENTA
                        }
                    }
                }
                
                mtlFile.append(contentsOf: "newmtl mtl\(n)\n".data(using: .ascii)!)
                
                let rgb: [Float] = nc.getRGB()
                
                mtlFile.append(contentsOf: "Ka 0.1 0.1 0.1\n".data(using: .ascii)!)
                mtlFile.append(contentsOf: "Kd \(rgb[0]) \(rgb[1]) \(rgb[2])\n".data(using: .ascii)!)
                mtlFile.append(contentsOf: "illum 1\n".data(using: .ascii)!)
            }
            
            try! mtlFile.write(to: NSURL.fileURL(withPath: KDTree.dumpPrefix + ".mtl"))
            
            var objFile: Data = Data() // StreamWriter(dumpPrefix + ".obj")
            
            UI.printInfo(.ACCEL, "Dumping tree to \(Self.dumpPrefix).obj ...")
            
            var _v: Int32? = 0
            
            _ = dumpObj(0, &_v, maxN, BoundingBox(bounds!), &objFile, &mtlFile)
            
            try! objFile.write(to: NSURL.fileURL(withPath: KDTree.dumpPrefix + ".obj"))
        }
    }

    func dumpObj(_ offset: Int32, _ vertOffset: inout Int32?, _ maxN: Int32, _ bounds: BoundingBox, _ file: inout Data, _ mtlFile: inout Data) -> Int32 {
        if offset == 0 {
            file.append(contentsOf: "mtllib \(Self.dumpPrefix).mtl\n".data(using: .ascii)!)
        }
        
        var nextOffset: Int32 = tree![Int(offset)]
        
        if (nextOffset & (3 << 30)) == (3 << 30) {
            //  leaf
            let n: Int32 = tree![Int(offset) + 1]
            
            if n > 0 {
                //  output the current voxel to the file
                let min: Point3 = bounds.getMinimum()
                let max: Point3 = bounds.getMaximum()
                
                file.append(contentsOf: "o node\(offset)\n".data(using: .ascii)!)
                file.append(contentsOf: "v \(max.x) \(max.y) \(min.z)\n".data(using: .ascii)!)
                file.append(contentsOf: "v \(max.x) \(min.y) \(min.z)\n".data(using: .ascii)!)
                file.append(contentsOf: "v \(min.x) \(min.y) \(min.z)\n".data(using: .ascii)!)
                file.append(contentsOf: "v \(min.x) \(max.y) \(min.z)\n".data(using: .ascii)!)
                file.append(contentsOf: "v \(max.x) \(max.y) \(max.z)\n".data(using: .ascii)!)
                file.append(contentsOf: "v \(max.x) \(min.y) \(max.z)\n".data(using: .ascii)!)
                file.append(contentsOf: "v \(min.x) \(min.y) \(max.z)\n".data(using: .ascii)!)
                file.append(contentsOf: "v \(min.x) \(max.y) \(max.z)\n".data(using: .ascii)!)
                
                let v0: Int32 = vertOffset!
                
                file.append(contentsOf: "usemtl mtl\(n)\n".data(using: .ascii)!)
                file.append(contentsOf: "s off\n".data(using: .ascii)!)
                file.append(contentsOf: "f \(v0 + 1) \(v0 + 2) \(v0 + 3) \(v0 + 4)\n".data(using: .ascii)!)
                file.append(contentsOf: "f \(v0 + 5) \(v0 + 8) \(v0 + 7) \(v0 + 6)\n".data(using: .ascii)!)
                file.append(contentsOf: "f \(v0 + 1) \(v0 + 5) \(v0 + 6) \(v0 + 2)\n".data(using: .ascii)!)
                file.append(contentsOf: "f \(v0 + 2) \(v0 + 6) \(v0 + 7) \(v0 + 3)\n".data(using: .ascii)!)
                file.append(contentsOf: "f \(v0 + 3) \(v0 + 7) \(v0 + 8) \(v0 + 4)\n".data(using: .ascii)!)
                file.append(contentsOf: "f \(v0 + 5) \(v0 + 1) \(v0 + 4) \(v0 + 8)\n".data(using: .ascii)!)
                
                vertOffset = vertOffset! + 8
            }
            
            return vertOffset!
        } else {
            // node, recurse
            let axis: Int32 = nextOffset & (3 << 30)
            var v0: Int32?
            let split: Float = ByteUtil.intBitsToFloat(tree![Int(offset) + 1])
            var min: Float
            var max: Float
            
            nextOffset &= ~(3 << 30)
            
            switch axis {
                case 0:
                    max = bounds.getMaximum().x
                    
                    bounds.getMaximum().x = split
                    
                    v0 = dumpObj(nextOffset, &vertOffset, maxN, bounds, &file, &mtlFile)
                    
                    bounds.getMaximum().x = max
                    
                    min = bounds.getMinimum().x
                    
                    bounds.getMinimum().x = split
                    
                    v0 = dumpObj(nextOffset + 2, &v0, maxN, bounds, &file, &mtlFile)
                    
                    bounds.getMinimum().x = min
                case 1 << 30:
                    max = bounds.getMaximum().y
                    
                    bounds.getMaximum().y = split
                    
                    v0 = dumpObj(nextOffset, &vertOffset, maxN, bounds, &file, &mtlFile)
                    
                    bounds.getMaximum().y = max
                    
                    min = bounds.getMinimum().y
                    
                    bounds.getMinimum().y = split
                    
                    v0 = dumpObj(nextOffset + 2, &v0, maxN, bounds, &file, &mtlFile)
                    
                    bounds.getMinimum().y = min
                case 2 << 30:
                    max = bounds.getMaximum().z
                    
                    bounds.getMaximum().z = split
                    
                    v0 = dumpObj(nextOffset, &vertOffset, maxN, bounds, &file, &mtlFile)
                    
                    bounds.getMaximum().z = max
                    
                    min = bounds.getMinimum().z
                    
                    bounds.getMinimum().z = split
                    
                    v0 = dumpObj(nextOffset + 2, &v0, maxN, bounds, &file, &mtlFile)
                    
                    bounds.getMinimum().z = min
                default:
                    v0 = vertOffset!
            }
            
            return v0!
        }
    }
    
    // pack split values into a 64bit integer
    static func pack(_ split: Float, _ type: Int64, _ axis: Int32, _ objectNum: Int32) -> Int64 {
        //  pack float in sortable form
        let f: Int32 = ByteUtil.floatToRawIntBits(split)
        let top: Int32 = f ^ ((f >> 31) | Int32(bitPattern: 0x80000000))
        
        var p: Int64 = (Int64(top) & Int64(bitPattern: 0xFFFFFFFF)) << 32
        
        p |= type // encode type as 2 bits
        
        p |= Int64(axis) << 28 // encode axis as 2 bits

        p |= (Int64(objectNum) & Int64(bitPattern: 0xFFFFFFF)) // pack object number
        
        return p
    }

    static func unpackObject(_ p: Int64) -> Int32 {
        return Int32(p & Int64(bitPattern: 0xFFFFFFF))
    }

    static func unpackAxis(_ p: Int64) -> Int32 {
        return Int32((p >>> 28) & 3)
    }

    static func unpackSplitType(_ p: Int64) -> Int64 {
        return p & TYPE_MASK
    }

    static func unpackSplit(_ p: Int64) -> Float {
        let f: Int32 = Int32(truncatingIfNeeded: ((p >>> 32) & Int64(bitPattern: 0xFFFFFFFF)))
        let m: Int32 = ((f >>> 31) - 1) | Int32(bitPattern: 0x80000000)
        
        return ByteUtil.intBitsToFloat(f ^ m)
    }

    // radix sort on top 36 bits - returns sorted result
    static func radix12(_ splits: BuildTask, _ n: Int32) {
        //  allocate working memory
        var hist: [Int32] = [Int32](repeating: 0, count: 2048)
        var sorted: [Int64] = [Int64](repeating: 0, count: Int(n))
        
        //  parallel histogramming pass
        for i in 0 ..< n {
            let pi: Int64 = splits.splits![Int(i)]
            
            hist[0x000 + Int((pi >>> 28) & 0x1FF)] += 1
            
            hist[0x200 + Int((pi >>> 37) & 0x1FF)] += 1
            
            hist[0x400 + Int((pi >>> 46) & 0x1FF)] += 1
            
            hist[0x600 + Int(pi >>> 55)] += 1
        }
        
        //  sum the histograms - each histogram entry records the number of
        //  values preceding itself.
        do {
            var sum0: Int32 = 0
            var sum1: Int32 = 0
            var sum2: Int32 = 0
            var sum3: Int32 = 0
            var tsum: Int32
            
            for i in 0 ..< 512 {
                tsum = hist[0x000 + i] + sum0
                
                hist[0x000 + i] = sum0 - 1
                
                sum0 = tsum
                
                tsum = hist[0x200 + i] + sum1
                
                hist[0x200 + i] = sum1 - 1
                
                sum1 = tsum
                
                tsum = hist[0x400 + i] + sum2
                
                hist[0x400 + i] = sum2 - 1
                
                sum2 = tsum
                
                tsum = hist[0x600 + i] + sum3
                
                hist[0x600 + i] = sum3 - 1
                
                sum3 = tsum
            }
        }
        
        //  read/write histogram passes
        for i in 0 ..< n {
            let pi: Int64 = splits.splits![Int(i)]
            let pos: Int = Int((pi >>> 28) & 0x1FF)
            
            hist[0x000 + pos] += 1
            sorted[Int(hist[0x000 + pos])] = pi
        }
        
        for i in 0 ..< n {
            let pi: Int64 = sorted[Int(i)]
            let pos: Int = Int((pi >>> 37) & 0x1FF)
            
            hist[0x200 + pos] += 1
            splits.splits![Int(hist[0x200 + pos])] = pi
        }
        
        for i in 0 ..< n {
            let pi: Int64 = splits.splits![Int(i)]
            let pos: Int = Int((pi >>> 46) & 0x1FF)
            
            hist[0x400 + pos] += 1
            sorted[Int(hist[0x400 + pos])] = pi
        }
        
        for i in 0 ..< n {
            let pi: Int64 = sorted[Int(i)]
            let pos: Int = Int(pi >>> 55)
            
            hist[0x600 + pos] += 1
            splits.splits![Int(hist[0x600 + pos])] = pi
        }
    }
    
    func buildTree(_ minx: Float, _ maxx: Float, _ miny: Float, _ maxy: Float, _ minz: Float, _ maxz: Float, _ task: inout BuildTask?, _ depth: Int32, _ tempTree: inout [Int32], _ offset: Int32, _ tempList: inout [Int32], _ stats: BuildStats) {
        //  get node bounding box extents
        if (task!.numObjects > maxPrims && depth < Self.MAX_DEPTH) {
            let dx: Float = maxx - minx
            let dy: Float = maxy - miny
            let dz: Float = maxz - minz
            
            //  search for best possible split
            var bestCost: Float = Self.INTERSECT_COST * Float(task!.numObjects)
            var bestAxis: Int32 = -1
            var bestOffsetStart: Int32 = -1
            var bestOffsetEnd: Int32 = -1
            var bestSplit: Float = 0
            var bestPlanarLeft: Bool = false
            var bnl: Int32 = 0
            var bnr: Int32 = 0
            
            //  inverse area of the bounding box (factor of 2 omitted)
            let area: Float = (dx * dy + dy * dz + dz * dx)
            let ISECT_COST: Float = Self.INTERSECT_COST / area
            
            //  setup counts for each axis
            var nl: [Int32] = [0, 0, 0]
            var nr: [Int32] = [task!.numObjects, task!.numObjects, task!.numObjects]
            
            //  setup bounds for each axis
            let dp: [Float] = [dy * dz, dz * dx, dx * dy]
            let ds: [Float] = [dy + dz, dz + dx, dx + dy]
            let nodeMin: [Float] = [minx, miny, minz]
            let nodeMax: [Float] = [maxx, maxy, maxz]
            
            //  search for best cost
            let nSplits: Int32 = task!.n
            var splits: [Int64]? = task!.splits
            var lrtable: [UInt8] = task!.leftRightTable
            
            var i: Int32 = 0
            
            while i < nSplits {
                //  extract current split
                let ptr: Int64 = splits![Int(i)]
                let split: Float = Self.unpackSplit(ptr)
                let axis: Int32 = Self.unpackAxis(ptr)
                
                //  mark current position
                let currentOffset: Int32 = i
                
                // count number of primitives start/stopping/lying on the
                // current plane
                var pClosed: Int32 = 0
                var pPlanar: Int32 = 0
                var pOpened: Int32 = 0
                
                let ptrMasked: Int64 = ptr & (~Self.TYPE_MASK & Int64(bitPattern: 0xFFFFFFFFF0000000))
                let ptrClosed: Int64 = ptrMasked | Self.CLOSED
                let ptrPlanar: Int64 = ptrMasked | Self.PLANAR
                let ptrOpened: Int64 = ptrMasked | Self.OPENED
                
                while (i < nSplits && (splits![Int(i)] & Int64(bitPattern: 0xFFFFFFFFF0000000)) == ptrClosed) {
                    let obj: Int32 = Self.unpackObject(splits![Int(i)])
                    
                    lrtable[Int(obj >>> 2)] = 0
                    
                    pClosed += 1
                    
                    i += 1
                }
                
                while (i < nSplits && (splits![Int(i)] & Int64(bitPattern: 0xFFFFFFFFF0000000)) == ptrPlanar) {
                    let obj: Int32 = Self.unpackObject(splits![Int(i)])
                    
                    lrtable[Int(obj >>> 2)] = 0
                    
                    pPlanar += 1
                    
                    i += 1
                }
                
                while (i < nSplits && (splits![Int(i)] & Int64(bitPattern: 0xFFFFFFFFF0000000)) == ptrOpened) {
                    let obj: Int32 = Self.unpackObject(splits![Int(i)])
                    
                    lrtable[Int(obj >>> 2)] = 0
                    
                    pOpened += 1
                    
                    i += 1
                }
                
                //  now we have summed all contributions from this plane
                nr[Int(axis)] -= pPlanar + pClosed
                
                //  compute cost
                if (split >= nodeMin[Int(axis)] && split <= nodeMax[Int(axis)]) {
                    //  left and right surface area (factor of 2 ommitted)
                    let dl: Float = split - nodeMin[Int(axis)]
                    let dr: Float = nodeMax[Int(axis)] - split
                    let lp: Float = dp[Int(axis)] + dl * ds[Int(axis)]
                    let rp: Float = dp[Int(axis)] + dr * ds[Int(axis)]
                    
                    //  planar prims go to smallest cell always
                    let planarLeft: Bool = dl < dr
                    let numLeft: Int32 = nl[Int(axis)] + (planarLeft ? pPlanar : 0)
                    let numRight: Int32 = nr[Int(axis)] + (planarLeft ? 0 : pPlanar)
                    let eb: Float = ((numLeft == 0 && dl > 0) || (numRight == 0 && dr > 0)) ? Self.EMPTY_BONUS : 0
                
                    let cost = Self.TRAVERSAL_COST + ISECT_COST * (1 - eb) * (lp * Float(numLeft) + rp * Float(numRight))

                    if cost < bestCost {
                        bestCost = cost
                        
                        bestAxis = axis
                        
                        bestSplit = split
                        
                        bestOffsetStart = currentOffset
                        
                        bestOffsetEnd = i
                        
                        bnl = numLeft
                        
                        bnr = numRight
                        
                        bestPlanarLeft = planarLeft
                    }
                }
                
                //  move objects left
                nl[Int(axis)] += pOpened + pPlanar
            }
            
            //  debug check for correctness of the scan
            for axis in 0 ..< 3 {
                let numLeft: Int32 = nl[axis]
                let numRight: Int32 = nr[axis]
                
                if (numLeft != task!.numObjects || numRight != 0) {
                    UI.printError(.ACCEL, "Didn\'t scan full range of objects @depth=\(depth). Left overs for axis \(axis): [L: \(numLeft)] [R: \(numRight)]")
                }
            }
            
            //  found best split
            if bestAxis != -1 {
                //  allocate space for child nodes
                var taskL: BuildTask? = BuildTask(bnl, task!)
                var taskR: BuildTask? = BuildTask(bnr, task!)
                
                var lk: Int32 = 0
                var rk: Int32 = 0
                
                for i in 0 ..< bestOffsetStart {
                    let ptr: Int64 = splits![Int(i)]
                    
                    if Self.unpackAxis(ptr) == bestAxis {
                        if Self.unpackSplitType(ptr) != Self.CLOSED {
                            let obj: Int32 = Self.unpackObject(ptr)
                            
                            lrtable[Int(obj >>> 2)] |= 1 << ((obj & 3) << 1)
                            
                            lk += 1
                        }
                    }
                }
                
                for i in bestOffsetStart ..< bestOffsetEnd {
                    let ptr: Int64 = splits![Int(i)]
                    
                    assert(Self.unpackAxis(ptr) == bestAxis)
                    
                    if Self.unpackSplitType(ptr) == Self.PLANAR {
                        if bestPlanarLeft {
                            let obj: Int32 = Self.unpackObject(ptr)
                            
                            lrtable[Int(obj >>> 2)] |= 1 << ((obj & 3) << 1)
                            
                            lk += 1
                        } else {
                            let obj: Int32 = Self.unpackObject(ptr)
                            
                            lrtable[Int(obj >>> 2)] |= 2 << ((obj & 3) << 1)
                            
                            rk += 1
                        }
                    }
                }
                
                for i in bestOffsetEnd ..< nSplits {
                    let ptr: Int64 = splits![Int(i)]
                    
                    if Self.unpackAxis(ptr) == bestAxis {
                        if Self.unpackSplitType(ptr) != Self.OPENED {
                            let obj: Int32 = Self.unpackObject(ptr)
                            
                            lrtable[Int(obj >>> 2)] |= 2 << ((obj & 3) << 1)
                            
                            rk += 1
                        }
                    }
                }
                
                //  output new splits while maintaining order
                // FIXME: swift passa gli array per copia e non per reference, quindi con = non vengono valorizzati i vecchi arrays
                //var splitsL: [Int64]? = taskL!.splits
                //var splitsR: [Int64]? = taskR!.splits
                var nsl: Int32 = 0
                var nsr: Int32 = 0
                
                for i in 0 ..< nSplits {
                    let ptr: Int64 = splits![Int(i)]
                    let obj: Int32 = Self.unpackObject(ptr)
                    let idx: Int32 = obj >>> 2
                   
                    let mask: Int32 = 1 << ((obj & 3) << 1)
                    
                    if (Int32(lrtable[Int(idx)]) & mask) != 0 {
                        //splitsL![Int(nsl)] = ptr
                        taskL!.splits![Int(nsl)] = ptr
                        
                        nsl += 1
                    }
                    
                    if (Int32(lrtable[Int(idx)]) & (mask << 1)) != 0 {
                        //splitsR![Int(nsr)] = ptr
                        taskR!.splits![Int(nsr)] = ptr
                        
                        nsr += 1
                    }
                }
                
                taskL!.n = nsl
                taskR!.n = nsr
                
                // FIXME: check if memory is really released
                //  free more memory
                task!.splits = nil
                splits = nil
                //splitsL = nil
                //splitsR = nil
                task = nil
                
                //  allocate child nodes
                let nextOffset: Int32 = Int32(tempTree.count)
                
                tempTree.append(0)
                tempTree.append(0)
                tempTree.append(0)
                tempTree.append(0)
                
                //  create current node
                tempTree[Int(offset) + 0] = (bestAxis << 30) | nextOffset
                tempTree[Int(offset) + 1] = ByteUtil.floatToRawIntBits(bestSplit)
                
                //  recurse for child nodes - free object arrays after each step
                stats.updateInner()
                
                switch bestAxis {
                    case 0:
                        buildTree(minx, bestSplit, miny, maxy, minz, maxz, &taskL, depth + 1, &tempTree, nextOffset, &tempList, stats)
                        
                        taskL = nil
                        
                        buildTree(bestSplit, maxx, miny, maxy, minz, maxz, &taskR, depth + 1, &tempTree, nextOffset + 2, &tempList, stats)
                        
                        taskR = nil
                        
                        return
                    case 1:
                        buildTree(minx, maxx, miny, bestSplit, minz, maxz, &taskL, depth + 1, &tempTree, nextOffset, &tempList, stats)
                        
                        taskL = nil
                        
                        buildTree(minx, maxx, bestSplit, maxy, minz, maxz, &taskR, depth + 1, &tempTree, nextOffset + 2, &tempList, stats)
                        
                        taskR = nil
                        
                        return
                    case 2:
                        buildTree(minx, maxx, miny, maxy, minz, bestSplit, &taskL, depth + 1, &tempTree, nextOffset, &tempList, stats)
                        
                        taskL = nil
                        
                        buildTree(minx, maxx, miny, maxy, bestSplit, maxz, &taskR, depth + 1, &tempTree, nextOffset + 2, &tempList, stats)
                        
                        taskR = nil
                        
                        return
                    default:
                        assert(false)
                }
            }
        }
        
        //  create leaf node
        let listOffset: Int32 = Int32(tempList.count)
        var n: Int32 = 0
        
        for i in 0 ..< task!.n {
            let ptr: Int64 = task!.splits![Int(i)]
            
            if (Self.unpackAxis(ptr) == 0 && Self.unpackSplitType(ptr) != Self.CLOSED) {
                tempList.append(Self.unpackObject(ptr))
                
                n += 1
            }
        }
        
        stats.updateLeaf(depth, n)
        
        if n != task!.numObjects {
            UI.printError(.ACCEL, "Error creating leaf node - expecting \(task!.numObjects) found \(n)")
        }
        
        tempTree[Int(offset) + 0] = (3 << 30) | listOffset
        tempTree[Int(offset) + 1] = task!.numObjects
        
        //  free some memory
        task!.splits = nil
    }
    
    func intersect(_ r: Ray, _ state: IntersectionState) {
        // FIXME: controllare se con variabili locali le performance aumentano
        let tree: [Int32]? = self.tree
        let primitives: [Int32]? = self.primitives
        let primitiveList: PrimitiveList? = self.primitiveList
        let bounds: BoundingBox? = self.bounds
        
        var intervalMin: Float = r.getMin()
        var intervalMax: Float = r.getMax()
        let orgX: Float = r.ox
        let dirX: Float = r.dx
        let invDirX: Float = 1 / dirX
        
        // slab test
        var t1: Float
        var t2: Float
        
        t1 = (bounds!.getMinimum().x - orgX) * invDirX
        t2 = (bounds!.getMaximum().x - orgX) * invDirX
        
        if invDirX > 0 {
            if t1 > intervalMin {
                intervalMin = t1
            }
            if t2 < intervalMax {
                intervalMax = t2
            }
        } else {
            if t2 > intervalMin {
                intervalMin = t2
            }
            if t1 < intervalMax {
                intervalMax = t1
            }
        }
        
        if intervalMin > intervalMax {
            return
        }
        
        
        let orgY: Float = r.oy
        let dirY: Float = r.dy
        let invDirY: Float = 1 / dirY
        
        
        t1 = (bounds!.getMinimum().y - orgY) * invDirY
        t2 = (bounds!.getMaximum().y - orgY) * invDirY
        
        if invDirY > 0 {
            if t1 > intervalMin {
                intervalMin = t1
            }
            if t2 < intervalMax {
                intervalMax = t2
            }
        } else {
            if t2 > intervalMin {
                intervalMin = t2
            }
            if t1 < intervalMax {
                intervalMax = t1
            }
        }
        
        if intervalMin > intervalMax {
            return
        }
        
        
        let orgZ: Float = r.oz
        let dirZ: Float = r.dz
        let invDirZ: Float = 1 / dirZ
        
        
        t1 = (bounds!.getMinimum().z - orgZ) * invDirZ
        t2 = (bounds!.getMaximum().z - orgZ) * invDirZ
        
        if invDirZ > 0 {
            if t1 > intervalMin {
                intervalMin = t1
            }
            if t2 < intervalMax {
                intervalMax = t2
            }
        } else {
            if t2 > intervalMin {
                intervalMin = t2
            }
            if t1 < intervalMax {
                intervalMax = t1
            }
        }
        
        if intervalMin > intervalMax {
            return
        }
       
        /*
        // alternative slab test
        let t0: Vector3 = (Vector3(bounds!.getMinimum().x, bounds!.getMinimum().y, bounds!.getMinimum().z) - Vector3(r.ox, r.oy, r.oz)) * Vector3(1 / r.dx, 1 / r.dy, 1 / r.dz)
        let t1: Vector3 = (Vector3(bounds!.getMaximum().x, bounds!.getMaximum().y, bounds!.getMaximum().z) - Vector3(r.ox, r.oy, r.oz)) * Vector3(1 / r.dx, 1 / r.dy, 1 / r.dz)
        let tmin: Vector3 = min(t0,t1)
        let tmax: Vector3 = max(t0,t1)
        
        if tmin.min() > tmax.max() {
            return
        }
        */
        
        //  compute custom offsets from direction sign bit
        let offsetXFront: Int32 = (ByteUtil.floatToRawIntBits(dirX) & (1 << 31)) >>> 30
        let offsetYFront: Int32 = (ByteUtil.floatToRawIntBits(dirY) & (1 << 31)) >>> 30
        let offsetZFront: Int32 = (ByteUtil.floatToRawIntBits(dirZ) & (1 << 31)) >>> 30
        
        let offsetXBack: Int32 = offsetXFront ^ 2
        let offsetYBack: Int32 = offsetYFront ^ 2
        let offsetZBack: Int32 = offsetZFront ^ 2
        
        var stack: [IntersectionState.StackNode] = state.getStack()
        var stackPos: Int32 = 0
        var node: Int32 = 0
        
        while true {
            let tn: Int32 = tree![Int(node)]
            let axis: Int32 = tn & (3 << 30)
            var offset: Int32 = tn & ~(3 << 30)
            
            switch axis {
                case 0:
                    do {
                        let d: Float = (ByteUtil.intBitsToFloat(tree![Int(node) + 1]) - orgX) * invDirX
                        let back: Int32 = offset + offsetXBack
                        
                        node = back
                        
                        if d < intervalMin {
                            continue
                        }
                        
                        node = offset + offsetXFront //  front
                        
                        if d > intervalMax {
                            continue
                        }
                        
                        //  push back node
                        stack[Int(stackPos)].node = back
                        stack[Int(stackPos)].near = (d >= intervalMin ? d : intervalMin)
                        stack[Int(stackPos)].far = intervalMax
                        
                        stackPos += 1
                        
                        //  update ray interval for front node
                        intervalMax = (d <= intervalMax) ? d : intervalMax
                        
                        continue
                    }
                case 1 << 30:
                    do {
                        //  y axis
                        let d: Float = (ByteUtil.intBitsToFloat(tree![Int(node) + 1]) - orgY) * invDirY
                        let back: Int32 = offset + offsetYBack
                        
                        node = back
                        
                        if d < intervalMin {
                            continue
                        }
                        
                        node = offset + offsetYFront //  front
                        
                        if d > intervalMax {
                            continue
                        }
                        
                        //  push back node
                        stack[Int(stackPos)].node = back
                        stack[Int(stackPos)].near = (d >= intervalMin) ?  d : intervalMin
                        stack[Int(stackPos)].far = intervalMax
                        
                        stackPos += 1
                        
                        //  update ray interval for front node
                        intervalMax = (d <= intervalMax) ?  d : intervalMax
                        
                        continue
                    }
            case 2 << 30:
                do {
                    //  z axis
                    let d: Float = (ByteUtil.intBitsToFloat(tree![Int(node) + 1]) - orgZ) * invDirZ
                    let back: Int32 = offset + offsetZBack
                    
                    node = back
                    
                    if d < intervalMin {
                        continue
                    }
                    
                    node = offset + offsetZFront //  front
                    
                    if d > intervalMax {
                        continue
                    }
                    
                    //  push back node
                    stack[Int(stackPos)].node = back
                    stack[Int(stackPos)].near = (d >= intervalMin) ? d : intervalMin
                    stack[Int(stackPos)].far = intervalMax
                    
                    stackPos += 1
                    
                    //  update ray interval for front node
                    intervalMax = (d <= intervalMax) ? d : intervalMax
                    
                    continue
                }
            default:
                    do {
                        //  leaf - test some objects
                        var n: Int32 = tree![Int(node) + 1]
                        
                        while n > 0 {
                            primitiveList!.intersectPrimitive(r, primitives![Int(offset)], state)
                            
                            n -= 1
                            
                            offset += 1
                        }
                        
                        if r.getMax() < intervalMax {
                            return
                        }
                        
                        repeat {
                            //  stack is empty
                            if stackPos == 0 {
                                return
                            }
                            
                            //  move back up the stack
                            stackPos -= 1
                            
                            intervalMin = stack[Int(stackPos)].near
                            
                            if r.getMax() < intervalMin {
                                continue
                            }
                            
                            node = stack[Int(stackPos)].node
                            
                            intervalMax = stack[Int(stackPos)].far
                            
                            break
                        } while true
                        
                        break
                    }
            }
            //  switch
        } //  traversal loop
    }
    
    final class BuildStats {
        var numNodes: Int32 = 0
        var numLeaves: Int32 = 0
        var sumObjects: Int32 = 0
        var minObjects: Int32 = 0
        var maxObjects: Int32 = 0
        var sumDepth: Int32 = 0
        var minDepth: Int32 = 0
        var maxDepth: Int32 = 0
        var numLeaves0: Int32 = 0
        var numLeaves1: Int32 = 0
        var numLeaves2: Int32 = 0
        var numLeaves3: Int32 = 0
        var numLeaves4: Int32 = 0
        var numLeaves4p: Int32 = 0
        
        init() {
            numNodes = 0
            numLeaves = 0
            sumObjects = 0
            minObjects = Int32.max
            maxObjects = Int32.min
            sumDepth = 0
            minDepth = Int32.max
            maxDepth = Int32.min
            numLeaves0 = 0
            numLeaves1 = 0
            numLeaves2 = 0
            numLeaves3 = 0
            numLeaves4 = 0
            numLeaves4p = 0
        }
        
        func updateInner() {
            numNodes += 1
        }
        
        func updateLeaf(_ depth: Int32, _ n: Int32) {
            numLeaves += 1
            
            minDepth = min(depth, minDepth)
            maxDepth = max(depth, maxDepth)
            
            sumDepth += depth
            
            minObjects = min(n, minObjects)
            maxObjects = max(n, maxObjects)
            
            sumObjects += n
            
            switch n {
                case 0:
                    numLeaves0 += 1
                case 1:
                    numLeaves1 += 1
                case 2:
                    numLeaves2 += 1
                case 3:
                    numLeaves3 += 1
                case 4:
                    numLeaves4 += 1
                default:
                    numLeaves4p += 1
            }
        }
        
        func printStats() {
            UI.printDetailed(.ACCEL, "KDTree stats:")
            UI.printDetailed(.ACCEL, "  * Nodes:          \(numNodes)")
            UI.printDetailed(.ACCEL, "  * Leaves:         \(numLeaves)")
            UI.printDetailed(.ACCEL, "  * Objects: min    \(minObjects)")
            UI.printDetailed(.ACCEL, "             avg    \(Float(sumObjects) / Float(numLeaves))")
            UI.printDetailed(.ACCEL, "           avg(n>0) \(Float(sumObjects) / Float(numLeaves - numLeaves0))")
            UI.printDetailed(.ACCEL, "             max    \(maxObjects)")
            UI.printDetailed(.ACCEL, "  * Depth:   min    \(minDepth)")
            UI.printDetailed(.ACCEL, "             avg    \(Float(sumDepth) / Float(numLeaves))")
            UI.printDetailed(.ACCEL, "             max    \(maxDepth)")
            UI.printDetailed(.ACCEL, "  * Leaves w/: N=0  \((100 * numLeaves0) / numLeaves)")
            UI.printDetailed(.ACCEL, "               N=1  \((100 * numLeaves1) / numLeaves)")
            UI.printDetailed(.ACCEL, "               N=2  \((100 * numLeaves2) / numLeaves)")
            UI.printDetailed(.ACCEL, "               N=3  \((100 * numLeaves3) / numLeaves)")
            UI.printDetailed(.ACCEL, "               N=4  \((100 * numLeaves4) / numLeaves)")
            UI.printDetailed(.ACCEL, "               N>4  \((100 * numLeaves4p) / numLeaves)")
        }
    }
    
    final class BuildTask {
        var splits: [Int64]?
        var numObjects: Int32 = 0
        var n: Int32 = 0
        var leftRightTable: [UInt8]
        
        init(_ numObjects: Int32) {
            splits = [Int64](repeating: 0, count: 6 * Int(numObjects))
            
            self.numObjects = numObjects
            
            n = 0
            
            //  2 bits per object
            leftRightTable = [UInt8](repeating: 0, count: (Int(numObjects) + 3) / 4)
        }
        
        init(_ numObjects: Int32, _ parent: BuildTask) {
            splits = [Int64](repeating: 0, count: 6 * Int(numObjects))
            
            self.numObjects = numObjects
            
            n = 0
            
            leftRightTable = parent.leftRightTable
        }
    }
}
