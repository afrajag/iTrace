//
//  PNGBitmapReader.swift
//  iTrace
//
//  Created by Fabrizio Pezzola on 09/03/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class PNGBitmapReader: BitmapReader {
    required init() {}

    func load(_ filename: String, _ isLinear: Bool) throws -> Bitmap? {
        let imgHelper = ImageHelper(filename)
        try imgHelper.loadImage()
        
        var pixels: [UInt8] = [UInt8](repeating: 0, count: 4 * imgHelper.width * imgHelper.height)
        
        var index: Int32 = 0
        
        for y in 0 ..< imgHelper.height {
            for x in 0 ..< imgHelper.width {
                let argb: [UInt8] = imgHelper.getPixel(x, imgHelper.height - 1 - y)
            
                pixels[Int(index) + 0] = argb[0]
                pixels[Int(index) + 1] = argb[1]
                pixels[Int(index) + 2] = argb[2]
                pixels[Int(index) + 3] = argb[3]
                
                index += 4
            }
        }
        
        imgHelper.unloadImage()
        
        if !isLinear {
            for index in stride(from: 0, to: pixels.count, by: 4) {
                pixels[Int(index) + 0] = Color.NATIVE_SPACE.rgbToLinear(pixels[Int(index) + 0])
                pixels[Int(index) + 1] = Color.NATIVE_SPACE.rgbToLinear(pixels[Int(index) + 1])
                pixels[Int(index) + 2] = Color.NATIVE_SPACE.rgbToLinear(pixels[Int(index) + 2])
            }
        }

        return BitmapRGBA8(Int32(imgHelper.width), Int32(imgHelper.height), pixels)
    }
}
