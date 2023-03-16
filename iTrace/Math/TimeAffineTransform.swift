//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class TimeAffineTransform {
    var transforms: [AffineTransform?]?
    var t0: Float = 0.0
    var t1: Float = 0.0
    var inv: Float = 0.0

    // Constructs a simple static matrix.
    //
    // @param m matrix value at all times
    init(_ m: AffineTransform?) {
        transforms = [m]

        t0 = 0
        t1 = 0
        inv = 1
    }

    init(_ n: Int32, _ t0: Float, _ t1: Float, _ inv: Float) {
        transforms = [AffineTransform?](repeating: nil, count: Int(n))

        self.t0 = t0
        self.t1 = t1
        self.inv = inv
    }

    // Redefines the number of steps in the matrix. The contents are only
    // re-allocated if the number of steps changes. This is to allow the matrix
    // to be incrementally specified.
    //
    // @param n
    func setSteps(_ n: Int32) {
        if transforms!.count != n {
            transforms = [AffineTransform](repeating: AffineTransform(), count: Int(n))

            if t0 < t1 {
                inv = Float(transforms!.count - 1) / (t1 - t0)
            } else {
                inv = 1
            }
        }
    }

    // updates the matrix for the given time step.
    //
    // @param i time step to update
    // @param m new value for the matrix at this time step
    func updateData(_ i: Int32, _ m: AffineTransform?) {
        transforms![Int(i)] = m
    }

    // Get the matrix for the given time step.
    //
    // @param i time step to get
    // @return matrix for the specfied time step
    func getData(_ i: Int32) -> AffineTransform? {
        return transforms![Int(i)]
    }

    // Get the number of matrix segments
    //
    // @return number of segments
    func numSegments() -> Int32 {
        return Int32(transforms!.count)
    }

    // update the time extents over which the matrix data is changing. If the
    // interval is empty, no motion will be produced, even if multiple values
    // have been specified.
    //
    // @param t0
    // @param t1
    func updateTimes(_ t0: Float, _ t1: Float) {
        self.t0 = t0
        self.t1 = t1

        if t0 < t1 {
            inv = Float(transforms!.count - 1) / (t1 - t0)
        } else {
            inv = 1
        }
    }

    func inverse() -> TimeAffineTransform? {
        let mi: TimeAffineTransform = TimeAffineTransform(Int32(transforms!.count), t0, t1, inv)

        for i in 0 ..< transforms!.count {
            if transforms![i] != nil {
                mi.transforms![i] = transforms![i]!.inverse()

                if mi.transforms![i] == nil {
                    return nil //  unable to invert
                }
            }
        }

        return mi
    }

    func sample(_ time: Float) -> AffineTransform? {
        if (transforms!.count == 1) || (t0 >= t1) {
            return transforms![0]
        } else {
            let nt: Float = (time.clamp(t0, t1) - t0) * inv
            let idx0: Int32 = Int32(nt)
            let idx1: Int32 = min(idx0 + 1, Int32(transforms!.count - 1))

            return AffineTransform.blend(transforms![Int(idx0)]!, transforms![Int(idx1)]!, Float(nt - Float(idx0)))
        }
    }
}
