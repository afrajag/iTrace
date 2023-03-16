//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

import Foundation

final class TGABitmapWriter: BitmapWriter {
    var filename: String = ""
    var data: [UInt8]
    var width: Int32 = 0
    var height: Int32 = 0

    let lockQueue = DispatchQueue(label: "tgawriter.lock.serial.queue")

    required init() {
        data = [UInt8]()
    }

    func configure(_: String, _: String) {}

    func openFile(_ filename: String) throws {
        self.filename = filename
    }

    func writeHeader(_ width: Int32, _ height: Int32, _: Int32) throws {
        self.width = width
        self.height = height

        data = [UInt8](repeating: 0, count: Int(width * height) * 4) //  RGBA8
    }

    func writeTile(_ x: Int32, _ y: Int32, _ w: Int32, _ h: Int32, _ color: [Color], _ alpha: [Float]) throws {
        lockQueue.sync { // synchronized block
            let _color = ColorEncoder.unlinearize(color) //  gamma correction

            let tileData: [UInt8] = ColorEncoder.quantizeRGBA8(_color, alpha)

            var index = 0

            for j in 0 ..< h {
                var imageIndex: Int32 = 4 * (x + ((height - 1 - (y + j)) * width))

                for _ in 0 ..< w {
                    //  swap bytes around so buffer is in native BGRA order
                    data[Int(imageIndex) + 0] = tileData[index + 2]
                    data[Int(imageIndex) + 1] = tileData[index + 1]
                    data[Int(imageIndex) + 2] = tileData[index + 0]
                    data[Int(imageIndex) + 3] = tileData[index + 3]

                    index += 4
                    imageIndex += 4
                }
            }
        }
    }

    func closeFile() throws {
        var dataImage: Data = Data()

        //  no id, no colormap, uncompressed 3bpp RGB
        let tgaHeader: [UInt8] = [0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0]

        dataImage.append(contentsOf: tgaHeader)

        //  then the size info
        dataImage.append(UInt8(width & 0xFF))
        dataImage.append(UInt8((width >> 8) & 0xFF))
        dataImage.append(UInt8(height & 0xFF))
        dataImage.append(UInt8((height >> 8) & 0xFF))

        //  bits per pixel and filler
        dataImage.append(UInt8(32))
        dataImage.append(UInt8(0))

        //  image data
        for imageIndex in stride(from: 0, to: data.count, by: 4) {
            dataImage.append(data[Int(imageIndex) + 0])
            dataImage.append(data[Int(imageIndex) + 1])
            dataImage.append(data[Int(imageIndex) + 2])
            dataImage.append(data[Int(imageIndex) + 3])
        }

        UI.printInfo(.IMG, "Saving image to \(filename)")

        UI.printInfo(.IMG, "Image size: \(dataImage)")

        try dataImage.write(to: NSURL.fileURL(withPath: filename))
    }
}
