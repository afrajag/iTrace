//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//
import Foundation

struct Solvers {
    // Solves the equation ax^2+bx+c=0. Solutions are returned in a sorted array
    // if they exist.
    //
    // @param a coefficient of x^2
    // @param b coefficient of x^1
    // @param c coefficient of x^0
    // @return an array containing the two real roots, or null if
    //         no real solutions exist
    static func solveQuadric(_ a: Double, _ b: Double, _ c: Double) -> [Double]? {
        var disc: Double = (b * b) - (4 * a * c)

        if disc < 0 {
            return nil
        }

        disc = sqrt(disc)

        let q: Double = (b < 0 ? -0.5 * (b - disc) : -0.5 * (b + disc))
        let t0: Double = q / a
        let t1: Double = c / q

        //  return sorted array
        return (t0 > t1 ? [t1, t0] : [t0, t1])
    }

    // Solve a quartic equation of the form ax^4+bx^3+cx^2+cx^1+d=0. The roots
    // are returned in a sorted array of doubles in increasing order.
    //
    // @param a coefficient of x^4
    // @param b coefficient of x^3
    // @param c coefficient of x^2
    // @param d coefficient of x^1
    // @param e coefficient of x^0
    // @return a sorted array of roots, or null if no solutions
    //         exist
    static func solveQuartic(_ a: Double, _ b: Double, _ c: Double, _ d: Double, _ e: Double) -> [Double]? {
        let inva: Double = 1 / a
        let c1: Double = b * inva
        let c2: Double = c * inva
        let c3: Double = d * inva
        let c4: Double = e * inva

        // cubic resolvant
        let c12: Double = c1 * c1
        let p: Double = (-0.375 * c12) + c2
        let q: Double = ((0.125 * c12 * c1) - (0.5 * c1 * c2)) + c3
        let r: Double = (((-0.01171875 * c12 * c12) + (0.0625 * c12 * c2)) - (0.25 * c1 * c3)) + c4
        let z: Double = solveCubicForQuartic(-0.5 * p, -r, (0.5 * r * p) - (0.125 * q * q))
        var d1: Double = (2.0 * z) - p

        if d1 < 0 {
            if d1 > 1e-10 {
                d1 = 0
            } else {
                return nil
            }
        }

        var d2: Double

        if d1 < 1e-10 {
            d2 = (z * z) - r
            if d2 < 0 {
                return nil
            }
            d2 = sqrt(d2)
        } else {
            d1 = sqrt(d1)
            d2 = (0.5 * q) / d1
        }

        //  setup usefull values for the quadratic factors
        let q1: Double = d1 * d1
        let q2: Double = -0.25 * c1
        var pm: Double = q1 - (4 * (z - d2))
        var pp: Double = q1 - (4 * (z + d2))

        if pm >= 0, pp >= 0 {
            //  4 roots ()
            pm = sqrt(pm)
            pp = sqrt(pp)

            var results: [Double] = [Double](repeating: 0, count: 4)

            results[0] = (-0.5 * (d1 + pm)) + q2
            results[1] = (-0.5 * (d1 - pm)) + q2
            results[2] = (0.5 * (d1 + pp)) + q2
            results[3] = (0.5 * (d1 - pp)) + q2

            //  tiny insertion sort
            for i in 1 ... 4 - 1 {
                // for var j: Int32 = i; j >= results[j - 1] > results[j]; j-- {
                var j = i
                while Double(j) >= results[j - 1], results[j - 1] > results[j] {
                    let t: Double = results[j]

                    results[j] = results[j - 1]

                    results[j - 1] = t

                    j -= 1
                }
            }
            return results
        } else {
            if pm >= 0 {
                pm = sqrt(pm)

                var results: [Double] = [Double](repeating: 0, count: 2)

                results[0] = (-0.5 * (d1 + pm)) + q2
                results[1] = (-0.5 * (d1 - pm)) + q2

                return results
            } else {
                if pp >= 0 {
                    pp = sqrt(pp)

                    var results: [Double] = [Double](repeating: 0, count: 2)

                    results[0] = (0.5 * (d1 - pp)) + q2
                    results[1] = (0.5 * (d1 + pp)) + q2

                    return results
                }
            }
        }

        return nil
    }

    // Return only one root for the specified cubic equation. This routine is
    // only meant to be called by the quartic solver. It assumes the cubic is of
    // the form: x^3+px^2+qx+r.
    //
    // @param p
    // @param q
    // @param r
    // @return
    static func solveCubicForQuartic(_ p: Double, _ q: Double, _ r: Double) -> Double {
        let A2: Double = p * p
        let Q: Double = (A2 - (3.0 * q)) / 9.0
        let R: Double = ((p * (A2 - (4.5 * q))) + (13.5 * r)) / 27.0
        let Q3: Double = Q * Q * Q
        let R2: Double = R * R

        var d: Double = Q3 - R2

        let an: Double = p / 3.0

        if d >= 0 {
            d = R / sqrt(Q3)

            let theta: Double = acos(d) / 3.0
            let sQ: Double = -2.0 * sqrt(Q)

            return (sQ * cos(theta)) - an
        } else {
            let sQ: Double = pow(sqrt(R2 - Q3) + abs(R), 1.0 / 3.0)

            if R < 0 {
                return (sQ + (Q / sQ)) - an
            } else {
                return -sQ + (Q / sQ) - an
            }
        }
    }
}
