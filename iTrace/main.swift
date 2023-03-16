//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

import Foundation
import AppKit

/*
 struct iTraceCLI: ParsableCommand {
 @Option(name: .shortAndLong, help: "Log verbosity.")
 var verbosity: Int?

 @Argument(help: "The scene to render.")
 var scene: String

 func run() throws {
     if let verbosity = self.verbosity {
         UI.verbosity(UI.PrintLevel(rawValue: verbosity)!)
     }

     iTrace().startRender()
 }
 }
 */

final class iTrace {

    var resolution: Int32 = 0

    required init() {
        UI.set(ConsoleInterface())
        UI.verbosity(.DETAIL)
    }

    func startRender() {
        UI.printInfo(.SCENE, " _ _______")
        UI.printInfo(.SCENE, "(_)__   __|")
        UI.printInfo(.SCENE, " _   | |_ __ __ _  ___ ___")
        UI.printInfo(.SCENE, "| |  | | '__/ _` |/ __/ _ \\")
        UI.printInfo(.SCENE, "| |  | | | | (_| | (_|  __/")
        UI.printInfo(.SCENE, "|_|  |_|_|  \\__,_|\\___\\___|")

        UI.printInfo(.SCENE, "Starting ...")

        if true {
            //let scene = SphereFlakeScene()
            //let scene = JuliaScene()
            //let scene = TestScene()
            //let scene = BumpScene()
            let scene = GumboAndTeapotScene()
            //let scene = CornellBoxJensenScene()
            //let scene = WireframeDemoScene()
            
            let sceneParams = scene.build()
            
            let fileImage = FileDisplay("/Users/afrajag/Desktop/output.png")
            
            scene.render(fileImage)
            
            if false { // (sceneParams != nil) {
                _ = NSApplication.shared
                NSApp.setActivationPolicy(.regular)

                let delegate = AppDelegate(scene)
                NSApplication.shared.delegate = delegate

                let menubar = NSMenu()
                let appMenuItem = NSMenuItem()
                menubar.addItem(appMenuItem)

                NSApp.mainMenu = menubar

                let appMenu = NSMenu()
                let appName = ProcessInfo.processInfo.processName
                
                let quitTitle = "Quit \(appName)"

                let quitMenuItem = NSMenuItem(title: quitTitle,
                                              action: #selector(NSApplication.shared.terminate(_:)),
                                              keyEquivalent: "q")
                appMenu.addItem(quitMenuItem)
                appMenuItem.submenu = appMenu

                let imageWidth = API.shared.lookupOptions("::options")!.getInt("resolutionX", 640)!
                let imageHeight = API.shared.lookupOptions("::options")!.getInt("resolutionY", 480)!
                
                let window: NSWindow = NSWindow(contentRect: NSRect(x: 0, y: 0, width: Int(imageWidth), height: Int(imageHeight)),
                                                styleMask: [.titled, .closable, .miniaturizable],
                                                backing: .buffered,
                                                defer: false)
                
                window.center()
                window.title = appName
                window.makeKeyAndOrderFront(nil)
                
                NSApp.activate(ignoringOtherApps: true)
                NSApp.run()
            }
        } else {
            let filename = "/Users/afrajag/Desktop/test.itr"
            
            SystemUtil.runSystemCheck()
            
            API.create(filename)
            
            // FIXME: controllare in altro modo se e' andato tutto bene
            /*
            guard (api != nil) else {
                fatalError("iTrace fatal error. Exiting ...")
            }
            */
            
            API.shared.parameter("sampler", "fast")
            
            API.shared.options(API.DEFAULT_OPTIONS)
            
            let fileImage = FileDisplay("/Users/afrajag/Desktop/output.png")
            
            API.shared.render(API.DEFAULT_OPTIONS, fileImage)

            UI.printInfo(.SCENE, "Shutting down ...")
        }
    }
}

// iTraceCLI.main()

#if !DEBUG
    print("Using SIMD")
#endif

iTrace().startRender()

// TODO: - mettere metodi/classi private dove necessario
// TODO: - controllare perche' il PPM salva l'immagine al contrario
// TODO: - trasformare in struct le final class non necessarie
// TODO: - togliere i getter e setter e trasformarli in computed properties
// TODO: - utilizzare simd_refract & simd_reflect
// TODO: - togliere da tutte le classi il _dest
// TODO: - sostituire array con Contiguous Array
