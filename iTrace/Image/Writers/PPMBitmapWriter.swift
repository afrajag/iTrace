//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//
import Foundation

final class PPMBitmapWriter: BitmapWriter {
    var filename: String = ""
    var data: [UInt8]
    var width: Int32 = 0
    var height: Int32 = 0

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

        data = [UInt8](repeating: 0, count: Int(width * height) * 3) //  RGB8
    }

    func writeTile(_ x: Int32, _ y: Int32, _ w: Int32, _ h: Int32, _ color: [Color], _: [Float]) throws {
        let _color = ColorEncoder.unlinearize(color) // gamma correction

        let tileData: [UInt8] = ColorEncoder.quantizeRGB8(_color)

        var index = 0

        for j in 0 ..< h {
            var imageIndex: Int32 = 3 * (x + ((height - 1 - (y + j)) * width))

            for _ in 0 ..< w {
                data[Int(imageIndex) + 0] = tileData[index + 0]
                data[Int(imageIndex) + 1] = tileData[index + 1]
                data[Int(imageIndex) + 2] = tileData[index + 2]

                index += 3
                imageIndex += 3
            }
        }
    }

    func closeFile() throws {
        var dataImage: Data = Data()

        let header = "P3\n\(width) \(height)\n255\n".data(using: .ascii)!

        dataImage.append(contentsOf: header)

        //  image data
        var imageIndex: Int32 = (width * height * 3) - 3

        for _ in 0 ..< height {
            for _ in 0 ..< width {
                // print("\(imageIndex)")

                let ir = data[Int(imageIndex) + 0]
                let ig = data[Int(imageIndex) + 1]
                let ib = data[Int(imageIndex) + 2]

                dataImage.append("\(ir) \(ig) \(ib)\n".data(using: .ascii)!)

                imageIndex -= 3
            }
        }

        UI.printInfo(.IMG, "Saving image to \(filename)")

        UI.printInfo(.IMG, "Image size: \(dataImage)")

        try dataImage.write(to: NSURL.fileURL(withPath: filename))
    }
}
