//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

import Foundation
import Progress

final class ConsoleInterface: UserInterface {
    var min: Int32 = 0
    var max: Int32 = 0
    var invP: Float = 0.0
    var task: String = ""
    var lastP: Int32 = 0

    let lockQueue = DispatchQueue(label: "consoleinterface.lock.serial.queue")
    
    var bar: ProgressBar?

    var lastPrintedTime = 0.0

    init() {}

    func printLine(_ m: UI.Module, _ level: UI.PrintLevel, _ s: String) {
        print(UI.formatOutput(m, level, s))
    }

    func taskStart(_ s: String, _ min: Int32, _ max: Int32) {
        bar = ProgressBar(count: Int(max), configuration: [ProgressString(string: UI.formatOutput(.BCKT, .INFO, "  *")), ProgressIndex(), ProgressString(string: "done ("), ProgressPercent(), ProgressString(string: ") :"), ProgressBarLine(barLength: 30), ProgressTimeEstimates()])
        
        /*
        task = s
        self.min = min
        self.max = max
        lastP = -1
        invP = 100.0 / Float((max - min))
        */
    }

    func taskUpdate(_ current: Int32) {
        lockQueue.sync { // synchronized block
            bar?.next()
        }
        
        /*
        let p = (min == max) ? 0 : Int32(Float(current - min) * invP)
        
        if (p != lastP) {
            lastP = p
            
            print("\u{1B}[1A\u{1B}[K\(task) [\(lastP)%]")
        }
        */
    }

    func taskStop() {
        //print("                                                                      \r")
    }
}
