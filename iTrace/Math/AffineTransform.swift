//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//
import Foundation

// This final class is used to represent general affine transformations in 3D. The
// bottom row of the matrix is assumed to be [0,0,0,1]. Note that the rotation
// matrices assume a right-handed convention.
final class AffineTransform: Codable, Equatable {
    var m00: Float = 0.0
    var m01: Float = 0.0
    var m02: Float = 0.0
    var m03: Float = 0.0
    var m10: Float = 0.0
    var m11: Float = 0.0
    var m12: Float = 0.0
    var m13: Float = 0.0
    var m20: Float = 0.0
    var m21: Float = 0.0
    var m22: Float = 0.0
    var m23: Float = 0.0

    static var ZERO: AffineTransform = AffineTransform()
    static var IDENTITY: AffineTransform = AffineTransform.scale(1)

    // Creates an empty matrix. All elements are 0.
    init() {}

    // Creates a matrix with the specified elements
    //
    // @param m00 value at row 0, col 0
    // @param m01 value at row 0, col 1
    // @param m02 value at row 0, col 2
    // @param m03 value at row 0, col 3
    // @param m10 value at row 1, col 0
    // @param m11 value at row 1, col 1
    // @param m12 value at row 1, col 2
    // @param m13 value at row 1, col 3
    // @param m20 value at row 2, col 0
    // @param m21 value at row 2, col 1
    // @param m22 value at row 2, col 2
    // @param m23 value at row 2, col 3
    init(_ m00: Float, _ m01: Float, _ m02: Float, _ m03: Float, _ m10: Float, _ m11: Float, _ m12: Float, _ m13: Float, _ m20: Float, _ m21: Float, _ m22: Float, _ m23: Float) {
        self.m00 = m00
        self.m01 = m01
        self.m02 = m02
        self.m03 = m03
        self.m10 = m10
        self.m11 = m11
        self.m12 = m12
        self.m13 = m13
        self.m20 = m20
        self.m21 = m21
        self.m22 = m22
        self.m23 = m23
    }

    // Initialize a matrix from the specified 16 element array. The matrix may
    // be given in row or column major form.
    //
    // @param m a 16 element array in row or column major form
    // @param rowMajor true if the array is in row major form,
    //            falseif it is in column major form
    init(_ m: [Float], _ rowMajor: Bool) {
        if rowMajor {
            m00 = m[0]
            m01 = m[1]
            m02 = m[2]
            m03 = m[3]
            m10 = m[4]
            m11 = m[5]
            m12 = m[6]
            m13 = m[7]
            m20 = m[8]
            m21 = m[9]
            m22 = m[10]
            m23 = m[11]

            if (m[12] != 0) || (m[13] != 0) || (m[14] != 0) || (m[15] != 1) {
                fatalError("Matrix is not affine Bottom row is: [\(m[12]), \(m[13]), \(m[14]), \(m[15])]")
            }
        } else {
            m00 = m[0]
            m01 = m[4]
            m02 = m[8]
            m03 = m[12]
            m10 = m[1]
            m11 = m[5]
            m12 = m[9]
            m13 = m[13]
            m20 = m[2]
            m21 = m[6]
            m22 = m[10]
            m23 = m[14]

            if (m[3] != 0) || (m[7] != 0) || (m[11] != 0) || (m[15] != 1) {
                fatalError("Matrix is not affine Bottom row is: [\(m[12]), \(m[13]), \(m[14]), \(m[15])]")
            }
        }
    }

    func isIdentity() -> Bool {
        return equals(Self.IDENTITY)
    }

    func equals(_ m: AffineTransform?) -> Bool {
        if m == nil {
            return false
        }

        // FIXME: controllare se l'implementazione di equatable e' corretta
        if self == m {
            return true
        }
        
        return (m00 == m!.m00) && (m01 == m!.m01) && (m02 == m!.m02) && (m03 == m!.m03) && (m10 == m!.m10) && (m11 == m!.m11) && (m12 == m!.m12) && (m13 == m!.m13) && (m20 == m!.m20) && (m21 == m!.m21) && (m22 == m!.m22) && (m23 == m!.m23)
    }

    func asRowMajor() -> [Float] {
        return [m00, m01, m02, m03, m10, m11, m12, m13, m20, m21, m22, m23, 0, 0, 0, 1]
    }

    func asColMajor() -> [Float] {
        return [m00, m10, m20, 0, m01, m11, m21, 0, m02, m12, m22, 0, m03, m13, m23, 1]
    }

    // Compute the matrix determinant.
    //
    // @return determinant of this matrix
    func determinant() -> Float {
        let A0: Float = (m00 * m11) - (m01 * m10)
        let A1: Float = (m00 * m12) - (m02 * m10)
        let A3: Float = (m01 * m12) - (m02 * m11)

        return (A0 * m22) - (A1 * m21) + (A3 * m20)
    }

    // Compute the inverse of this matrix and return it as a new object. If the
    // matrix is not invertible, null is returned.
    //
    // @return the inverse of this matrix, or null if not
    //         invertible
    func inverse() -> AffineTransform? {
        let A0: Float = (m00 * m11) - (m01 * m10)
        let A1: Float = (m00 * m12) - (m02 * m10)
        let A3: Float = (m01 * m12) - (m02 * m11)
        
        let det: Float = ((A0 * m22) - (A1 * m21)) + (A3 * m20)

        if abs(det) < 1e-12 {
            return nil //  matrix is not invertible
        }

        let invDet: Float = 1 / det
        
        let A2: Float = (m00 * m13) - (m03 * m10)
        let A4: Float = (m01 * m13) - (m03 * m11)
        let A5: Float = (m02 * m13) - (m03 * m12)
        
        let inv: AffineTransform = AffineTransform()

        inv.m00 = ((+m11 * m22) - (m12 * m21)) * invDet
        inv.m10 = ((-m10 * m22) + (m12 * m20)) * invDet
        inv.m20 = ((+m10 * m21) - (m11 * m20)) * invDet
        inv.m01 = ((-m01 * m22) + (m02 * m21)) * invDet
        inv.m11 = ((+m00 * m22) - (m02 * m20)) * invDet
        inv.m21 = ((-m00 * m21) + (m01 * m20)) * invDet
        inv.m02 = +A3 * invDet
        inv.m12 = -A1 * invDet
        inv.m22 = +A0 * invDet
        inv.m03 = (((-m21 * A5) + (m22 * A4)) - (m23 * A3)) * invDet
        inv.m13 = (((+m20 * A5) - (m22 * A2)) + (m23 * A1)) * invDet
        inv.m23 = (((-m20 * A4) + (m21 * A2)) - (m23 * A0)) * invDet

        return inv
    }

    // Computes this*m and return the result as a new AffineTransform
    //
    // @param m right hand side of the multiplication
    // @return a new AffineTransform object equal to this*m
    func multiply(_ m: AffineTransform) -> AffineTransform {
        //  matrix multiplication is m[r][c] = (row[r]).(col[c])
        let rm00: Float = (m00 * m.m00) + (m01 * m.m10) + (m02 * m.m20)
        let rm01: Float = (m00 * m.m01) + (m01 * m.m11) + (m02 * m.m21)
        let rm02: Float = (m00 * m.m02) + (m01 * m.m12) + (m02 * m.m22)
        let rm03: Float = (m00 * m.m03) + (m01 * m.m13) + (m02 * m.m23) + m03
        let rm10: Float = (m10 * m.m00) + (m11 * m.m10) + (m12 * m.m20)
        let rm11: Float = (m10 * m.m01) + (m11 * m.m11) + (m12 * m.m21)
        let rm12: Float = (m10 * m.m02) + (m11 * m.m12) + (m12 * m.m22)
        let rm13: Float = (m10 * m.m03) + (m11 * m.m13) + (m12 * m.m23) + m13
        let rm20: Float = (m20 * m.m00) + (m21 * m.m10) + (m22 * m.m20)
        let rm21: Float = (m20 * m.m01) + (m21 * m.m11) + (m22 * m.m21)
        let rm22: Float = (m20 * m.m02) + (m21 * m.m12) + (m22 * m.m22)
        let rm23: Float = (m20 * m.m03) + (m21 * m.m13) + (m22 * m.m23) + m23

        return AffineTransform(rm00, rm01, rm02, rm03, rm10, rm11, rm12, rm13, rm20, rm21, rm22, rm23)
    }

    // Transforms each corner of the specified axis-aligned bounding box and
    // returns a new bounding box which incloses the transformed corners.
    //
    // @param b original bounding box
    // @return a new BoundingBox object which encloses the transform version of
    //         b
    func transform(_ b: BoundingBox) -> BoundingBox {
        if b.isEmpty() {
            return BoundingBox()
        }

        //  special case extreme corners
        let rb: BoundingBox = BoundingBox(transformP(b.getMinimum()))

        rb.include(transformP(b.getMaximum()))

        //  do internal corners
        for i in 1 ..< 7 {
            rb.include(transformP(b.getCorner(Int32(i))))
        }

        return rb
    }

    // Computes this*v and returns the result as a new Vector3 object. This
    // method assumes the bottom row of the matrix is [0,0,0,1].
    //
    // @param v vector to multiply
    // @return a new Vector3 object equal to this*v
    func transformV(_ v: Vector3) -> Vector3 {
        let rv: Vector3 = Vector3()

        rv.x = (m00 * v.x) + (m01 * v.y) + (m02 * v.z)
        rv.y = (m10 * v.x) + (m11 * v.y) + (m12 * v.z)
        rv.z = (m20 * v.x) + (m21 * v.y) + (m22 * v.z)

        return rv
    }

    // Computes (this^T)*v and returns the result as a new Vector3 object. This
    // method assumes the bottom row of the matrix is [0,0,0,1].
    //
    // @param v vector to multiply
    // @return a new Vector3 object equal to (this^T)*v
    func transformTransposeV(_ v: Vector3) -> Vector3 {
        let rv: Vector3 = Vector3()

        rv.x = (m00 * v.x) + (m10 * v.y) + (m20 * v.z)
        rv.y = (m01 * v.x) + (m11 * v.y) + (m21 * v.z)
        rv.z = (m02 * v.x) + (m12 * v.y) + (m22 * v.z)

        return rv
    }

    // Computes this*p and returns the result as a new Point3 object. This
    // method assumes the bottom row of the matrix is [0,0,0,1].
    //
    // @param p point to multiply
    // @return a new Point3 object equal to this*v
    func transformP(_ p: Point3) -> Point3 {
        let rp: Point3 = Point3()

        rp.x = (m00 * p.x) + (m01 * p.y) + (m02 * p.z) + m03
        rp.y = (m10 * p.x) + (m11 * p.y) + (m12 * p.z) + m13
        rp.z = (m20 * p.x) + (m21 * p.y) + (m22 * p.z) + m23

        return rp
    }

    // Computes the x component of this*(x,y,z,0).
    //
    // @param x x coordinate of the vector to multiply
    // @param y y coordinate of the vector to multiply
    // @param z z coordinate of the vector to multiply
    // @return x coordinate transformation result
    func transformVX(_ x: Float, _ y: Float, _ z: Float) -> Float {
        return (m00 * x) + (m01 * y) + (m02 * z)
    }

    // Computes the y component of this*(x,y,z,0).
    //
    // @param x x coordinate of the vector to multiply
    // @param y y coordinate of the vector to multiply
    // @param z z coordinate of the vector to multiply
    // @return y coordinate transformation result
    func transformVY(_ x: Float, _ y: Float, _ z: Float) -> Float {
        return (m10 * x) + (m11 * y) + (m12 * z)
    }

    // Computes the z component of this*(x,y,z,0).
    //
    // @param x x coordinate of the vector to multiply
    // @param y y coordinate of the vector to multiply
    // @param z z coordinate of the vector to multiply
    // @return z coordinate transformation result
    func transformVZ(_ x: Float, _ y: Float, _ z: Float) -> Float {
        return (m20 * x) + (m21 * y) + (m22 * z)
    }

    // Computes the x component of (this^T)*(x,y,z,0).
    //
    // @param x x coordinate of the vector to multiply
    // @param y y coordinate of the vector to multiply
    // @param z z coordinate of the vector to multiply
    // @return x coordinate transformation result
    func transformTransposeVX(_ x: Float, _ y: Float, _ z: Float) -> Float {
        return (m00 * x) + (m10 * y) + (m20 * z)
    }

    // Computes the y component of (this^T)*(x,y,z,0).
    //
    // @param x x coordinate of the vector to multiply
    // @param y y coordinate of the vector to multiply
    // @param z z coordinate of the vector to multiply
    // @return y coordinate transformation result
    func transformTransposeVY(_ x: Float, _ y: Float, _ z: Float) -> Float {
        return (m01 * x) + (m11 * y) + (m21 * z)
    }

    // Computes the z component of (this^T)*(x,y,z,0).
    //
    // @param x x coordinate of the vector to multiply
    // @param y y coordinate of the vector to multiply
    // @param z z coordinate of the vector to multiply
    // @return zcoordinate transformation result
    func transformTransposeVZ(_ x: Float, _ y: Float, _ z: Float) -> Float {
        return (m02 * x) + (m12 * y) + (m22 * z)
    }

    // Computes the x component of this*(x,y,z,1).
    //
    // @param x x coordinate of the vector to multiply
    // @param y y coordinate of the vector to multiply
    // @param z z coordinate of the vector to multiply
    // @return x coordinate transformation result
    func transformPX(_ x: Float, _ y: Float, _ z: Float) -> Float {
        return (m00 * x) + (m01 * y) + (m02 * z) + m03
    }

    // Computes the y component of this*(x,y,z,1).
    //
    // @param x x coordinate of the vector to multiply
    // @param y y coordinate of the vector to multiply
    // @param z z coordinate of the vector to multiply
    // @return y coordinate transformation result
    func transformPY(_ x: Float, _ y: Float, _ z: Float) -> Float {
        return (m10 * x) + (m11 * y) + (m12 * z) + m13
    }

    // Computes the z component of this*(x,y,z,1).
    //
    // @param x x coordinate of the vector to multiply
    // @param y y coordinate of the vector to multiply
    // @param z z coordinate of the vector to multiply
    // @return z coordinate transformation result
    func transformPZ(_ x: Float, _ y: Float, _ z: Float) -> Float {
        return (m20 * x) + (m21 * y) + (m22 * z) + m23
    }

    // Create a translation matrix for the specified vector.
    //
    // @param x x component of translation
    // @param y y component of translation
    // @param z z component of translation
    // @return a new AffineTransform object representing the translation
    static func translation(_ x: Float, _ y: Float, _ z: Float) -> AffineTransform {
        let m: AffineTransform = AffineTransform()

        m.m00 = 1
        m.m11 = 1
        m.m22 = 1
        m.m03 = x
        m.m13 = y
        m.m23 = z

        return m
    }

    // Creates a rotation matrix about the X axis.
    //
    // @param theta angle to rotate about the X axis in radians
    // @return a new AffineTransform object representing the rotation
    static func rotateX(_ theta: Float) -> AffineTransform {
        let m: AffineTransform = AffineTransform()
        let s: Float = sin(theta)
        let c: Float = cos(theta)

        m.m00 = 1
        m.m11 = c
        m.m22 = c
        m.m12 = -s
        m.m21 = +s

        return m
    }

    // Creates a rotation matrix about the Y axis.
    //
    // @param theta angle to rotate about the Y axis in radians
    // @return a new AffineTransform object representing the rotation
    static func rotateY(_ theta: Float) -> AffineTransform {
        let m: AffineTransform = AffineTransform()
        let s: Float = sin(theta)
        let c: Float = cos(theta)

        m.m11 = 1
        m.m00 = c
        m.m22 = c
        m.m02 = +s
        m.m20 = -s

        return m
    }

    // Creates a rotation matrix about the Z axis.
    //
    // @param theta angle to rotate about the Z axis in radians
    // @return a new AffineTransform object representing the rotation
    static func rotateZ(_ theta: Float) -> AffineTransform {
        let m: AffineTransform = AffineTransform()
        let s: Float = sin(theta)
        let c: Float = cos(theta)

        m.m22 = 1
        m.m00 = c
        m.m11 = c
        m.m01 = -s
        m.m10 = +s

        return m
    }

    // Creates a rotation matrix about the specified axis. The axis vector need
    // not be normalized.
    //
    // @param x x component of the axis vector
    // @param y y component of the axis vector
    // @param z z component of the axis vector
    // @param theta angle to rotate about the axis in radians
    // @return a new AffineTransform object representing the rotation
    static func rotate(_ x: Float, _ y: Float, _ z: Float, _ theta: Float) -> AffineTransform {
        let m: AffineTransform = AffineTransform()
        let invLen: Float = 1 / sqrt((x * x) + (y * y) + (z * z))

        let _x = x * invLen
        let _y = y * invLen
        let _z = z * invLen

        let s: Float = sin(theta)
        let c: Float = cos(theta)
        let t: Float = 1 - c

        m.m00 = (t * _x * _x) + c
        m.m11 = (t * _y * _y) + c
        m.m22 = (t * _z * _z) + c

        let txy: Float = t * _x * _y
        let sz: Float = s * _z

        m.m01 = txy - sz
        m.m10 = txy + sz

        let txz: Float = t * _x * _z
        let sy: Float = s * _y

        m.m02 = txz + sy
        m.m20 = txz - sy

        let tyz: Float = t * _y * _z
        let sx: Float = s * _x

        m.m12 = tyz - sx
        m.m21 = tyz + sx

        return m
    }

    // Create a uniform scaling matrix.
    //
    // @param s scale factor for all three axes
    // @return a new AffineTransform object representing the uniform scale
    static func scale(_ s: Float) -> AffineTransform {
        let m: AffineTransform = AffineTransform()

        m.m00 = s
        m.m11 = s
        m.m22 = s

        return m
    }

    // Creates a non-uniform scaling matrix.
    //
    // @param sx scale factor in the x dimension
    // @param sy scale factor in the y dimension
    // @param sz scale factor in the z dimension
    // @return a new AffineTransform object representing the non-uniform scale
    static func scale(_ sx: Float, _ sy: Float, _ sz: Float) -> AffineTransform {
        let m: AffineTransform = AffineTransform()

        m.m00 = sx
        m.m11 = sy
        m.m22 = sz

        return m
    }

    // Creates a rotation matrix from an OrthonormalBasis.
    //
    // @param basis
    static func fromBasis(_ basis: OrthoNormalBasis) -> AffineTransform {
        let m: AffineTransform = AffineTransform()
        let u: Vector3 = basis.transform(Vector3(1, 0, 0))
        let v: Vector3 = basis.transform(Vector3(0, 1, 0))
        let w: Vector3 = basis.transform(Vector3(0, 0, 1))

        m.m00 = u.x
        m.m01 = v.x
        m.m02 = w.x
        m.m10 = u.y
        m.m11 = v.y
        m.m12 = w.y
        m.m20 = u.z
        m.m21 = v.z
        m.m22 = w.z

        return m
    }

    // Creates a rotation matrix from a vector orientation.
    //
    // @param u
    // @param v
    // @param w
    static func vectorOrientation(_ forward: Vector3, _ left: Vector3, _ up: Vector3) -> AffineTransform {
        let m: AffineTransform = AffineTransform()

        //
        // 	m.m00 = forward.x;
        //  m.m01 = forward.y;
        //  m.m02 = forward.z;
        // 	m.m10 = left.x;
        //  m.m11 = left.y;
        //  m.m12 = left.z;
        // 	m.m20 = up.x;
        // 	m.m21 = up.y;
        // 	m.m22 = up.z;
        //
        m.m00 = forward.x
        m.m01 = left.x
        m.m02 = up.x
        m.m10 = forward.y
        m.m11 = left.y
        m.m12 = up.y
        m.m20 = forward.z
        m.m21 = left.z
        m.m22 = up.z

        return m
    }

    // Creates a camera positioning matrix from the given eye and target points
    // and up vector.
    //
    // @param eye location of the eye
    // @param target location of the target
    // @param up vector pointing upwards
    // @return
    static func lookAt(_ eye: Point3, _ target: Point3, _ up: Vector3) -> AffineTransform {
        let m: AffineTransform = AffineTransform.fromBasis(OrthoNormalBasis.makeFromWV(Point3.sub(eye, target), up))
        //let a = Point3.sub(eye, target)
        //let b = OrthoNormalBasis.makeFromWV(a, up)
        //let m = AffineTransform.fromBasis(b)
        let transf = AffineTransform.translation(eye.x, eye.y, eye.z)
        
        return transf.multiply(m)
    }

    static func blend(_ m0: AffineTransform, _ m1: AffineTransform, _ t: Float) -> AffineTransform {
        let m: AffineTransform = AffineTransform()

        m.m00 = ((1 - t) * m0.m00) + (t * m1.m00)
        m.m01 = ((1 - t) * m0.m01) + (t * m1.m01)
        m.m02 = ((1 - t) * m0.m02) + (t * m1.m02)
        m.m03 = ((1 - t) * m0.m03) + (t * m1.m03)
        m.m10 = ((1 - t) * m0.m10) + (t * m1.m10)
        m.m11 = ((1 - t) * m0.m11) + (t * m1.m11)
        m.m12 = ((1 - t) * m0.m12) + (t * m1.m12)
        m.m13 = ((1 - t) * m0.m13) + (t * m1.m13)
        m.m20 = ((1 - t) * m0.m20) + (t * m1.m20)
        m.m21 = ((1 - t) * m0.m21) + (t * m1.m21)
        m.m22 = ((1 - t) * m0.m22) + (t * m1.m22)
        m.m23 = ((1 - t) * m0.m23) + (t * m1.m23)

        return m
    }
    
    static func == (lhs: AffineTransform, rhs: AffineTransform) -> Bool {
       return (lhs.m00 == rhs.m00) && (lhs.m01 == rhs.m01) && (lhs.m02 == rhs.m02) && (lhs.m03 == rhs.m03) && (lhs.m10 == rhs.m10) && (lhs.m11 == rhs.m11) && (lhs.m12 == rhs.m12) && (lhs.m13 == rhs.m13) && (lhs.m20 == rhs.m20) && (lhs.m21 == rhs.m21) && (lhs.m22 == rhs.m22) && (lhs.m23 == rhs.m23)
    }
}
