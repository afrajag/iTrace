//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class BoundingBox: CustomStringConvertible {
    var minimum: Point3
    var maximum: Point3

    // Creates an empty box. The minimum point will have all components set to
    // positive infinity, and the maximum will have all components set to
    // negative infinity.
    init() {
        minimum = Point3(Float.infinity, Float.infinity, Float.infinity)
        maximum = Point3(-Float.infinity, -Float.infinity, -Float.infinity)
    }

    // Creates a copy of the given box.
    //
    // @param b bounding box to copy
    init(_ b: BoundingBox) {
        minimum = Point3(b.minimum)
        maximum = Point3(b.maximum)
    }

    // Creates a bounding box containing only the specified point.
    //
    // @param p point to include
    convenience init(_ p: Point3) {
        self.init(p.x, p.y, p.z)
    }

    // Creates a bounding box containing only the specified point.
    //
    // @param x x coordinate of the point to include
    // @param y y coordinate of the point to include
    // @param z z coordinate of the point to include
    init(_ x: Float, _ y: Float, _ z: Float) {
        minimum = Point3(x, y, z)
        maximum = Point3(x, y, z)
    }

    // Creates a bounding box centered around the origin.
    //
    // @param size half edge Length of the bounding box
    init(_ size: Float) {
        minimum = Point3(-size, -size, -size)
        maximum = Point3(size, size, size)
    }

    // Gets the minimum corner of the box. That is the corner of smallest
    // coordinates on each axis. Note that the returned reference is not cloned
    // for efficiency purposes so care must be taken not to change the
    // coordinates of the point.
    //
    // @return a reference to the minimum corner
    func getMinimum() -> Point3 {
        return minimum
    }

    // Gets the maximum corner of the box. That is the corner of largest
    // coordinates on each axis. Note that the returned reference is not cloned
    // for efficiency purposes so care must be taken not to change the
    // coordinates of the point.
    //
    // @return a reference to the maximum corner
    func getMaximum() -> Point3 {
        return maximum
    }

    // Gets the center of the box, computed as (min + max) / 2.
    //
    // @return a reference to the center of the box
    func getCenter() -> Point3 {
        return Point3.mid(minimum, maximum)
    }

    // Gets a corner of the bounding box. The index scheme uses the binary
    // representation of the index to decide which corner to return. Corner 0 is
    // equivalent to the minimum and corner 7 is equivalent to the maximum.
    //
    // @param i a corner index, from 0 to 7
    // @return the corresponding corner
    func getCorner(_ i: Int32) -> Point3 {
        let x: Float = (i & 1) == 0 ? minimum.x : maximum.x
        let y: Float = (i & 2) == 0 ? minimum.y : maximum.y
        let z: Float = (i & 4) == 0 ? minimum.z : maximum.z
        return Point3(x, y, z)
    }

    // Gets a specific coordinate of the surface's bounding box.
    //
    // @param i index of a side from 0 to 5
    // @return value of the request bounding box side
    func getBound(_ i: Int32) -> Float {
        switch i {
        case 0:
            return minimum.x
        case 1:
            return maximum.x
        case 2:
            return minimum.y
        case 3:
            return maximum.y
        case 4:
            return minimum.z
        case 5:
            return maximum.z
        default:
            return 0
        }
    }

    // Gets the extents vector for the box. This vector is computed as (max -
    // min). Its coordinates are always positive and represent the dimensions of
    // the box along the three axes.
    //
    // @return a refreence to the extent vector
    // @see org.sunflow.math.Vector3#Length()
    func getExtents() -> Vector3 {
        return Point3.sub(maximum, minimum)
    }

    // Gets the surface area of the box.
    //
    // @return surface area
    func getArea() -> Float {
        let w: Vector3 = getExtents()
        let ax: Float = max(w.x, 0)
        let ay: Float = max(w.y, 0)
        let az: Float = max(w.z, 0)
        return 2 * ((ax * ay) + (ay * az) + (az * ax))
    }

    // Gets the box's volume
    //
    // @return volume
    func getVolume() -> Float {
        let w: Vector3 = getExtents()
        let ax: Float = max(w.x, 0)
        let ay: Float = max(w.y, 0)
        let az: Float = max(w.z, 0)
        return ax * ay * az
    }

    // Enlarge the bounding box by the minimum possible amount to avoid numeric
    // precision related problems.
    func enlargeUlps() {
        let eps: Float = 0.0001

        minimum.x -= max(eps, minimum.x.ulp)
        minimum.y -= max(eps, minimum.y.ulp)
        minimum.z -= max(eps, minimum.z.ulp)
        maximum.x += max(eps, maximum.x.ulp)
        maximum.y += max(eps, maximum.y.ulp)
        maximum.z += max(eps, maximum.z.ulp)
    }

    // Returns true when the box has just been initialized, and
    // is still empty. This method might also return true if the state of the
    // box becomes inconsistent and some component of the minimum corner is
    // larger than the corresponding coordinate of the maximum corner.
    //
    // @return true if the box is empty, false
    //         otherwise
    func isEmpty() -> Bool {
        return (maximum.x < minimum.x) || (maximum.y < minimum.y) || (maximum.z < minimum.z)
    }

    // Returns true if the specified bounding box intersects this
    // one. The boxes are treated as volumes, so a box inside another will
    // return true. Returns false if the parameter is
    // null.
    //
    // @param b box to be tested for intersection
    // @return true if the boxes overlap, false
    //         otherwise
    func intersects(_ b: BoundingBox?) -> Bool {
        return b != nil && (minimum.x <= b!.maximum.x) && (maximum.x >= b!.minimum.x) && (minimum.y <= b!.maximum.y) && (maximum.y >= b!.minimum.y) && (minimum.z <= b!.maximum.z) && (maximum.z >= b!.minimum.z)
    }

    // Checks to see if the specified {@link org.sunflow.math.Point3 point}is
    // inside the volume defined by this box. Returns false if
    // the parameter is null.
    //
    // @param p point to be tested for containment
    // @return true if the point is inside the box,
    //         false otherwise
    func contains(_ p: Point3?) -> Bool {
        return p != nil && (p!.x >= minimum.x) && (p!.x <= maximum.x) && (p!.y >= minimum.y) && (p!.y <= maximum.y) && (p!.z >= minimum.z) && (p!.z <= maximum.z)
    }

    // Check to see if the specified point is inside the volume defined by this
    // box.
    //
    // @param x x coordinate of the point to be tested
    // @param y y coordinate of the point to be tested
    // @param z z coordinate of the point to be tested
    // @return true if the point is inside the box,
    //         false otherwise
    func contains(_ x: Float, _ y: Float, _ z: Float) -> Bool {
        return (x >= minimum.x) && (x <= maximum.x) && (y >= minimum.y) && (y <= maximum.y) && (z >= minimum.z) && (z <= maximum.z)
    }

    // Changes the extents of the box as needed to include the given
    // {@link org.sunflow.math.Point3 point}into this box. Does nothing if the
    // parameter is null.
    //
    // @param p point to be included
    func include(_ p: Point3?) {
        if p != nil {
            if p!.x < minimum.x {
                minimum.x = p!.x
            }
            if p!.x > maximum.x {
                maximum.x = p!.x
            }
            if p!.y < minimum.y {
                minimum.y = p!.y
            }
            if p!.y > maximum.y {
                maximum.y = p!.y
            }
            if p!.z < minimum.z {
                minimum.z = p!.z
            }
            if p!.z > maximum.z {
                maximum.z = p!.z
            }
        }
    }

    // Changes the extents of the box as needed to include the given point into
    // this box.
    //
    // @param x x coordinate of the point
    // @param y y coordinate of the point
    // @param z z coordinate of the point
    func include(_ x: Float, _ y: Float, _ z: Float) {
        if x < minimum.x {
            minimum.x = x
        }
        if x > maximum.x {
            maximum.x = x
        }
        if y < minimum.y {
            minimum.y = y
        }
        if y > maximum.y {
            maximum.y = y
        }
        if z < minimum.z {
            minimum.z = z
        }
        if z > maximum.z {
            maximum.z = z
        }
    }

    // Changes the extents of the box as needed to include the given box into
    // this box. Does nothing if the parameter is null.
    //
    // @param b box to be included
    func include(_ b: BoundingBox?) {
        if b != nil {
            if b!.minimum.x < minimum.x {
                minimum.x = b!.minimum.x
            }
            if b!.maximum.x > maximum.x {
                maximum.x = b!.maximum.x
            }
            if b!.minimum.y < minimum.y {
                minimum.y = b!.minimum.y
            }
            if b!.maximum.y > maximum.y {
                maximum.y = b!.maximum.y
            }
            if b!.minimum.z < minimum.z {
                minimum.z = b!.minimum.z
            }
            if b!.maximum.z > maximum.z {
                maximum.z = b!.maximum.z
            }
        }
    }

    var description: String {
        return "(\(minimum.x), \(minimum.y), \(minimum.z)) to (\(maximum.x), \(maximum.y), \(maximum.z))"
    }
}
