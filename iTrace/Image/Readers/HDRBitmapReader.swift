//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

import Foundation

final class HDRBitmapReader: BitmapReader {
    required init() {}
    
    func load(_ filename: String, _ isLinear: Bool) throws -> Bitmap? {
        //  load radiance rgbe file
        let fileURL = URL(fileURLWithPath: filename)
        var f: Data = try Data(contentsOf: fileURL)
        
        // parse header
        var parseWidth: Bool = false
        var parseHeight: Bool = false
        var width: Int32 = 0
        var height: Int32 = 0
        var last: String = ""
        
        while (width == 0) || (height == 0) || (last != "\n") {
            let n: String = String(Character(UnicodeScalar(f.readByte()!)))
            
            switch n {
                case "Y":
                    parseHeight = last == "-"
                    
                    parseWidth = false
                case "X":
                    parseHeight = false
                    
                    parseWidth = last == "+"
                case " ":
                    parseWidth = parseWidth && width == 0
                    
                    parseHeight = parseHeight && height == 0
                case "0",
                     "1",
                     "2",
                     "3",
                     "4",
                     "5",
                     "6",
                     "7",
                     "8",
                     "9":
                    if parseHeight {
                        height = (10 * height) + Int32(n)! // (n - "0")
                    } else if parseWidth {
                        width = (10 * width) + Int32(n)! // (n - "0")
                    }
                default:
                    parseWidth = false
                    parseHeight = false
            }
            
            last = n
        }
        
        //  allocate image
        var pixels: [Int32] = [Int32](repeating: 0, count: Int(width * height))
        
        if (width < 8) || (width > 0x7fff) {
            //  run length encoding is not allowed so read flat
            readFlatRGBE(&f, 0, width * height, &pixels)
        } else {
            var rasterPos: Int32 = 0
            var numScanlines: Int32 = height
            var scanlineBuffer: [Int32] = [Int32](repeating: 0, count: 4 * Int(width))
            
            while numScanlines > 0 {
                var r: Int32 = Int32(f.readByte()!)
                var g: Int32 = Int32(f.readByte()!)
                var b: Int32 = Int32(f.readByte()!)
                var e: Int32 = Int32(f.readByte()!)
                
                if (r != 2) || (g != 2) || ((b & 0x80) != 0) {
                    //  this file is not run length encoded
                    pixels[Int(rasterPos)] = (r << 24) | (g << 16) | (b << 8) | e
                    
                    readFlatRGBE(&f, rasterPos + 1, (width * numScanlines) - 1, &pixels)
                    
                    return nil
                }
                
                if ((b << 8) | e) != width {
                    throw BitmapFormatException.message("Invalid scanline width")
                }
                
                var p: Int32 = 0
                
                //  read each of the four channels for the scanline into
                //  the buffer
                for i in 0 ..< 4 {
                    if (p % width) != 0 {
                        throw BitmapFormatException.message("Unaligned access to scanline data")
                    }
                    
                    let end: Int32 = Int32((i + 1)) * width
                    
                    while p < end {
                        let b0: Int32 = Int32(f.readByte()!)
                        let b1: Int32 = Int32(f.readByte()!)
                        
                        if b0 > 128 {
                            //  a run of the same value
                            var count: Int32 = b0 - 128
                            
                            if (count == 0) || (count > (end - p)) {
                                throw BitmapFormatException.message("Bad scanline data - invalid RLE run")
                            }

                            while count > 0 {
                                count -= 1
                                
                                scanlineBuffer[Int(p)] = b1
                                
                                p += 1
                            }
                        } else {
                            //  a non-run
                            var count: Int32 = b0
                            
                            if (count == 0) || (count > (end - p)) {
                                throw BitmapFormatException.message("Bad scanline data - invalid count")
                            }
                            
                            scanlineBuffer[Int(p)] = b1
                            
                            p += 1
                            
                            count -= 1
                            
                            if count > 0 {
                                for x in 0 ..< count {
                                    scanlineBuffer[Int(p + x)] = Int32(f.readByte()!)
                                }

                                p += count
                            }
                        }
                    }
                }
                
                //  now convert data from buffer into floats
                for i in 0 ..< width {
                    r = scanlineBuffer[Int(i)]
                    g = scanlineBuffer[Int(i + width)]
                    b = scanlineBuffer[Int(i + (2 * width))]
                    e = scanlineBuffer[Int(i + (3 * width))]
                    
                    pixels[Int(rasterPos)] = (r << 24) | (g << 16) | (b << 8) | e
                    
                    rasterPos += 1
                }
                
                numScanlines -= 1
            }
        }
        
        var i: Int = 0
        var ir: Int = (Int(height) - 1) * Int(width)
        
        //  flip image
        for _ in 0 ..< height / 2 {
            var i2: Int = ir
            
            for _ in 0 ..< width {
                let t: Int32 = pixels[i]
                
                pixels[i] = pixels[i2]
                
                pixels[i2] = t
                
                i += 1
                
                i2 += 1
            }
            
            ir -= Int(width)
        }
        
        return BitmapRGBE(width, height, pixels)
    }

    func readFlatRGBE(_ f: inout Data, _ _rasterPos: Int32, _ _numPixels: Int32, _ pixels: inout [Int32]) {
        var numPixels = _numPixels
        var rasterPos = _rasterPos

        while numPixels > 0 {
            numPixels -= 1
            
            let r: Int32 = Int32(f.readByte()!)
            let g: Int32 = Int32(f.readByte()!)
            let b: Int32 = Int32(f.readByte()!)
            let e: Int32 = Int32(f.readByte()!)
            
            pixels[Int(rasterPos)] = (r << 24) | (g << 16) | (b << 8) | e
            
            rasterPos += 1
        }
    }
}
