//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

import Foundation

final class TGABitmapReader: BitmapReader {
    static var CHANNEL_INDEX: [Int32] = [2, 1, 0, 3]
    
    required init() {}
    
    func load(_ filename: String, _ isLinear: Bool) throws -> Bitmap? {
        let fileURL = URL(fileURLWithPath: filename)
        var f: Data = try Data(contentsOf: fileURL)
        
        var read: Data = Data()
        
        //  read header
        let idsize: UInt8 = f.readByte()!
        let cmaptype: UInt8 = f.readByte()! //  cmap byte (unsupported)
        
        if cmaptype != 0 {
            throw BitmapFormatException.message("Colormapping (type: \(cmaptype)) is unsupported")
        }
        
        let datatype: UInt8 = f.readByte()!
        
        //  colormap info (5 bytes ignored)
        f.removeFirst(5)
        
        //  xstart, 16 bits (ignored)
        f.removeFirst(2)
        
        //  ystart, 16 bits (ignored)
        f.removeFirst(2)
        
        //  read resolution
        var width: Int32 = Int32(f.readByte()!)

        width |= Int32(f.readByte()!) << 8
        
        var height: Int32 = Int32(f.readByte()!)
        
        height |= Int32(f.readByte()!) << 8
        
        let bits: UInt8 = f.readByte()!
        let bpp: UInt8 = bits / 8
        let imgdscr: UInt8 = f.readByte()!
        
        //  skip image ID if present
        if idsize != 0 {
            f = f.readBytes(count: Int(idsize))!
        }
        
        //  allocate byte buffer to hold the image
        var pixels: [UInt8] = [UInt8](repeating: 0, count: Int(width * height * Int32(bpp)))
        
        if (datatype == 2) || (datatype == 3) {
            if bpp != 1 && bpp != 3 && bpp != 4 {
                throw BitmapFormatException.message("Invalid bit depth in uncompressed TGA: \(bits)")
            }
            
            // uncompressed image
            var ptr: Int32 = 0
            
            while ptr < pixels.count {
                //  read bytes
                read = f.readBytes(count: Int(bpp))!
                
                for i in 0 ..< bpp {
                    pixels[Int(ptr + Self.CHANNEL_INDEX[Int(i)])] = read[read.startIndex + Int(i)]
                }
                
                ptr += Int32(bpp)
            }
        } else if datatype == 10 {
            if bpp != 3 && bpp != 4 {
                throw BitmapFormatException.message("Invalid bit depth in run-length encoded TGA: \(bits)")
            }
            
            // RLE encoded image
            var ptr: Int32 = 0
            
            while ptr < pixels.count {
                let rle: UInt8 = f.popFirst()!
                let num: UInt8 = 1 + (rle & 127)
                
                if (rle & 0x80) != 0 {
                    //  rle packet - decode length and copy pixel
                    read = f.readBytes(count: Int(bpp))!
                    
                    for _ in 0 ..< num {
                        for i in 0 ..< bpp {
                            pixels[Int(ptr + Self.CHANNEL_INDEX[Int(i)])] = read[read.startIndex + Int(i)]
                        }
                        
                        ptr += Int32(bpp)
                    }
                } else {
                    //  raw packet - decode length and read pixels
                    for _ in 0 ..< num {
                        read = f.readBytes(count: Int(bpp))!
                        
                        for i in 0 ..< bpp {
                            pixels[Int(ptr + Self.CHANNEL_INDEX[Int(i)])] = read[read.startIndex + Int(i)]
                        }
                        
                        ptr += Int32(bpp)
                    }
                }
            }
        } else {
            throw BitmapFormatException.message("Unsupported TGA image type: \(datatype)")
        }
        
        if !isLinear {
            // apply reverse correction
            var ptr: Int32 = 0
            
            while ptr < pixels.count {
                for i in 0 ..< bpp {
                    pixels[Int(ptr) + Int(i)] = Color.NATIVE_SPACE.rgbToLinear(pixels[Int(ptr) + Int(i)])
                }
                
                ptr += Int32(bpp)
            }
        }
        
        //  should image be flipped in Y ?
        if (imgdscr & 32) == 32 {
            var pix_ptr: Int32 = 0
            
            for y in 0 ..< height / 2 {
                var bot_ptr: Int32 = Int32(bpp) * (height - y - 1) * width
                
                for _ in 0 ..< width {
                    for i in 0 ..< bpp {
                        let t: UInt8 = pixels[Int(pix_ptr) + Int(i)]
                        
                        pixels[Int(pix_ptr) + Int(i)] = pixels[Int(bot_ptr) + Int(i)]
                        
                        pixels[Int(bot_ptr) + Int(i)] = t
                    }
                    
                    pix_ptr += Int32(bpp)
                    
                    bot_ptr += Int32(bpp)
                }
            }
        }
        
        switch bpp {
            case 1:
                return BitmapG8(Int32(width), Int32(height), pixels)
            case 3:
                return BitmapRGB8(Int32(width), Int32(height), pixels)
            case 4:
                return BitmapRGBA8(Int32(width), Int32(height), pixels)
            default: break
        }
        
        throw BitmapFormatException.message("Inconsistent code in TGA reader")
    }
}
