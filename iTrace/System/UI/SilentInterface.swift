//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class SilentInterface: UserInterface {
    func printLine(_ m: UI.Module, _ level: UI.PrintLevel, _ s: String) {}

    func taskStart(_: String, _: Int32, _: Int32) {}

    func taskUpdate(_: Int32) {}

    func taskStop() {}
}
