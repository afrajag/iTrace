//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class BitmapGA8: Bitmap {
    var data: [UInt8]
    var w: Int32 = 0
    var h: Int32 = 0

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
        return Color(Float(data[(2 * Int(x + y * w)) + 0] & 0xFF) * INV255)
    }

    func readAlpha(_ x: Int32, _ y: Int32) -> Float {
        return Float(data[(2 * Int(x + y * w)) + 1] & 0xFF) * INV255
    }
}
