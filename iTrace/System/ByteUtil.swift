//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

struct ByteUtil {
    static func get2Bytes(_ i: Int32) -> [UInt8] {
        var b: [UInt8] = [UInt8](repeating: 0, count: 2)

        b[0] = UInt8(i & 0xFF)
        b[1] = UInt8((i >> 8) & 0xFF)

        return b
    }

    static func get4Bytes(_ i: Int32) -> [UInt8] {
        var b: [UInt8] = [UInt8](repeating: 0, count: 4)

        b[0] = UInt8(i & 0xFF)
        b[1] = UInt8((i >> 8) & 0xFF)
        b[2] = UInt8((i >> 16) & 0xFF)
        b[3] = UInt8((i >> 24) & 0xFF)

        return b
    }

    static func get4BytesInv(_ i: Int32) -> [UInt8] {
        var b: [UInt8] = [UInt8](repeating: 0, count: 4)

        b[3] = UInt8(i & 0xFF)
        b[2] = UInt8((i >> 8) & 0xFF)
        b[1] = UInt8((i >> 16) & 0xFF)
        b[0] = UInt8((i >> 24) & 0xFF)

        return b
    }

    static func get8Bytes(_ i: Int64) -> [UInt8] {
        var b: [UInt8] = [UInt8](repeating: 0, count: 8)

        b[0] = UInt8(i & 0xFF)
        b[1] = UInt8((i >> 8) & 0xFF)
        b[2] = UInt8((i >> 16) & 0xFF)
        b[3] = UInt8((i >> 24) & 0xFF)
        b[4] = UInt8((i >> 32) & 0xFF)
        b[5] = UInt8((i >> 40) & 0xFF)
        b[6] = UInt8((i >> 48) & 0xFF)
        b[7] = UInt8((i >> 56) & 0xFF)

        return b
    }

    static func toLong(_ input: [UInt8]) -> Int64 {
        return Int64(toInt(input[0], input[1], input[2], input[3])) | (Int64(toInt(input[4], input[5], input[6], input[7])) << 32)
    }

    static func toInt(_ in0: UInt8, _ in1: UInt8, _ in2: UInt8, _ in3: UInt8) -> Int32 {
        let _a = (in0 & 0xFF)
        let _b = ((in1 & 0xFF) << 8)
        let _c = ((in2 & 0xFF) << 16)
        let _d = ((in3 & 0xFF) << 24)

        return Int32(_a | _b | _c | _d)
    }

    static func toInt(_ input: [UInt8]) -> Int32 {
        return toInt(input[0], input[1], input[2], input[3])
    }

    static func toInt(_ input: [UInt8], _ ofs: Int32) -> Int32 {
        return toInt(input[Int(ofs) + 0], input[Int(ofs) + 1], input[Int(ofs) + 2], input[Int(ofs) + 3])
    }

    static func floatToHalf(_ f: Float) -> Int32 {
        let i: Int32 = ByteUtil.floatToRawIntBits(f)

        //  unpack the s, e and m of the float
        let s: Int32 = (i >> 16) & 0x00008000
        var e: Int32 = ((i >> 23) & 0x000000FF) - (127 - 15)
        var m: Int32 = i & 0x007FFFFF

        //  pack them back up, forming a half
        if e <= 0 {
            if e < -10 {
                //  E is less than -10. The absolute value of f is less than
                //  HALF_MIN
                //  convert f to 0
                return 0
            }

            //  E is between -10 and 0.
            m = (m | 0x00800000) >> (1 - e)

            //  Round to nearest, round "0.5" up.
            if (m & 0x00001000) == 0x00001000 {
                m += 0x00002000
            }

            //  Assemble the half from s, e (zero) and m.
            return s | (m >> 13)
        } else if e == (0xFF - (127 - 15)) {
            if m == 0 {
                //  F is an infinity; convert f to a half infinity
                return s | 0x7C00
            } else {
                //  F is a NAN; we produce a half NAN that preserves the sign bit
                //  and the 10 leftmost bits of the significand of f
                m >>= 13

                return s | 0x7C00 | m | (m == 0 ? 0 : 1)
            }
        } else {
            //  E is greater than zero. F is a normalized float. Round to
            //  nearest, round "0.5" up
            if (m & 0x00001000) == 0x00001000 {
                m += 0x00002000

                if (m & 0x00800000) == 0x00800000 {
                    m = 0

                    e += 1
                }
            }

            //  Handle exponent overflow
            if e > 30 {
                //  overflow (); // Cause a hardware floating point overflow;
                return s | 0x7C00
                //  if this returns, the half becomes an
            } //  infinity with the same sign as f.

            //  Assemble the half from s, e and m.
            return s | (e << 10) | (m >> 13)
        }
    }

    /*
     static func floatToRawIntBits(_ f: Float) -> Int32 {
         // FIXME: controllare se possibile mettere un altro tipo di implementazione (si puo' usare Float.bitPattern ma non gestisce i negativi)
         return unsafeBitCast(f, to: Int32.self)
     }

     static func intBitsToFloat(_ i: Int32) -> Float {
         // FIXME: controllare se possibile mettere un altro tipo di implementazione
         return unsafeBitCast(i, to: Float.self)
     }
    */

    static func floatToRawIntBits(_ f: Float) -> Int32 {
        return Int32(bitPattern: f.bitPattern)
    }

    static func intBitsToFloat(_ i: Int32) -> Float {
        return Float(bitPattern: UInt32(bitPattern: i))
    }
}
