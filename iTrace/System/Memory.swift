//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

import Foundation

struct Memory {
    static func sizeOf(_ array: [Int32]?) -> String {
        return bytesTostring(Int64(array == nil ? 0 : 4 * array!.count))
    }

    // FIXME: controllare se la nuova implementazione e' corretta
    /*
     static func sizeOf<T>(_ array: [T]?) -> String {
         return bytesTostring(Int64(array == nil ? 0 : MemoryLayout.size(ofValue: T.self) * array!.count))

     }
     */
    static func bytesTostring(_ bytes: Int64) -> String {
        if bytes < 1024 {
            return "\(bytes)b"
        }

        if bytes < (1024 * 1024) {
            return "\((bytes + 512) >>> 10)Kb"
        }

        return "\((bytes + (512 * 1024)) >>> 20)Mb"
    }
    
    static func maxMemory() -> UInt64 {
        let p: UInt64 = ProcessInfo.processInfo.physicalMemory // PerformanceCounter("Memory", "Available Bytes")

        return p
    }
}
