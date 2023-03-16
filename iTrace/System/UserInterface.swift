//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

protocol UserInterface: class {
    // Displays some information to the user from the specified module with the
    // specified print level. A user interface is free to show or ignore any
    // message. Level filtering is done in the core and shouldn't be
    // re-implemented by the user interface. All messages will be short enough
    // to fit on one line.
    //
    // @param m module the message came from
    // @param level seriousness of the message
    // @param s string to display
    func printLine(_ m: UI.Module, _ level: UI.PrintLevel, _ s: String)

    // Prepare a progress bar representing a lengthy task. The actual progress
    // is first shown by the call to update and closed when update is closed
    // with the max value. It is currently not possible to nest calls to
    // setTask, so only one task needs to be tracked at a time.
    //
    // @param s desriptive string
    // @param min minimum value of the task
    // @param max maximum value of the task
    func taskStart(_ s: String, _ min: Int32, _ max: Int32)

    // updates the current progress bar to a value between the current min and
    // max. When min or max are passed the progressed bar is shown or hidden
    // respectively.
    //
    // @param current current value of the task in progress.
    func taskUpdate(_ current: Int32)

    // Closes the current progress bar to indicate the task is over
    func taskStop()
}
