//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class GenericBitmap: Bitmap {
    var color: [Color]
    var alpha: [Float]
    var w: Int32 = 0
    var h: Int32 = 0

    init(_ w: Int32, _ h: Int32) {
        self.w = w
        self.h = h

        color = [Color](repeating: Color(), count: Int(w * h))
        alpha = [Float](repeating: 0, count: Int(w * h))
    }

    required init() {
        color = [Color]()
        alpha = [Float]()
    }

    func getWidth() -> Int32 {
        return w
    }

    func getHeight() -> Int32 {
        return h
    }

    func readColor(_ x: Int32, _ y: Int32) -> Color {
        return color[Int(x + y * w)]
    }

    func readAlpha(_ x: Int32, _ y: Int32) -> Float {
        return alpha[Int(x + y * w)]
    }

    func writePixel(_ x: Int32, _ y: Int32, _ c: Color, _ a: Float) {
        color[Int(x + y * w)] = c
        alpha[Int(x + y * w)] = a
    }

    func save(_ filename: String) {
        let file_extension: String = FileUtils.getExtension(filename)!

        let writer: BitmapWriter? = PluginRegistry.bitmapWriterPlugins.createInstance(file_extension)

        if writer == nil {
            UI.printError(.IMG, "Unable to save file \"\(filename)\" - unknown file format: \(file_extension)")

            return
        }

        do {
            try writer!.openFile(filename)
            try writer!.writeHeader(w, h, max(w, h))
            try writer!.writeTile(0, 0, w, h, color, alpha)
            try writer!.closeFile()
        } catch {
            UI.printError(.IMG, "Unable to save file \"\(filename)\" - \(error)")
        }
    }
}
