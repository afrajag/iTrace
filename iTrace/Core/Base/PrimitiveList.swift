//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

protocol PrimitiveList: RenderObject {
    // Compute a bounding box of this object in world space, using the specified
    // object-to-world transformation matrix. The bounds should be as exact as
    // possible, if they are difficult or expensive to compute exactly, you may
    // use {@link AffineTransform#transform(BoundingBox)}. If the matrix is
    // null no transformation is needed, and object space is
    // equivalent to world space.
    //
    // @param o2w object to world transformation matrix
    // @return object bounding box in world space
    func getWorldBounds(_ o2w: AffineTransform?) -> BoundingBox?

    // Returns the number of individual primtives in this aggregate object.
    //
    // @return number of primitives
    func getNumPrimitives() -> Int32

    // Retrieve the bounding box component of a particular primitive in object
    // space. Even indexes get minimum values, while odd indexes get the maximum
    // values for each axis.
    //
    // @param primID primitive index
    // @param i bounding box side index
    // @return value of the request bound
    func getPrimitiveBound(_ primID: Int32, _ i: Int32) -> Float

    // Intersect the specified primitive in local space.
    //
    // @param r ray in the object's local space
    // @param primID primitive index to intersect
    // @param state intersection state
    // @see Ray#setMax(float)
    // @see IntersectionState#setIntersection(int, float, float)
    func intersectPrimitive(_ r: Ray, _ primID: Int32, _ state: IntersectionState)

    // Prepare the specified {@link ShadingState} by setting all of its internal
    // parameters.
    //
    // @param state shading state to fill in
    func prepareShadingState(_ state: ShadingState)

    // Create a new {@link PrimitiveList} object suitable for baking lightmaps.
    // This means a set of primitives laid out in the unit square UV space. This
    // method is optional, objects which do not support it should simply return
    // null.
    //
    // @return a list of baking primitives
    func getBakingPrimitives() -> PrimitiveList?
}
