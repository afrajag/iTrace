//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class BitmapRGB8: Bitmap {
    var data: [UInt8]
    var w: Int32 = 0
    var h: Int32 = 0

    init(_ w: Int32, _ h: Int32, _ data: [UInt8]) {
        self.w = w
        self.h = h
        self.data = data
    }

    required init() {
        data = [UInt8]()
    }

    func getWidth() -> Int32 {
        return w
    }

    func getHeight() -> Int32 {
        return h
    }

    func readColor(_ x: Int32, _ y: Int32) -> Color {
        let index: Int32 = 3 * (x + y * w)
        let r: Float = Float(data[Int(index) + 0] & 0xFF) * INV255
        let g: Float = Float(data[Int(index) + 1] & 0xFF) * INV255
        let b: Float = Float(data[Int(index) + 2] & 0xFF) * INV255

        return Color(r, g, b)
    }

    func readAlpha(_: Int32, _: Int32) -> Float {
        return 1
    }
}
