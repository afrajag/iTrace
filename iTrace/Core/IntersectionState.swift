//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class IntersectionState {
    static var MAX_STACK_SIZE: Int32 = 64
    var time: Float = 0.0
    var instance: Instance?
    var id: Int32 = 0
    var stacks: [[StackNode]] = [[StackNode]](repeating: [], count: 2)
    var current: Instance?
    var numEyeRays: Int64 = 0
    var numShadowRays: Int64 = 0
    var numReflectionRays: Int64 = 0
    var numGlossyRays: Int64 = 0
    var numRefractionRays: Int64 = 0
    var numRays: Int64 = 0
    var u: Float = 0.0
    var v: Float = 0.0
    var w: Float = 0.0

    // Initializes all traversal stacks.
    init() {
        for i in 0 ..< stacks.count {
            stacks[i] = [StackNode](repeating: StackNode(), count: Int(Self.MAX_STACK_SIZE))

            // FIXME: tolto perche' gia' viene inizializzato nella riga precedente
            /*
             for j in 0 ..< stacks[i].count {
             	stacks[i][j] = StackNode()
             }
             */
        }
    }

    // Returns the time at which the intersection should be calculated. This
    // will be constant for a given ray-tree. This value is guarenteed to be
    // between the camera's shutter open and shutter close time.
    //
    // @return time value
    func getTime() -> Float {
        return time
    }

    // Get stack object for tree based {@link AccelerationStructure}s.
    //
    // @return array of stack nodes
    func getStack() -> [StackNode] {
        return (current == nil ? stacks[0] : stacks[1])
    }

    // Checks to see if a hit has been recorded.
    //
    // @return true if a hit has been recorded,
    //         false otherwise
    func hit() -> Bool {
        return instance != nil
    }

    // Record an intersection with the specified primitive id. The parent object
    // is assumed to be the current instance. The u and v parameters are used to
    // pinpoint the location on the surface if needed.
    //
    // @param id primitive id of the intersected object
    // @param u u surface paramater of the intersection point
    // @param v v surface parameter of the intersection point
    func setIntersection(_ id: Int32) {
        instance = current

        self.id = id
    }

    // Record an intersection with the specified primitive id. The parent object
    // is assumed to be the current instance. The u and v parameters are used to
    // pinpoint the location on the surface if needed.
    //
    // @param id primitive id of the intersected object
    // @param u u surface paramater of the intersection point
    // @param v v surface parameter of the intersection point
    func setIntersection(_ id: Int32, _ u: Float, _ v: Float) {
        instance = current

        self.id = id
        self.u = u
        self.v = v
    }

    // Record an intersection with the specified primitive id. The parent object
    // is assumed to be the current instance. The u and v parameters are used to
    // pinpoint the location on the surface if needed.
    //
    // @param id primitive id of the intersected object
    // @param u u surface paramater of the intersection point
    // @param v v surface parameter of the intersection point
    func setIntersection(_ id: Int32, _ u: Float, _ v: Float, _ w: Float) {
        instance = current

        self.id = id
        self.u = u
        self.v = v
        self.w = w
    }

    struct StackNode {
        var node: Int32 = 0
        var near: Float = 0.0
        var far: Float = 0.0
    }
}
