//
//  PNGBitmapWriter.swift
//  iTrace
//
//  Created by Fabrizio Pezzola on 14/03/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

import Foundation
import ImageIO

final class PNGBitmapWriter: BitmapWriter {
    var filename: String = ""
    var data: [UInt8]
    var width: Int32 = 0
    var height: Int32 = 0

    let lockQueue = DispatchQueue(label: "pngwriter.lock.serial.queue")

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
            let _color0 = ColorEncoder.unpremult(color, alpha) // gamma correction
            let _color = ColorEncoder.unlinearize(_color0)
            
            let tileData: [UInt8] = ColorEncoder.quantizeRGBA8(_color, alpha)

            var index = 0

            for j in 0 ..< h {
                var imageIndex: Int32 = 4 * ((y + j) * width + x)

                for _ in 0 ..< w {
                    data[Int(imageIndex) + 0] = tileData[index + 0]
                    data[Int(imageIndex) + 1] = tileData[index + 1]
                    data[Int(imageIndex) + 2] = tileData[index + 2]
                    data[Int(imageIndex) + 3] = tileData[index + 3]

                    index += 4
                    imageIndex += 4
                }
            }
        }
    }

    func closeFile() throws {
        let ctx = data.withUnsafeMutableBufferPointer { ptr in ptr.baseAddress }

        let cgImage = byteArrayToCGImage(raw: ctx!, w: Int(width), h: Int(height))

        UI.printInfo(.IMG, "Saving image to \(filename)")

        //UI.printInfo(.IMG, "Image size: \(cgImage)")

        try cgImage?.png!.write(to: NSURL.fileURL(withPath: filename))
    }

    func byteArrayToCGImage(raw: UnsafeMutablePointer<UInt8>, w: Int, h: Int) -> CGImage! {
        // 4 bytes(rgba channels) for each pixel
        let bytesPerPixel: Int = 4

        // (8 bits per each channel)
        let bitsPerComponent: Int = 8

        let bitsPerPixel = bytesPerPixel * bitsPerComponent

        // channels in each row (width)
        let bytesPerRow: Int = w * bytesPerPixel

        let cfData = CFDataCreate(nil, raw, w * h * bytesPerPixel)

        let cgDataProvider = CGDataProvider(data: cfData!)!

        let deviceColorSpace = CGColorSpaceCreateDeviceRGB()

        let image: CGImage! = CGImage(width: w,
                                      height: h,
                                      bitsPerComponent: bitsPerComponent,
                                      bitsPerPixel: bitsPerPixel,
                                      bytesPerRow: bytesPerRow,
                                      space: deviceColorSpace,
                                      bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
                                      provider: cgDataProvider,
                                      decode: nil,
                                      shouldInterpolate: true,
                                      intent: CGColorRenderingIntent.defaultIntent)

        return image
    }
}

extension CGImage {
    var png: Data? {
        guard let mutableData = CFDataCreateMutable(nil, 0),
            let destination = CGImageDestinationCreateWithData(mutableData, "public.png" as CFString, 1, nil) else { return nil }

        CGImageDestinationAddImage(destination, self, nil)

        guard CGImageDestinationFinalize(destination) else { return nil }

        return mutableData as Data
    }
}
