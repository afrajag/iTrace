//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class BitmapRGBE: Bitmap {
    static var EXPONENT: [Float] = {
        var EXPONENT: [Float] = [Float](repeating: 0, count: 256)

        EXPONENT[0] = 0

        for i in 1 ..< 256 {
            var f: Float = 1.0
            let e: Int32 = Int32(i) - (128 + 8)

            if e > 0 {
                for _ in 0 ..< e {
                    f *= 2.0
                }
            } else {
                for _ in 0 ..< -e {
                    f *= 0.5
                }
            }

            EXPONENT[i] = f
        }

        return EXPONENT
    }()
    
    var w: Int32 = 0
    var h: Int32 = 0
    var data: [Int32]
    
    required init() {
        data = [Int32]()
    }

    init(_ w: Int32, _ h: Int32, _ data: [Int32]) {
        self.w = w
        self.h = h
        self.data = data
    }

    func getWidth() -> Int32 {
        return w
    }

    func getHeight() -> Int32 {
        return h
    }

    func readColor(_ x: Int32, _ y: Int32) -> Color {
        let rgbe: Int32 = data[Int(x + y * w)]
        let f: Float = Self.EXPONENT[Int(rgbe) & 0xFF]
        let r: Float = f * (Float(rgbe >>> 24) + 0.5)
        let g: Float = f * (Float((rgbe >> 16) & 0xFF) + 0.5)
        let b: Float = f * (Float((rgbe >> 8) & 0xFF) + 0.5)

        return Color(r, g, b)
    }

    func readAlpha(_: Int32, _: Int32) -> Float {
        return 1
    }
}
