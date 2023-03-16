//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//
import Foundation

final class UI {
    static var ui: UserInterface = ConsoleInterface()
    static var canceled: Bool = false
    static var _verbosity: PrintLevel = .INFO

    init() {}

    // Sets the active user interface implementation
    static func set(_ ui: UserInterface) {
        self.ui = ui
    }

    static func verbosity(_ verbosity: PrintLevel) {
        UI._verbosity = verbosity
    }

    static func formatOutput(_ m: Module, _ level: PrintLevel, _ s: String, file _: String = #file, function _: String = #function, line _: Int = #line) -> String {
        switch level {
            case .DETAIL:
                return "📗 " + ANSIColors.green.rawValue + "\(m) \(level): \(s)"
            case .INFO:
                return "📘 " + ANSIColors.white.rawValue + "\(m) \(level): \(s)"
            case .WARN:
                return "📙 " + ANSIColors.yellow.rawValue + "\(m) \(level): \(s)"
            case .ERROR:
                return "📕 " + ANSIColors.red.rawValue + "\(m) \(level): \(s)"
        }
    }

    static func printDetailed(_ m: Module, _ s: String) {
        if _verbosity >= .DETAIL {
            ui.printLine(m, PrintLevel.DETAIL, s)
        }
    }

    static func printInfo(_ m: Module, _ s: String) {
        if _verbosity >= .INFO {
            ui.printLine(m, PrintLevel.INFO, s)
        }
    }

    static func printWarning(_ m: Module, _ s: String) {
        if _verbosity >= .WARN {
            ui.printLine(m, PrintLevel.WARN, s)
        }
    }

    static func printError(_ m: Module, _ s: String) {
        if _verbosity >= .ERROR {
            ui.printLine(m, PrintLevel.ERROR, s)
        }
    }

    static func taskStart(_ s: String, _ min: Int32, _ max: Int32) {
        ui.taskStart(s, min, max)
    }

    static func taskUpdate(_ current: Int32) {
        ui.taskUpdate(current)
    }

    static func taskStop() {
        ui.taskStop()
        //  reset canceled status
        //  this assume the parent application will deal with it immediately
        canceled = false
    }

    // Cancel the currently active task. This forces the application to abort as
    // soon as possible.
    static func taskCancel() {
        UI.printInfo(.GUI, "Abort requested by the user ...")
        UI.canceled = true
    }

    // Check to see if the current task should be aborted.
    //
    // @return true if the current task should be stopped,
    //         false otherwise
    static func taskCanceled() -> Bool {
        if UI.canceled {
            UI.printInfo(.GUI, "Abort request noticed by the current task")
        }

        return UI.canceled
    }

    enum Module {
        case API
        case GEOM
        case HAIR
        case ACCEL
        case BCKT
        case IPR
        case LIGHT
        case GUI
        case SCENE
        case BENCH
        case TEX
        case IMG
        case DISP
        case QMC
        case SYS
        case USER
        case CAM
    }

    enum PrintLevel: Int, Comparable {
        static func < (lhs: UI.PrintLevel, rhs: UI.PrintLevel) -> Bool {
            lhs.rawValue < rhs.rawValue
        }

        static func > (lhs: UI.PrintLevel, rhs: UI.PrintLevel) -> Bool {
            lhs.rawValue > rhs.rawValue
        }

        static func <= (lhs: UI.PrintLevel, rhs: UI.PrintLevel) -> Bool {
            lhs.rawValue <= rhs.rawValue
        }

        static func >= (lhs: UI.PrintLevel, rhs: UI.PrintLevel) -> Bool {
            lhs.rawValue >= rhs.rawValue
        }

        static func == (lhs: UI.PrintLevel, rhs: UI.PrintLevel) -> Bool {
            lhs.rawValue == rhs.rawValue
        }

        case ERROR = 0
        case WARN = 1
        case INFO = 2
        case DETAIL = 3
    }
}

enum ANSIColors: String {
    case black = "\u{001B}[0;30m"
    case red = "\u{001B}[0;31m"
    case green = "\u{001B}[0;32m"
    case yellow = "\u{001B}[0;33m"
    case blue = "\u{001B}[0;34m"
    case magenta = "\u{001B}[0;35m"
    case cyan = "\u{001B}[0;36m"
    case white = "\u{001B}[0;37m"

    func name() -> String {
        switch self {
        case .black: return "Black"
        case .red: return "Red"
        case .green: return "Green"
        case .yellow: return "Yellow"
        case .blue: return "Blue"
        case .magenta: return "Magenta"
        case .cyan: return "Cyan"
        case .white: return "White"
        }
    }

    static func all() -> [ANSIColors] {
        return [.black, .red, .green, .yellow, .blue, .magenta, .cyan, .white]
    }
}
