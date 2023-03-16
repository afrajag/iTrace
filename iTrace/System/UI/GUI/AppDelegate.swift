//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    lazy var window: NSWindow = NSApplication.shared.windows[0]
    
    var scene: SceneBuilder? = nil
    
    let viewController: iTraceViewController = iTraceViewController()

    init(_ scene: SceneBuilder?) {
        self.scene = scene
    }
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        let view = viewController.view
        
        window.contentView = view
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.global().async {
            if self.scene != nil {
                self.scene!.render(GUIDisplay(self))
            }
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
