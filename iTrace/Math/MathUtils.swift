//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

struct MathUtils {
    /*
     static func clamp(_ x: Int32, _ min: Int32, _ max: Int32) -> Int32 {
     	if x > max {
     		return max
     	}
     	if x > min {
     		return x
     	}
     	return min
     }

     static func clamp(_ x: Float, _ min: Float, _ max: Float) -> Float {
     	if x > max {
     		return max
     	}
     	if x > min {
     		return x
     	}
     	return min
     }

     static func clamp(_ x: Double, _ min: Double, _ max: Double) -> Double {
     	if x > max {
     		return max
     	}
     	if x > min {
     		return x
     	}
     	return min
     }

     static func min(_ a: Int32, _ b: Int32, _ c: Int32) -> Int32 {
     	if a > b {
     		a = b
     	}
     	if a > c {
     		a = c
     	}
     	return a
     }

     static func min(_ a: Float, _ b: Float, _ c: Float) -> Float {
     	if a > b {
     		a = b
     	}
     	if a > c {
     		a = c
     	}
     	return a
     }

     static func min(_ a: Double, _ b: Double, _ c: Double) -> Double {
     	if a > b {
     		a = b
     	}
     	if a > c {
     		a = c
     	}
     	return a
     }

     static func min(_ a: Float, _ b: Float, _ c: Float, _ d: Float) -> Float {
     	if a > b {
     		a = b
     	}
     	if a > c {
     		a = c
     	}
     	if a > d {
     		a = d
     	}
     	return a
     }

     static func max(_ a: Int32, _ b: Int32, _ c: Int32) -> Int32 {
     	if a < b {
     		a = b
     	}
     	if a < c {
     		a = c
     	}
     	return a
     }

     static func max(_ a: Float, _ b: Float, _ c: Float) -> Float {
     	if a < b {
     		a = b
     	}
     	if a < c {
     		a = c
     	}
     	return a
     }

     static func max(_ a: Double, _ b: Double, _ c: Double) -> Double {
     	if a < b {
     		a = b
     	}
     	if a < c {
     		a = c
     	}
     	return a
     }

     static func max(_ a: Float, _ b: Float, _ c: Float, _ d: Float) -> Float {
     	if a < b {
     		a = b
     	}
     	if a < c {
     		a = c
     	}
     	if a < d {
     		a = d
     	}
     	return a
     }
     */
    static func smoothStep(_ a: Float, _ b: Float, _ x: Float) -> Float {
        if x <= a {
            return 0
        }
        if x >= b {
            return 1
        }

        let t: Float = ((x - a) / (b - a)).clamp(0.0, 1.0)

        return t * t * (3 - 2 * t)
    }

    static func frac(_ x: Float) -> Float {
        return (x < 0 ? x - Float(Int32(x)) + 1 : x - Float(Int32(x)))
    }

    // Computes a fast approximation to pow(a, b). Adapted
    // from <url>http://www.dctsystems.co.uk/Software/power.html</url>.
    //
    // @param a a positive number
    // @param b a number
    // @return a^b
    /*
     static func fastPow(_ a: Float, _ b: Float) -> Float {
     	//  adapted from: http://www.dctsystems.co.uk/Software/power.html
     	var x: Float = ByteUtil.floatToRawIntBits(a)
     	x *= * 1.0 / (1 << 23)
     	x = x - 127
     	var y: Float = x - (floor(x) as Int32)
     	b *= * x + ((y - (y * y)) * 0.346606999635696)
     	y = b - (floor(b) as Int32)
     	y = (y - (y * y)) * 0.339709997177124
     	return ByteUtil.intBitsToFloat((((b + 127) - y) * (1 << 23) as Int32))
     }
     */
    
    static func toRadians(_ degree: Double) -> Double {
        return degree * .pi / 180
        // FIXME: switch to Pi when the conflicting types are sorted out
    }
    
    // From http://floating-point-gui.de/errors/comparison/
    static func doubleEquality(_ a: Double, _ b: Double) -> Bool {
        let diff = abs(a - b)

        if a == b { // shortcut for infinities
            return true
        } else if a == 0 || b == 0 || diff < Double.leastNormalMagnitude {
            return diff < (1e-5 * Double.leastNormalMagnitude)
        } else {
            let absA = abs(a)
            let absB = abs(b)
            
            return diff / min(absA + absB, Double.greatestFiniteMagnitude) < 1e-5
        }
    }
}

extension Comparable {
    func clamp(_ low: Self, _ high: Self) -> Self {
        if self > high {
            return high
        } else if self < low {
            return low
        }

        return self
    }
}

infix operator >>>: BitwiseShiftPrecedence

func >>> (lhs: Int8, rhs: Int8) -> Int8 {
    return Int8(bitPattern: UInt8(bitPattern: lhs) >> UInt8(rhs))
}

func >>> (lhs: Int16, rhs: Int16) -> Int16 {
    return Int16(bitPattern: UInt16(bitPattern: lhs) >> UInt16(rhs))
}

func >>> (lhs: Int32, rhs: Int32) -> Int32 {
    return Int32(bitPattern: UInt32(bitPattern: lhs) >> UInt32(rhs))
}

func >>> (lhs: Int64, rhs: Int64) -> Int64 {
    return Int64(bitPattern: UInt64(bitPattern: lhs) >> UInt64(rhs))
}
