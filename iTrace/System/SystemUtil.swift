//
//  SystemUtil.swift
//  iTrace
//
//  Created by Fabrizio Pezzola on 30/03/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

import Foundation

struct SystemUtil {
    //  This is a quick system test which verifies that the user has launched
    static func runSystemCheck() {
        let RECOMMENDED_MAX_SIZE: Int64 = 800
        let maxMb: UInt64 = Memory.maxMemory() / 1_048_576

        if maxMb < RECOMMENDED_MAX_SIZE {
            UI.printError(.API, "Available memory is below \(RECOMMENDED_MAX_SIZE) MB (found \(maxMb) MB only).\n")
        }
        
        UI.printDetailed(.API, "Environment settings:")
        UI.printDetailed(.API, "  * Max memory available : \(maxMb) MB")
        UI.printDetailed(.API, "  * Processor count : \(ProcessInfo.processInfo.processorCount)")
        UI.printDetailed(.API, "  * Operating system : \(ProcessInfo.processInfo.operatingSystemVersionString)")
    }
}
