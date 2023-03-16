//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//
import Foundation

final class TraceTimer {
    var startTime: UInt64 = 0
    var endTime: UInt64 = 0

    init() {
        startTime = 0
        endTime = 0
    }

    func start() {
        startTime = DispatchTime.now().uptimeNanoseconds
        endTime = DispatchTime.now().uptimeNanoseconds
    }

    func end() {
        endTime = DispatchTime.now().uptimeNanoseconds
    }

    func nanos() -> Int64 {
        return Int64(endTime - startTime)
    }

    func seconds() -> Double {
        return Double(nanos()) * 1e-09
    }

    static func toString(_ nanos: UInt64) -> String {
        let t: TraceTimer = TraceTimer()

        t.endTime = nanos

        return t.toString()
    }

    static func toString(_ seconds: Double) -> String {
        let t: TraceTimer = TraceTimer()

        t.endTime = UInt64(seconds * 1_000_000_000.0)

        return t.toString()
    }

    func toString() -> String {
        var millis: UInt64 = UInt64(nanos() / (1000 * 1000))

        if millis < 10000 {
            return "\(millis)ms"
        }

        let hours: UInt64 = millis / (60 * 60 * 1000)
        millis = millis - hours * 60 * 60 * 1000

        let minutes: UInt64 = millis / (60 * 1000)
        millis = millis - minutes * 60 * 1000

        let seconds: UInt64 = millis / 1000
        millis = millis - seconds * 1000

        return "\(hours):\(minutes):\(seconds).\(millis / 100)"
    }
}
