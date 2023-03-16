//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

import Foundation

protocol Bitmap: Initializable {
    func getWidth() -> Int32

    func getHeight() -> Int32

    func readColor(_ x: Int32, _ y: Int32) -> Color

    func readAlpha(_ x: Int32, _ y: Int32) -> Float
}

extension Bitmap {
    var INV255: Float { return 1.0 / 255 }
    var INV65535: Float { return 1.0 / 65535 }
}

extension Data {
    mutating func readByte() -> UInt8? {
        guard let first = self.first else { return nil }
        self.removeFirst()
        return first
    }

    mutating func readBytes(count: Int) -> Data? {
        guard self.count >= count else { return nil }
        defer { self.removeFirst(count) }
        return self.prefix(count)
    }
}
