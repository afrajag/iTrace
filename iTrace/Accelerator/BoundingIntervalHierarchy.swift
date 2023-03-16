//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class BoundingIntervalHierarchy: AccelerationStructure {
    // FIXME: provare a spostare il tree in una variabile locale, perche' accedere alle variabili d'istanza e' piu' pesante
    var tree: [Int32]?
    var objects: [Int32]?
    var primitives: PrimitiveList?
    var bounds: BoundingBox?
    var maxPrims: Int32 = 0

    required init() {
        maxPrims = 2
    }

    func build(_ primitives: PrimitiveList) {
        self.primitives = primitives

        let n: Int32 = primitives.getNumPrimitives()

        UI.printDetailed(.ACCEL, "Getting bounding box ...")

        bounds = primitives.getWorldBounds(nil)

        objects = [Int32]()

        for i in 0 ..< n {
            objects!.append(i)
        }

        UI.printDetailed(.ACCEL, "Creating tree ...")

        let initialSize: Int32 = 3 * (2 * 6 * n + 1)

        tree = [Int32]()

        let stats: BuildStats = BuildStats()

        let t: TraceTimer = TraceTimer()

        t.start()

        buildHierarchy(stats)

        t.end()

        //  display stats
        stats.printStats()

        UI.printDetailed(.ACCEL, "  * Creation time:  \(t.toString())")
        UI.printDetailed(.ACCEL, "  * Usage of init:  \(Double(100 * tree!.count) / Double(initialSize))%")
        UI.printDetailed(.ACCEL, "  * Tree memory:    \(Memory.sizeOf(tree!))")
        UI.printDetailed(.ACCEL, "  * Indices memory: \(Memory.sizeOf(objects!))\n")
    }

    func buildHierarchy(_ stats: BuildStats) {
        //  create space for the first node
        tree!.append(3 << 30) //  dummy leaf
        tree!.append(0)
        tree!.append(0)

        if objects!.isEmpty {
            return
        }

        //  seed bbox
        var gridBox: [Float]? = [Float]([bounds!.getMinimum().x, bounds!.getMaximum().x, bounds!.getMinimum().y, bounds!.getMaximum().y, bounds!.getMinimum().z, bounds!.getMaximum().z])

        var nodeBox: [Float]? = [Float]([bounds!.getMinimum().x, bounds!.getMaximum().x, bounds!.getMinimum().y, bounds!.getMaximum().y, bounds!.getMinimum().z, bounds!.getMaximum().z])

        let left: Int32 = 0
        let right: Int32 = Int32(objects!.count - 1)

        let nodeIndex: Int32 = 0
        let depth: Int32 = 1

        //  seed subdivide function
        subdivide(left, right, &gridBox, &nodeBox, nodeIndex, depth, stats)
    }

    func createNode(_ nodeIndex: Int32, _ left: Int32, _ right: Int32) {
        //  write leaf node
        tree![Int(nodeIndex) + 0] = (3 << 30) | left
        tree![Int(nodeIndex) + 1] = (right - left) + 1
    }

    func subdivide(_ left: Int32, _ right: Int32, _ gridBox: inout [Float]?, _ nodeBox: inout [Float]?, _ nodeIndex: Int32, _ depth: Int32, _ stats: BuildStats) {
        let _left = left
        var _right = right
        var _nodeIndex = nodeIndex
        var _depth = depth

        // calculate extents
        var axis: Int32 = -1
        var prevAxis: Int32
        var rightOrig: Int32 = 0
        var clipL: Float = Float.nan
        var clipR: Float = Float.nan
        var prevClip: Float = Float.nan
        var split: Float = Float.nan
        var prevSplit: Float
        var wasLeft: Bool = true

        if ((_right - _left + 1) <= maxPrims) || (_depth >= 64) {
            //  write leaf node
            stats.updateLeaf(_depth, _right - _left + 1)

            createNode(_nodeIndex, _left, _right)

            return
        }

        while true {
            prevAxis = axis
            prevSplit = split

            //  perform quick consistency checks
            let d: [Float] = [gridBox![1] - gridBox![0], gridBox![3] - gridBox![2], gridBox![5] - gridBox![4]]

            if (d[0] < 0) || (d[1] < 0) || (d[2] < 0) {
                fatalError("BIH: Negative node extents")
            }

            for i in 0 ..< 3 {
                if (nodeBox![2 * i + 1] < gridBox![2 * i]) || (nodeBox![2 * i] > gridBox![2 * i + 1]) {
                    UI.printError(.ACCEL, "Reached tree area in error - discarding node with: \(_right - _left + 1) objects!")

                    fatalError("BIH: Invalid node overlap")
                }
            }

            //  find longest axis
            if d[0] > d[1], d[0] > d[2] {
                axis = 0
            } else if d[1] > d[2] {
                axis = 1
            } else {
                axis = 2
            }

            split = 0.5 * (gridBox![2 * Int(axis)] + gridBox![2 * Int(axis) + 1])

            //  partition L/R subsets
            clipL = -Float.infinity
            clipR = Float.infinity

            rightOrig = _right //  save this for later

            var nodeL: Float = Float.infinity
            var nodeR: Float = -Float.infinity

            var i: Int32 = _left

            while i <= _right {
                let obj: Int32 = objects![Int(i)]
                let minb: Float = primitives!.getPrimitiveBound(obj, 2 * axis + 0)
                let maxb: Float = primitives!.getPrimitiveBound(obj, 2 * axis + 1)
                let center: Float = (minb + maxb) * 0.5

                if center <= split {
                    //  stay left
                    i += 1

                    if clipL < maxb {
                        clipL = maxb
                    }
                } else {
                    //  move to the right most
                    let t: Int32 = objects![Int(i)]

                    objects![Int(i)] = objects![Int(_right)]
                    objects![Int(_right)] = t

                    _right -= 1

                    if clipR > minb {
                        clipR = minb
                    }
                }

                if nodeL > minb {
                    nodeL = minb
                }

                if nodeR < maxb {
                    nodeR = maxb
                }
            }

            //  check for empty space
            if nodeL > nodeBox![(2 * Int(axis)) + 0], nodeR < nodeBox![2 * Int(axis) + 1] {
                let nodeBoxW: Float = nodeBox![2 * Int(axis) + 1] - nodeBox![2 * Int(axis) + 0]
                let nodeNewW: Float = nodeR - nodeL

                //  node box is too big compare to space occupied by primitives
                if (1.3 * nodeNewW) < nodeBoxW {
                    stats.updateBVH2()

                    let nextIndex: Int32 = Int32(tree!.count)

                    //  allocate child
                    tree!.append(0)
                    tree!.append(0)
                    tree!.append(0)

                    //  write bvh2 clip node
                    stats.updateInner()

                    tree![Int(_nodeIndex) + 0] = (axis << 30) | (1 << 29) | nextIndex
                    tree![Int(_nodeIndex) + 1] = ByteUtil.floatToRawIntBits(nodeL)
                    tree![Int(_nodeIndex) + 2] = ByteUtil.floatToRawIntBits(nodeR)

                    //  update nodebox and recurse
                    nodeBox![2 * Int(axis) + 0] = nodeL
                    nodeBox![2 * Int(axis) + 1] = nodeR

                    subdivide(_left, rightOrig, &gridBox, &nodeBox, nextIndex, _depth + 1, stats)

                    return
                }
            }

            //  ensure we are making progress in the subdivision
            if _right == rightOrig {
                //  all left
                if clipL <= split, gridBox![2 * Int(axis) + 1] != split {
                    //  keep looping on left half
                    gridBox![2 * Int(axis) + 1] = split

                    prevClip = clipL

                    wasLeft = true

                    continue
                }

                if prevAxis == axis, prevSplit == split {
                    //  we are stuck here - create a leaf
                    stats.updateLeaf(_depth, _right - _left + 1)

                    createNode(_nodeIndex, _left, _right)

                    return
                }

                gridBox![2 * Int(axis) + 1] = split

                prevClip = Float.nan
            } else if _left > _right {
                //  all right
                _right = rightOrig

                if clipR >= split, gridBox![2 * Int(axis) + 0] != split {
                    //  keep looping on right half
                    gridBox![2 * Int(axis) + 0] = split

                    prevClip = clipR

                    wasLeft = false

                    continue
                }

                if prevAxis == axis, prevSplit == split {
                    //  we are stuck here - create a leaf
                    stats.updateLeaf(_depth, _right - _left + 1)

                    createNode(_nodeIndex, _left, _right)

                    return
                }

                gridBox![2 * Int(axis) + 0] = split

                prevClip = Float.nan
            } else {
                //  we are actually splitting stuff
                if prevAxis != -1, !prevClip.isNaN {
                    //  second time through - lets create the previous split
                    //  since it produced empty space
                    let nextIndex: Int32 = Int32(tree!.count)

                    //  allocate child node
                    tree!.append(0)
                    tree!.append(0)
                    tree!.append(0)

                    if wasLeft {
                        //  create a node with a left child
                        //  write leaf node
                        stats.updateInner()

                        tree![Int(_nodeIndex) + 0] = (prevAxis << 30) | nextIndex
                        tree![Int(_nodeIndex) + 1] = ByteUtil.floatToRawIntBits(prevClip)
                        tree![Int(_nodeIndex) + 2] = ByteUtil.floatToRawIntBits(Float.infinity)
                    } else {
                        //  create a node with a right child
                        //  write leaf node
                        stats.updateInner()

                        tree![Int(_nodeIndex) + 0] = (prevAxis << 30) | (nextIndex - 3)
                        tree![Int(_nodeIndex) + 1] = ByteUtil.floatToRawIntBits(-Float.infinity)
                        tree![Int(_nodeIndex) + 2] = ByteUtil.floatToRawIntBits(prevClip)
                    }

                    //  count stats for the unused leaf
                    _depth += 1

                    stats.updateLeaf(_depth, 0)

                    //  now we keep going as we are, with a new nodeIndex:
                    _nodeIndex = nextIndex
                }

                break
            }
        }

        //  compute index of child nodes
        var nextIndex1: Int32 = Int32(tree!.count)

        //  allocate left node
        let nl: Int32 = _right - _left + 1
        let nr: Int32 = rightOrig - (_right + 1) + 1

        if nl > 0 {
            tree!.append(0)
            tree!.append(0)
            tree!.append(0)
        } else {
            nextIndex1 -= 3
        }

        //  allocate right node
        if nr > 0 {
            tree!.append(0)
            tree!.append(0)
            tree!.append(0)
        }

        //  write leaf node
        stats.updateInner()

        tree![Int(_nodeIndex) + 0] = (axis << 30) | nextIndex1
        tree![Int(_nodeIndex) + 1] = ByteUtil.floatToRawIntBits(clipL)
        tree![Int(_nodeIndex) + 2] = ByteUtil.floatToRawIntBits(clipR)

        //  prepare L/R child boxes
        var gridBoxL: [Float]? = [Float]([Float](repeating: 0, count: 6))
        var gridBoxR: [Float]? = [Float]([Float](repeating: 0, count: 6))
        var nodeBoxL: [Float]? = [Float]([Float](repeating: 0, count: 6))
        var nodeBoxR: [Float]? = [Float]([Float](repeating: 0, count: 6))

        for i in 0 ..< 6 {
            gridBoxL![i] = gridBox![i]
            gridBoxR![i] = gridBox![i]
            nodeBoxL![i] = nodeBox![i]
            nodeBoxR![i] = nodeBox![i]
        }

        gridBoxL![2 * Int(axis) + 1] = split
        gridBoxR![2 * Int(axis)] = split

        nodeBoxL![2 * Int(axis) + 1] = clipL
        nodeBoxR![2 * Int(axis) + 0] = clipR

        // FIXME: check if memory is really released
        gridBox = nil
        nodeBox = nil

        //  recurse
        if nl > 0 {
            subdivide(_left, _right, &gridBoxL, &nodeBoxL, nextIndex1, _depth + 1, stats)
        } else {
            stats.updateLeaf(_depth + 1, 0)
        }

        if nr > 0 {
            subdivide(_right + 1, rightOrig, &gridBoxR, &nodeBoxR, nextIndex1 + 3, _depth + 1, stats)
        } else {
            stats.updateLeaf(_depth + 1, 0)
        }
    }

    func intersect(_ r: Ray, _ state: IntersectionState) {
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

        //  compute custom offsets from direction sign bit
        var offsetXFront: Int32 = ByteUtil.floatToRawIntBits(dirX) >>> 31
        var offsetYFront: Int32 = ByteUtil.floatToRawIntBits(dirY) >>> 31
        var offsetZFront: Int32 = ByteUtil.floatToRawIntBits(dirZ) >>> 31

        var offsetXBack: Int32 = offsetXFront ^ 1
        var offsetYBack: Int32 = offsetYFront ^ 1
        var offsetZBack: Int32 = offsetZFront ^ 1

        let offsetXFront3: Int32 = offsetXFront * 3
        let offsetYFront3: Int32 = offsetYFront * 3
        let offsetZFront3: Int32 = offsetZFront * 3

        let offsetXBack3: Int32 = offsetXBack * 3
        let offsetYBack3: Int32 = offsetYBack * 3
        let offsetZBack3: Int32 = offsetZBack * 3

        //  avoid always adding 1 during the inner loop
        offsetXFront += 1
        offsetYFront += 1
        offsetZFront += 1
        offsetXBack += 1
        offsetYBack += 1
        offsetZBack += 1

        var stack: [IntersectionState.StackNode] = state.getStack()
        var stackPos: Int32 = 0
        var node: Int32 = 0

        while true {
            pushloop: while true {
                let tn: Int32 = tree![Int(node)]
                let axis: Int32 = tn & (7 << 29)
                var offset: Int32 = tn & ~(7 << 29)

                switch axis {
                    case 0:
                        //  x axis
                        let tf: Float = (ByteUtil.intBitsToFloat(tree![Int(node + offsetXFront)]) - orgX) * invDirX
                        let tb: Float = (ByteUtil.intBitsToFloat(tree![Int(node + offsetXBack)]) - orgX) * invDirX

                        //  ray passes between clip zones
                        if tf < intervalMin, tb > intervalMax {
                            break pushloop
                        }

                        let back: Int32 = offset + offsetXBack3

                        node = back

                        //  ray passes through far node only
                        if tf < intervalMin {
                            intervalMin = (tb >= intervalMin ? tb : intervalMin)

                            continue
                        }

                        node = offset + offsetXFront3 //  front

                        //  ray passes through near node only
                        if tb > intervalMax {
                            intervalMax = (tf <= intervalMax ? tf : intervalMax)

                            continue
                        }

                        //  ray passes through both nodes
                        //  push back node
                        stack[Int(stackPos)].node = back
                        stack[Int(stackPos)].near = (tb >= intervalMin ? tb : intervalMin)
                        stack[Int(stackPos)].far = intervalMax

                        stackPos += 1

                        //  update ray interval for front node
                        intervalMax = (tf <= intervalMax ? tf : intervalMax)
                    case 1 << 30:
                        let tf: Float = (ByteUtil.intBitsToFloat(tree![Int(node + offsetYFront)]) - orgY) * invDirY
                        let tb: Float = (ByteUtil.intBitsToFloat(tree![Int(node + offsetYBack)]) - orgY) * invDirY

                        //  ray passes between clip zones
                        if tf < intervalMin, tb > intervalMax {
                            break pushloop
                        }

                        let back: Int32 = offset + offsetYBack3

                        node = back

                        //  ray passes through far node only
                        if tf < intervalMin {
                            intervalMin = (tb >= intervalMin ? tb : intervalMin)

                            continue
                        }

                        node = offset + offsetYFront3 //  front

                        //  ray passes through near node only
                        if tb > intervalMax {
                            intervalMax = (tf <= intervalMax ? tf : intervalMax)

                            continue
                        }

                        //  ray passes through both nodes
                        //  push back node
                        stack[Int(stackPos)].node = back
                        stack[Int(stackPos)].near = (tb >= intervalMin ? tb : intervalMin)
                        stack[Int(stackPos)].far = intervalMax

                        stackPos += 1

                        //  update ray interval for front node
                        intervalMax = (tf <= intervalMax ? tf : intervalMax)
                    case 2 << 30:
                        //  z axis
                        let tf: Float = (ByteUtil.intBitsToFloat(tree![Int(node + offsetZFront)]) - orgZ) * invDirZ
                        let tb: Float = (ByteUtil.intBitsToFloat(tree![Int(node + offsetZBack)]) - orgZ) * invDirZ

                        //  ray passes between clip zones
                        if tf < intervalMin, tb > intervalMax {
                            break pushloop
                        }

                        let back: Int32 = offset + offsetZBack3

                        node = back

                        //  ray passes through far node only
                        if tf < intervalMin {
                            intervalMin = (tb >= intervalMin ? tb : intervalMin)

                            continue
                        }

                        node = offset + offsetZFront3 //  front

                        //  ray passes through near node only
                        if tb > intervalMax {
                            intervalMax = (tf <= intervalMax ? tf : intervalMax)

                            continue
                        }

                        //  ray passes through both nodes
                        //  push back node
                        stack[Int(stackPos)].node = back
                        stack[Int(stackPos)].near = (tb >= intervalMin ? tb : intervalMin)
                        stack[Int(stackPos)].far = intervalMax

                        stackPos += 1

                        //  update ray interval for front node
                        intervalMax = (tf <= intervalMax ? tf : intervalMax)
                    case 3 << 30:
                        //  leaf - test some objects
                        var n: Int32 = tree![Int(node) + 1]

                        while n > 0 {
                            primitives!.intersectPrimitive(r, objects![Int(offset)], state)

                            n -= 1

                            offset += 1
                        }

                        break pushloop
                    case 1 << 29:
                        let tf: Float = (ByteUtil.intBitsToFloat(tree![Int(node + offsetXFront)]) - orgX) * invDirX
                        let tb: Float = (ByteUtil.intBitsToFloat(tree![Int(node + offsetXBack)]) - orgX) * invDirX

                        node = offset

                        intervalMin = (tf >= intervalMin ? tf : intervalMin)
                        intervalMax = (tb <= intervalMax ? tb : intervalMax)

                        if intervalMin > intervalMax {
                            break pushloop
                        }
                    case 3 << 29:
                        let tf: Float = (ByteUtil.intBitsToFloat(tree![Int(node + offsetYFront)]) - orgY) * invDirY
                        let tb: Float = (ByteUtil.intBitsToFloat(tree![Int(node + offsetYBack)]) - orgY) * invDirY

                        node = offset

                        intervalMin = (tf >= intervalMin ? tf : intervalMin)
                        intervalMax = (tb <= intervalMax ? tb : intervalMax)

                        if intervalMin > intervalMax {
                            break pushloop
                        }
                    case 5 << 29:
                        let tf: Float = (ByteUtil.intBitsToFloat(tree![Int(node + offsetZFront)]) - orgZ) * invDirZ
                        let tb: Float = (ByteUtil.intBitsToFloat(tree![Int(node + offsetZBack)]) - orgZ) * invDirZ

                        node = offset

                        intervalMin = (tf >= intervalMin ? tf : intervalMin)
                        intervalMax = (tb <= intervalMax ? tb : intervalMax)

                        if intervalMin > intervalMax {
                            break pushloop
                        }
                    default:
                        return // should not happen
                } //  switch
            } //  traversal loop

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
        }
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
        var numBVH2: Int32 = 0

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
            numBVH2 = 0
        }

        func updateInner() {
            numNodes += 1
        }

        func updateBVH2() {
            numBVH2 += 1
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
            UI.printDetailed(.ACCEL, "Tree stats:")
            UI.printDetailed(.ACCEL, "  * Nodes:          \(numNodes)")
            UI.printDetailed(.ACCEL, "  * Leaves:         \(numLeaves)")
            UI.printDetailed(.ACCEL, "  * Objects: min    \(minObjects)")
            UI.printDetailed(.ACCEL, "             avg    \(Float(sumObjects) / Float(numLeaves))")
            UI.printDetailed(.ACCEL, "           avg(n>0) \(Float(sumObjects) / Float(numLeaves - numLeaves0))")
            UI.printDetailed(.ACCEL, "             max    \(maxObjects)")
            UI.printDetailed(.ACCEL, "  * Depth:   min    \(minDepth)")
            UI.printDetailed(.ACCEL, "             avg    \(Float(sumDepth) / Float(numLeaves))")
            UI.printDetailed(.ACCEL, "             max    \(maxDepth)")
            UI.printDetailed(.ACCEL, "  * Leaves w/: N=0  \((100 * numLeaves0) / numLeaves)%")
            UI.printDetailed(.ACCEL, "               N=1  \((100 * numLeaves1) / numLeaves)%")
            UI.printDetailed(.ACCEL, "               N=2  \((100 * numLeaves2) / numLeaves)%")
            UI.printDetailed(.ACCEL, "               N=3  \((100 * numLeaves3) / numLeaves)%")
            UI.printDetailed(.ACCEL, "               N=4  \((100 * numLeaves4) / numLeaves)%")
            UI.printDetailed(.ACCEL, "               N>4  \((100 * numLeaves4p) / numLeaves)%")
            UI.printDetailed(.ACCEL, "  * BVH2 nodes:     \(numBVH2) (\((100 * numBVH2) / ((numNodes + numLeaves) - (2 * numBVH2)))%)")
        }
    }
}
