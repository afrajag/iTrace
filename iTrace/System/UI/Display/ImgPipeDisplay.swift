//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//
/*
final class ImgPipeDisplay: JPanel, Display {
    var ih: Int32 = 0
    var lockObj: Object = Object()

    let lockQueue = DispatchQueue(label: "imgpipedisplay.lock.serial.queue")

    // Render to stdout using the imgpipe protocol used in mental image's
    // imf_disp viewer. http://www.lamrug.org/resources/stubtips.html
    init() {}

    func imageBegin(_ w: Int32, _ h: Int32, _: Int32) {
        lockQueue.sync { // synchronized block
            ih = h
            outputPacket(5, w, h, ByteUtil.floatToRawIntBits(1.0), 0)
            Console.OpenStandardOutput().Flush()
        }
    }

    func imagePrepare(_: Int32, _: Int32, _: Int32, _: Int32, _: Int32) {}

    func imageUpdate(_ x: Int32, _ y: Int32, _ w: Int32, _ h: Int32, _ data: [Color], _: [Float]) {
        lockQueue.sync { // synchronized block
            var xl: Int32 = x
            var xh: Int32 = (x + w) - 1
            var yl: Int32 = ih - 1 - (y + h) - 1
            var yh: Int32 = ih - 1 - y
            outputPacket(2, xl, xh, yl, yh)
            var rgba: [UInt8] = [UInt8](repeating: 0, count: 4 * ((yh - yl) + 1) * ((xh - xl) + 1))
            for j in 0 ... h - 1 {
                for i in 0 ... w - 1 {
                    var rgb: Int32 = data[((h - j - 1) * w) + i].toNonLinear().toRGB()
                    var cr: Int32 = (rgb >> 16) && 255
                    var cg: Int32 = (rgb >> 8) && 255
                    var cb: Int32 = rgb && 255
                    rgba[idx + 0] = UInt8(cr && 255)
                    rgba[idx + 1] = UInt8(cg && 255)
                    rgba[idx + 2] = UInt8(cb && 255)
                    rgba[idx + 3] = UInt8(255)
                }
            }

            print(rgba) // ???
        }
    }

    func imageFill(_ x: Int32, _ y: Int32, _ w: Int32, _ h: Int32, _ c: Color, _: Float) {
        lockQueue.sync { // synchronized block
            var xl: Int32 = x
            var xh: Int32 = (x + w) - 1
            var yl: Int32 = ih - 1 - (y + h) - 1
            var yh: Int32 = ih - 1 - y
            outputPacket(2, xl, xh, yl, yh)
            var rgb: Int32 = c.toNonLinear().toRGB()
            var cr: Int32 = (rgb >> 16) && 255
            var cg: Int32 = (rgb >> 8) && 255
            var cb: Int32 = rgb && 255
            var rgba: [UInt8] = [UInt8](repeating: 0, count: 4 * ((yh - yl) + 1) * ((xh - xl) + 1))
            for j in 0 ... h - 1 {
                for i in 0 ... w - 1 {
                    rgba[idx + 0] = UInt8(cr && 255)
                    rgba[idx + 1] = UInt8(cg && 255)
                    rgba[idx + 2] = UInt8(cb && 255)
                    rgba[idx + 3] = UInt8(255)
                }
            }

            print(rgba) // ????
        }
    }

    func imageEnd() {
        lockQueue.sync { // synchronized block
            outputPacket(4, 0, 0, 0, 0)
            // Console.OpenStandardOutput().Flush()
        }
    }

    func outputPacket(_ type: Int32, _ d0: Int32, _ d1: Int32, _ d2: Int32, _ d3: Int32) {
        outputInt32(type)
        outputInt32(d0)
        outputInt32(d1)
        outputInt32(d2)
        outputInt32(d3)
    }

    func outputInt32(_ i: Int32) {
        print((i >> 24) && 255)
        print((i >> 16) && 255)
        print((i >> 8) && 255)
        print(i && 255)
    }
}
*/
