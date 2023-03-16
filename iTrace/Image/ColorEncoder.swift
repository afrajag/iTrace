//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class ColorEncoder {
    // Undoes the premultiplication of the specified color array. The original
    // colors are not modified.
    //
    // @param color an array of premultiplied colors
    // @param alpha alpha values corresponding to the colors
    // @return an array of unpremultiplied colors
    static func unpremult(_ color: [Color], _ alpha: [Float]) -> [Color] {
        var output: [Color] = [Color](repeating: Color(), count: color.count)

        for i in 0 ..< color.count {
            output[i] = color[i].copy().mul(1.0 / alpha[i])
        }

        return output
    }

    // Moves the colors in the specified array to non-linear space. The original
    // colors are not modified.
    //
    // @param color an array of colors in linear space
    // @return a new array of the same colors in non-linear space
    static func unlinearize(_ color: [Color]) -> [Color] {
        var output: [Color] = [Color](repeating: Color(), count: color.count)

        for i in 0 ..< color.count {
            output[i] = color[i].copy().toNonLinear()
        }

        return output
    }

    // Quantize the specified colors to 8-bit RGB format. The returned array
    // contains 3 bytes for each color in the original array.
    //
    // @param color array of colors to quantize
    // @return array of quantized RGB values
    static func quantizeRGB8(_ color: [Color]) -> [UInt8] {
        var output: [UInt8] = [UInt8](repeating: 0, count: color.count * 3)

        var index = 0
        for i in 0 ..< color.count {
            let rgb: [Float] = color[i].getRGB()

            // FIXME: NaN not supported by Integer, quick fix
            output[index + 0] = UInt8(Int32((rgb[0].isNaN ? 0 : rgb[0]) * 255.0 + 0.5).clamp(0, 255))
            output[index + 1] = UInt8(Int32((rgb[1].isNaN ? 0 : rgb[1]) * 255.0 + 0.5).clamp(0, 255))
            output[index + 2] = UInt8(Int32((rgb[2].isNaN ? 0 : rgb[2]) * 255.0 + 0.5).clamp(0, 255))

            index += 3
        }

        return output
    }

    // Quantize the specified colors to 8-bit RGBA format. The returned array
    // contains 4 bytes for each color in the original array.
    //
    // @param color array of colors to quantize
    // @param alpha array of alpha values (same length as color)
    // @return array of quantized RGBA values
    static func quantizeRGBA8(_ color: [Color], _ alpha: [Float]) -> [UInt8] {
        var output: [UInt8] = [UInt8](repeating: 0, count: color.count * 4)

        var index = 0
        for i in 0 ..< color.count {
            let rgb: [Float] = color[i].getRGB()
            
            // FIXME: NaN not supported by Integer, quick fix
            output[index + 0] = UInt8(Int32((rgb[0].isNaN ? 0 : rgb[0]) * 255.0 + 0.5).clamp(0, 255))
            output[index + 1] = UInt8(Int32((rgb[1].isNaN ? 0 : rgb[1]) * 255.0 + 0.5).clamp(0, 255))
            output[index + 2] = UInt8(Int32((rgb[2].isNaN ? 0 : rgb[2]) * 255.0 + 0.5).clamp(0, 255))
            output[index + 3] = UInt8(Int32(alpha[i] * 255.0 + 0.5).clamp(0, 255))

            index += 4
        }

        return output
    }

    // Encode the specified colors using Ward's RGBE technique. The returned
    // array contains one int for each color in the original array.
    //
    // @param color array of colors to encode
    // @return array of encoded colors
    static func encodeRGBE(_ color: [Color]) -> [Int32] {
        var output: [Int32] = [Int32](repeating: 0, count: color.count)

        for i in 0 ..< color.count {
            output[i] = color[i].toRGBE()
        }

        return output
    }
}
