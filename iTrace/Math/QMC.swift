//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

struct QMC {
    static var MAX_SIGMA_ORDER: Int32 = 15
    static let NUM: Int32 = 128
    static var SIGMA: [[Int32]] = [[Int32]](repeating: [], count: Int(NUM))
    static var PRIMES: [Int32] = [Int32](repeating: 0, count: Int(NUM))
    static var FIBONACCI: [Int32] = [Int32](repeating: 0, count: 47)
    static var FIBONACCI_INV: [Double] = [Double](repeating: 0, count: FIBONACCI.count)
    static var KOROBOV: [Double] = [Double](repeating: 0, count: Int(NUM))
    
    // FIXME: controllare che questo metodo venga chiamato prima di tutto
    static func buildSigPri() {
        UI.printInfo(.QMC, "Initializing Faure scrambling tables ...")

        //  build table of first primes
        PRIMES[0] = 2

        for i in 1 ..< PRIMES.count {
            PRIMES[i] = nextPrime(PRIMES[i - 1])
        }

        var table: [[Int32]] = [[Int32]](repeating: [], count: Int(PRIMES[PRIMES.count - 1]) + 1)

        table[2] = [Int32](repeating: 0, count: 2)
        table[2][0] = 0
        table[2][1] = 1

        for i in 3 ... PRIMES[PRIMES.count - 1] {
            table[Int(i)] = [Int32](repeating: 0, count: Int(i))

            if (i & 1) == 0 {
                let prev: [Int32] = table[Int(i) >> 1]

                for j in 0 ..< prev.count {
                    table[Int(i)][j] = 2 * prev[j]
                }

                for j in 0 ..< prev.count {
                    table[Int(i)][prev.count + j] = (2 * prev[j]) + 1
                }
            } else {
                let prev: [Int32] = table[Int(i) - 1]
                let med: Int32 = (i - 1) >> 1

                for j in 0 ..< med {
                    table[Int(i)][Int(j)] = prev[Int(j)] + (prev[Int(j)] >= med ? 1 : 0)
                }

                table[Int(i)][Int(med)] = med

                for j in 0 ..< med {
                    table[Int(i)][Int(med + j) + 1] = prev[Int(j + med)] + (prev[Int(j + med)] >= med ? 1 : 0)
                }
            }
        }

        for i in 0 ..< PRIMES.count {
            let p: Int32 = PRIMES[i]

            SIGMA[i] = [Int32](repeating: 0, count: Int(p))

            SIGMA[i][0 ..< Int(p)] = table[Int(p)][0 ..< Int(p)]
        }

        UI.printInfo(.QMC, "Initializing lattice tables ...")

        FIBONACCI[0] = 0
        FIBONACCI[1] = 1

        for i in 2 ..< FIBONACCI.count {
            FIBONACCI[i] = FIBONACCI[i - 1] + FIBONACCI[i - 2]
            FIBONACCI_INV[i] = 1.0 / Double(FIBONACCI[i])
        }

        KOROBOV[0] = 1

        for i in 1 ..< KOROBOV.count {
            KOROBOV[i] = 203 * KOROBOV[i - 1]
        }
    }

    static func nextPrime(_ p: Int32) -> Int32 {
        var _p = p + (p & 1) + 1

        while true {
            var div: Int32 = 3
            var isPrime: Bool = true

            while isPrime, (div * div) <= _p {
                isPrime = (_p % div) != 0

                div += 2
            }

            if isPrime {
                return _p
            }

            _p += 2
        }
    }

    // >>> operator
    static func riVDC(_ bits: Int32, _ r: Int32) -> Double {
        var _bits: Int64 = Int64(bits)

        _bits = (_bits << 16) | (_bits >>> 16)
        _bits = ((_bits & 0x00FF_00FF) << 8) | ((_bits & 0xFF00_FF00) >>> 8)
        _bits = ((_bits & 0x0F0F_0F0F) << 4) | ((_bits & 0xF0F0_F0F0) >>> 4)
        _bits = ((_bits & 0x3333_3333) << 2) | ((_bits & 0xCCCC_CCCC) >>> 2)
        _bits = ((_bits & 0x5555_5555) << 1) | ((_bits & 0xAAAA_AAAA) >>> 1)

        _bits ^= Int64(r)

        return Double(_bits & 0xFFFF_FFFF) / Double(0x1_0000_0000)
    }

    static func riS(_ i: Int32, _ r: Int32) -> Double {
        var v: Int32 = 1 << 31

        var _i = i
        var _r: Int64 = Int64(r)

        while _i != 0 {
            if (_i & 1) != 0 {
                _r = _r ^ Int64(v)
            }

            _i = _i >>> 1
            v ^= v >>> 1
        }

        return Double(_r & 0xFFFF_FFFF) / Double(0x1_0000_0000)
    }

    static func riLP(_ i: Int32, _ r: Int32) -> Double {
        var v: Int32 = 1 << 31

        var _i = i
        var _r: Int64 = Int64(r)

        while _i != 0 {
            if (_i & 1) != 0 {
                _r = _r ^ Int64(v)
            }

            _i = _i >>> 1
            v |= v >>> 1
        }

        return Double(_r & 0xFFFF_FFFF) / Double(0x1_0000_0000)
    }

    static func halton(_ d: Int32, _ i: Int32) -> Double {
        var _i: Int64 = Int64(i)

        //  generalized Halton sequence
        switch d {
        case 0:
            _i = (_i << 16) | (_i >>> 16)
            _i = ((_i & 0x00FF_00FF) << 8) | ((_i & 0xFF00_FF00) >>> 8)
            _i = ((_i & 0x0F0F_0F0F) << 4) | ((_i & 0xF0F0_F0F0) >>> 4)
            _i = ((_i & 0x3333_3333) << 2) | ((_i & 0xCCCC_CCCC) >>> 2)
            _i = ((_i & 0x5555_5555) << 1) | ((_i & 0xAAAA_AAAA) >>> 1)

            return Double(_i & 0xFFFF_FFFF) / Double(0x1_0000_0000)
        case 1:
            var v: Double = 0
            let inv: Double = 1.0 / 3
            var p: Double
            var n: Int32

            p = inv
            n = i

            while n != 0 {
                v += Double(n % 3) * p

                p *= inv
                n /= 3
            }

            return v
        default:
            do {
                // nothing
            }
            // UI.printError(.QMC, "What I'm doing here ?")
        }

        let base: Int32 = PRIMES[Int(d)]
        let perm: [Int32] = SIGMA[Int(d)]
        var v: Double = 0
        let inv: Double = 1.0 / Double(base)
        var p: Double
        var n: Int32

        p = inv
        n = i

        while n != 0 {
            v += Double(perm[Int(n % base)]) * p

            p *= inv
            n /= base
        }

        return v
    }

    // Compute mod(x,1), assuming that x is positive or 0.
    //
    // @param x any number >= 0
    // @return mod(x,1)
    static func mod1(_ x: Double) -> Double {
        //  assumes x >= 0
        return x - Double(Int32(bitPattern: UInt32(x)))
    }

    // Compute sigma function used to seed QMC sequence trees. The sigma table
    // is exactly 2^order elements long, and therefore i should be in the: [0,
    // 2^order) interval. This function is equal to 2^order*halton(0,i)
    //
    // @param i index
    // @param order
    // @return sigma function
    static func sigma(_ i: Int32, _ order: Int32) -> Int32 {
        assert(order > 0 && order < 32)
        assert(i >= 0 && i < (1 << order))

        var _i: Int64 = Int64(i)

        _i = (_i << 16) | (_i >>> 16)
        _i = ((_i & 0x00FF_00FF) << 8) | ((_i & 0xFF00_FF00) >>> 8)
        _i = ((_i & 0x0F0F_0F0F) << 4) | ((_i & 0xF0F0_F0F0) >>> 4)
        _i = ((_i & 0x3333_3333) << 2) | ((_i & 0xCCCC_CCCC) >>> 2)
        _i = ((_i & 0x5555_5555) << 1) | ((_i & 0xAAAA_AAAA) >>> 1)

        return Int32(bitPattern: UInt32(_i)) >>> (32 - order)
    }

    static func getFibonacciRank(_ n: Int32) -> Int32 {
        var k: Int32 = 3

        while FIBONACCI[Int(k)] <= n {
            k += 1
        }

        return k - 1
    }

    static func fibonacci(_ k: Int32) -> Int32 {
        return FIBONACCI[Int(k)]
    }

    static func fibonacciLattice(_ k: Int32, _ i: Int32, _ d: Int32) -> Double {
        return (d == 0 ? Double(i) * FIBONACCI_INV[Int(k)] : mod1(Double(i * FIBONACCI[Int(k) - 1] * Int32(FIBONACCI_INV[Int(k)]))))
    }

    static func reducedCPRotation(_ k: Int32, _ d: Int32, _ x0: Double, _ x1: Double) -> Double {
        var j1: Int32 = FIBONACCI[(2 * ((Int(k) - 1) >> 2)) + 1]
        var j2: Int32 = FIBONACCI[2 * ((Int(k) + 1) >> 2)]

        if d == 1 {
            j1 = (j1 * FIBONACCI[Int(k) - 1]) % FIBONACCI[Int(k)]
            j2 = ((j2 * FIBONACCI[Int(k) - 1]) % FIBONACCI[Int(k)]) - FIBONACCI[Int(k)]
        }

        let first = (x0 * Double(j1) + x1 * Double(j2))
        let _inv = FIBONACCI_INV[Int(k)]

        return first * _inv
    }

    static func korobovLattice(_ m: Int32, _ i: Int32, _ d: Int32) -> Double {
        return mod1(Double((i * Int32(KOROBOV[Int(d)])) / (1 << m)))
    }
}
