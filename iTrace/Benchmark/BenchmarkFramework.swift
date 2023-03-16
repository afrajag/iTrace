//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

import Foundation

final class BenchmarkFramework {
    var timers: [TraceTimer?]?
    var timeLimit: Int32 = 0 // time limit in seconds
    
    init(_ iterations: Int32, _ timeLimit: Int32) {
        self.timeLimit = timeLimit
        
        timers = [TraceTimer?](repeating: TraceTimer(), count: Int(iterations))
    }

    func currentTimeInMilliSeconds() -> Int64
    {
        let currentDate = Date()
        let since1970 = currentDate.timeIntervalSince1970
        
        return Int64(since1970 * 1000)
    }
    
    func execute(_ test: BenchmarkTest) {
        //  clear previous results
        for i in 0 ..< timers!.count {
            timers![i] = nil
        }
        
        //  loop for the specified number of iterations or until the time limit
        let startTime: Int64 = currentTimeInMilliSeconds()
        
        var i: Int = 0
        
        while ((currentTimeInMilliSeconds() - startTime) / 1000000000) < timeLimit {
            UI.printInfo(.BENCH, "Running iteration \(i + 1)")
            
            timers![i] = TraceTimer()
            
            test.kernelBegin()
            
            timers![i]!.start()
            
            test.kernelMain()
            
            timers![i]!.end()
            
            test.kernelEnd()
            
            i += 1
        }
        
        //  report stats
        var avg: Double = 0
        
        var _min: Double = Double.infinity
        var _max: Double = -Double.infinity
        
        var n: Int32 = 0
        
        for t in timers! {
            if t == nil {
                break
            }
            
            let s: Double = t!.seconds()
            
            _min = min(_min, s)
            _max = max(_max, s)
            
            avg = avg + s
            
            n += 1
        }
        
        if n == 0 {
            return
        }
        
        avg /= Double(n)
        
        var stdDev: Double = 0
        
        for t in timers! {
            if t == nil {
                break
            }
            
            let s: Double = t!.seconds()
            
            stdDev += (s - avg) * (s - avg)
        }
        
        stdDev = sqrt(stdDev / Double(n))
        
        UI.printInfo(.BENCH, "Benchmark results:")
        UI.printInfo(.BENCH, "  * Iterations: \(n)")
        UI.printInfo(.BENCH, "  * Average:    \(avg)")
        UI.printInfo(.BENCH, "  * Fastest:    \(_min)")
        UI.printInfo(.BENCH, "  * Longest:    \(_max)")
        UI.printInfo(.BENCH, "  * Deviation:  \(stdDev)")
        
        var _i: Int = 0
        
        while  timers![Int(_i)] != nil {
            UI.printDetailed(.BENCH, "  * Iteration \(_i + 1): \(timers![_i] ?? TraceTimer())")
            
            _i += 1
        }
    }
}
