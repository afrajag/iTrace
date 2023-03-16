//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

import Foundation

final class HDRBitmapWriter: BitmapWriter {
    var filename: String = ""
    var data: [Int32]
    var width: Int32 = 0
    var height: Int32 = 0
    
    static let MINELEN: Int32 = 8 //  minimum scanline length for encoding
    static let MAXELEN: Int32 = 0x7fff //  maximum scanline length for encoding
    static let MINRUN: Int32 = 4 //  minimum run length
    
    required init() {
        data = [Int32]()
    }
    
    func configure(_: String, _: String) {}

    func openFile(_ filename: String) throws {
        self.filename = filename
    }

    func writeHeader(_ width: Int32, _ height: Int32, _: Int32) throws {
        self.width = width
        self.height = height
        
        data = [Int32](repeating: 0, count: Int(width * height))
    }

    func writeTile(_ x: Int32, _ y: Int32, _ w: Int32, _ h: Int32, _ color: [Color], _: [Float]) throws {
        let tileData: [Int32] = ColorEncoder.encodeRGBE(color)
        
        var index: Int = 0
        var pixel = x + y * width
        
        for _ in 0 ..< h {
            for _ in 0 ..< w {
                data[Int(pixel)] = tileData[index]
                
                index += 1
                
                pixel += 1
            }
            
            pixel += width - w
        }
    }

    func closeFile() throws {
        var dataImage: Data = Data()

        let header = "#?RGBE\nFORMAT=32-bit_rle_rgbe\n\n-Y \(height) +X \(width)\n".data(using: .ascii)!

        dataImage.append(contentsOf: header)

        for i in 0 ..< data.count {
            let rgbe: Int32 = data[i]
            
            dataImage.append(contentsOf: byteArray(from: rgbe))
        }
        
        // FIXME: controllare e riabilitare RLE
        /*
        for y in 0 ..< height {
            writeRLEScanLine(&dataImage, y * width)
        }
        */
        
        UI.printInfo(.IMG, "Saving image to \(filename)")

        UI.printInfo(.IMG, "Image size: \(dataImage)")

        try dataImage.write(to: NSURL.fileURL(withPath: filename))
    }
 
    func byteArray<T>(from value: T) -> [UInt8] where T: FixedWidthInteger {
        withUnsafeBytes(of: value.bigEndian, Array.init)
    }
    
    func writeRLEScanLine(_ f: inout Data, _ scanlineOffset: Int32) {
        var len: Int32
        var c2: Int32
        var j: Int32
        var cnt: Int32
        var beg: Int32
        let MASK: [UInt32] = [0xFF000000, 0x00FF0000, 0x0000FF00, 0x000000FF]
        
        len = width
        
        f.append(2)
        f.append(2)
        f.append(contentsOf: byteArray(from: width >> 8))
        f.append(contentsOf: byteArray(from: width & 255))
        
        cnt = 0
        
        for i in 0 ..< 4 {  // each component is encoded seperately
            j = 0
            
            while j < len { // find next run
                beg = j
                
                while beg < len {
                    cnt = 1
                    
                    while (cnt < 127) && ((beg + cnt) < len) && ((UInt32(bitPattern: data[Int(scanlineOffset + beg + cnt)]) & MASK[i]) == (UInt32(bitPattern: data[Int(scanlineOffset + beg)]) & MASK[i])) {
                        // everything done in for statement
                        cnt += 1
                    }
                
                    if cnt >= Self.MINRUN {
                        break //  the run is long enough
                    }
            
                    beg += cnt
                }
            
                if ((beg - j) > 1) && ((beg - j) < Self.MINRUN) {
                    c2 = j + 1
                    
                    while (UInt32(bitPattern: data[Int(scanlineOffset + c2)]) & MASK[i]) == (UInt32(bitPattern: data[Int(scanlineOffset + j)]) & MASK[i]) {
                        c2 += 1
                        
                        if c2 == beg { //  short run
                            f.append(contentsOf: byteArray(from: 128 + beg - j))
                            f.append(contentsOf: byteArray(from: data[Int(scanlineOffset + j)] >> ((3 - i) * 8)))
                            
                            j = beg
                            
                            break
                        }
                    }
                }
            
                while j < beg { //  write out non-run
                    c2 = beg - j
                    
                    if (c2) > 128 {
                        c2 = 128
                    }
            
                    f.append(UInt8(c2))
            
                    while c2 > 0 {
                        c2 -= 1
                        
                        f.append(contentsOf: byteArray(from: data[Int(scanlineOffset + j)] >> ((3 - i) * 8)))
                        
                        j += 1
                    }
                }
            
                if cnt >= HDRBitmapWriter.MINRUN { //  write out run
                    f.append(contentsOf: byteArray(from: 128 + cnt))
                    f.append(contentsOf: byteArray(from: data[Int(scanlineOffset + beg)] >> ((3 - i) * 8)))
                } else {
                    cnt = 0
                }
            
                j += cnt
            }
        }
    }
}
