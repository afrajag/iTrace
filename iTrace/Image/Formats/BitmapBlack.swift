//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class BitmapBlack: Bitmap {
    required init() {}

    func getWidth() -> Int32 {
        return 1
    }

    func getHeight() -> Int32 {
        return 1
    }

    func readColor(_: Int32, _: Int32) -> Color {
        return Color.BLACK
    }

    func readAlpha(_: Int32, _: Int32) -> Float {
        return 0
    }
}
