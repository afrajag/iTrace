//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class BitmapG8: Bitmap {
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
        return Color(Float(data[Int(x + y * w)] & 0xFF) * INV255)
    }

    func readAlpha(_: Int32, _: Int32) -> Float {
        return 1
    }
}
