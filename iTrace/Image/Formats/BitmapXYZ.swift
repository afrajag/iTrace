//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class BitmapXYZ: Bitmap {
    var data: [Float]
    var w: Int32 = 0
    var h: Int32 = 0

    init(_ w: Int32, _ h: Int32, _ data: [Float]) {
        self.w = w
        self.h = h
        self.data = data
    }

    required init() {
        data = [Float]()
    }

    func getWidth() -> Int32 {
        return w
    }

    func getHeight() -> Int32 {
        return h
    }

    func readColor(_ x: Int32, _ y: Int32) -> Color {
        let index: Int32 = 3 * (x + y * w)

        return Color.NATIVE_SPACE.convertXYZtoRGB(XYZColor(data[Int(index)], data[Int(index) + 1], data[Int(index) + 2])).mul(0.1)
    }

    func readAlpha(_: Int32, _: Int32) -> Float {
        return 1
    }
}
