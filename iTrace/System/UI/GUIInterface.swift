//
//  GUIInterface.swift
//  iTrace
//
//  Created by Fabrizio Pezzola on 25/04/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

import AppKit

final class GUIInterface: UserInterface {
    func printLine(_: UI.Module, _: UI.PrintLevel, _: String) {}

    func taskStart(_: String, _: Int32, _: Int32) {}

    func taskUpdate(_: Int32) {}

    func taskStop() {}
}


