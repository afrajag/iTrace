//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class FileDisplay: Display {
    var writer: BitmapWriter?
    var filename: String = ""

    required init() {}

    convenience init(_ saveImage: Bool) {
        self.init(saveImage ? "output.png" : ".none")
    }

    init(_ filename: String?) {
        self.filename = ((filename == nil ? "output.png" : filename)!)

        let file_extension: String = FileUtils.getExtension(filename)!

        writer = PluginRegistry.bitmapWriterPlugins.createInstance(file_extension)
    }

    func imageBegin(_ w: Int32, _ h: Int32, _ bucketSize: Int32) {
        if writer == nil {
            return
        }

        try! writer!.openFile(filename)
        try! writer!.writeHeader(w, h, bucketSize)

        // FIXME: riabilitare exceptions
        // UI.printError(.IMG, "I/O error occured while preparing image for display: \(xxx)", e.Message)
    }

    func imagePrepare(_: Int32, _: Int32, _: Int32, _: Int32, _: Int32) {
        //  does nothing for files
        //
    }

    func imageUpdate(_ x: Int32, _ y: Int32, _ w: Int32, _ h: Int32, _ data: [Color], _ alpha: [Float]) {
        if writer == nil {
            return
        }

        try! writer!.writeTile(x, y, w, h, data, alpha)

        // FIXME: riabilitare exceptions
        // UI.printError(.IMG, "I/O error occured while writing image tile [(\(xxx),\(xxx)) \(xxx)\(xxx)] image for display: \(xxx)", x, y, w, h, e.Message)
    }

    func imageFill(_ x: Int32, _ y: Int32, _ w: Int32, _ h: Int32, _ c: Color, _ alpha: Float) {
        if writer == nil {
            return
        }

        var colorTile: [Color] = [Color](repeating: Color(), count: Int(w * h))
        var alphaTile: [Float] = [Float](repeating: 0, count: Int(w * h))

        for i in 0 ..< colorTile.count {
            colorTile[i] = c

            alphaTile[i] = alpha
        }

        imageUpdate(x, y, w, h, colorTile, alphaTile)
    }

    func imageEnd() {
        if writer == nil {
            return
        }

        try! writer!.closeFile()

        // FIXME: riabilitare exceptions
        // UI.printError(.IMG, "I/O error occured while closing the display: \(xxx)", e.Message)
    }
}
