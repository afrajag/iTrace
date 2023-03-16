//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

import Foundation
import DataCompression

final class EXRBitmapWriter: BitmapWriter {
    static let HALF: UInt8 = 1
    static let FLOAT: UInt8 = 2
    static let ZERO: UInt8 = 0
    static let HALF_SIZE: Int32 = 2
    static let FLOAT_SIZE: Int32 = 4
    static let OE_MAGIC: Int32 = 20000630
    static let OE_EXR_VERSION: Int32 = 2
    static let OE_TILED_FLAG: Int32 = 512
    static let NO_COMPRESSION: UInt8 = 0
    static let RLE_COMPRESSION: UInt8 = 1
    static let ZIP_COMPRESSION: UInt8 = 3
    static let RLE_MIN_RUN: Int32 = 3
    static let RLE_MAX_RUN: Int32 = 127
    
    var filename: String?
    var file: Data?
    var tileOffsets: [[Int64]]?
    var tileOffsetsPosition: Int64 = 0
    var tilesX: Int32 = 0
    var tilesY: Int32 = 0
    var tileSize: Int32 = 0
    var compression: UInt8 = 0
    var channelType: UInt8 = 0
    var channelSize: Int32 = 0
    var tmpbuf: [UInt8]?
    var comprbuf: [UInt8]?
    
    let lockQueue = DispatchQueue(label: "exrbitmapwriter.lock.serial.queue")
    
    required init() {
        //  default settings
        //  configure("compression", "none")
        //  configure("compression", "rle");
        configure("compression", "zip")
        
        configure("channeltype", "half")
        //  configure("channeltype", "float");
    }
    
    func configure(_ option: String, _ value: String) {
        if option == "compression" {
            if value == "none" {
                compression = Self.NO_COMPRESSION
            } else if value == "rle" {
                compression = Self.RLE_COMPRESSION
            } else if value == "zip" {
                compression = Self.ZIP_COMPRESSION
            } else {
                UI.printWarning(.IMG, "EXR - Compression type was not recognized - defaulting to zip")
                
                compression = Self.ZIP_COMPRESSION
            }
        } else if option == "channeltype" {
            if value == "float" {
                channelType = Self.FLOAT
                channelSize = Self.FLOAT_SIZE
            } else if value == "half" {
                channelType = Self.HALF
                channelSize = Self.HALF_SIZE
            } else {
                UI.printWarning(.DISP, "EXR - Channel type was not recognized - defaulting to float")
                channelType = Self.FLOAT
                channelSize = Self.FLOAT_SIZE
            }
        }
    }
    
    func openFile(_ filename: String) throws {
        self.filename = filename
    }
    
    func writeHeader(_ width: Int32, _ height: Int32, _ tileSize: Int32) throws {
        file = Data()
        
        if tileSize <= 0 {
            fatalError("Can\'t use OpenEXR bitmap writer without buckets.")
        }
        
        writeRGBAHeader(width, height, tileSize)
    }
    
    func writeTile(_ x: Int32, _ y: Int32, _ w: Int32, _ h: Int32, _ color: [Color], _ alpha: [Float]) throws {
        let tx: Int32 = x / tileSize
        let ty: Int32 = y / tileSize
        
        writeEXRTile(tx, ty, w, h, color, alpha)
    }
    
    func closeFile() throws {
        writeTileOffsets()
        
        UI.printInfo(.IMG, "Saving image to \(filename!)")
        
        UI.printInfo(.IMG, "Image size: \(file!)")
        
        try file!.write(to: NSURL.fileURL(withPath: filename!))
    }
    
    func byteArray<T>(from value: T) -> [UInt8] where T: FixedWidthInteger {
        withUnsafeBytes(of: value.bigEndian, Array.init)
    }
    
    func writeRGBAHeader(_ w: Int32, _ h: Int32, _ tileSize: Int32) {
        let chanOut: [UInt8] = [0, channelType, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0]
        
        file!.append(contentsOf: ByteUtil.get4Bytes(Self.OE_MAGIC))
        
        file!.append(contentsOf: ByteUtil.get4Bytes(Self.OE_EXR_VERSION | Self.OE_TILED_FLAG))
        
        file!.append("channels".data(using: .ascii)!)
        file!.append(Self.ZERO)
        file!.append("chlist".data(using: .ascii)!)
        file!.append(Self.ZERO)
        file!.append(contentsOf: ByteUtil.get4Bytes(73))
        file!.append("R".data(using: .ascii)!)
        file!.append(contentsOf: chanOut)
        file!.append("G".data(using: .ascii)!)
        file!.append(contentsOf: chanOut)
        file!.append("B".data(using: .ascii)!)
        file!.append(contentsOf: chanOut)
        file!.append("A".data(using: .ascii)!)
        file!.append(contentsOf: chanOut)
        file!.append(Self.ZERO)
        
        //  compression
        file!.append("compression".data(using: .ascii)!)
        file!.append(Self.ZERO)
        file!.append("compression".data(using: .ascii)!)
        file!.append(Self.ZERO)
        file!.append(1)
        file!.append(contentsOf: ByteUtil.get4BytesInv(Int32(compression)))
        
        //  datawindow =~ image size
        file!.append("dataWindow".data(using: .ascii)!)
        file!.append(Self.ZERO)
        file!.append("box2i".data(using: .ascii)!)
        file!.append(Self.ZERO)
        file!.append(contentsOf: ByteUtil.get4Bytes(0x10))
        file!.append(contentsOf: ByteUtil.get4Bytes(0))
        file!.append(contentsOf: ByteUtil.get4Bytes(0))
        file!.append(contentsOf: ByteUtil.get4Bytes(w - 1))
        file!.append(contentsOf: ByteUtil.get4Bytes(h - 1))
        
        //  dispwindow -> look at openexr.com for more info
        file!.append("displayWindow".data(using: .ascii)!)
        file!.append(Self.ZERO)
        file!.append("box2i".data(using: .ascii)!)
        file!.append(Self.ZERO)
        file!.append(contentsOf: ByteUtil.get4Bytes(0x10))
        file!.append(contentsOf: ByteUtil.get4Bytes(0))
        file!.append(contentsOf: ByteUtil.get4Bytes(0))
        file!.append(contentsOf: ByteUtil.get4Bytes(w - 1))
        file!.append(contentsOf: ByteUtil.get4Bytes(h - 1))
        
        //
        // lines in increasing y order = 0 decreasing would be 1
        //
        file!.append("lineOrder".data(using: .ascii)!)
        file!.append(Self.ZERO)
        file!.append("lineOrder".data(using: .ascii)!)
        file!.append(Self.ZERO)
        file!.append(1)
        file!.append(contentsOf: ByteUtil.get4BytesInv(2))
        
        file!.append("pixelAspectRatio".data(using: .ascii)!)
        file!.append(Self.ZERO)
        file!.append("float".data(using: .ascii)!)
        file!.append(Self.ZERO)
        file!.append(contentsOf: ByteUtil.get4Bytes(4))
        file!.append(contentsOf: ByteUtil.get4Bytes(ByteUtil.floatToRawIntBits(1)))
        
        //  meaningless to a flat (2D) image
        file!.append("screenWindowCenter".data(using: .ascii)!)
        file!.append(Self.ZERO)
        file!.append("v2f".data(using: .ascii)!)
        file!.append(Self.ZERO)
        file!.append(contentsOf: ByteUtil.get4Bytes(8))
        file!.append(contentsOf: ByteUtil.get4Bytes(ByteUtil.floatToRawIntBits(0)))
        file!.append(contentsOf: ByteUtil.get4Bytes(ByteUtil.floatToRawIntBits(0)))
        
        //  meaningless to a flat (2D) image
        file!.append("screenWindowWidth".data(using: .ascii)!)
        file!.append(Self.ZERO)
        file!.append("float".data(using: .ascii)!)
        file!.append(Self.ZERO)
        file!.append(contentsOf: ByteUtil.get4Bytes(4))
        file!.append(contentsOf: ByteUtil.get4Bytes(ByteUtil.floatToRawIntBits(1)))
        
        self.tileSize = tileSize
        
        tilesX = (w + tileSize - 1) / tileSize
        tilesY = (h + tileSize - 1) / tileSize
        
        // twice the space for the compressing buffer, as for ex. the compressor
        // can actually increase the size of the data :) If that happens though,
        // it is not saved into the file, but discarded
        //
        tmpbuf = [UInt8](repeating: 0, count: Int(tileSize * tileSize * channelSize) * 4)
        comprbuf = [UInt8](repeating: 0, count: Int(tileSize * tileSize * channelSize) * 4 * 2)
        
        tileOffsets = [[Int64]](repeating: [Int64](repeating: 0, count: Int(tilesY)), count: Int(tilesX))
        
        file!.append("tiles".data(using: .ascii)!)
        file!.append(Self.ZERO)
        file!.append("tiledesc".data(using: .ascii)!)
        file!.append(Self.ZERO)
        file!.append(contentsOf: ByteUtil.get4Bytes(9))
        
        file!.append(contentsOf: ByteUtil.get4Bytes(tileSize))
        file!.append(contentsOf: ByteUtil.get4Bytes(tileSize))
        
        //  ONE_LEVEL tiles, ROUNDING_MODE = not important
        file!.append(Self.ZERO)
        
        //  an attribute with a name of 0 to end the list
        file!.append(Self.ZERO)
        
        //  save a pointer to where the tileOffsets are stored and write dummy
        //  fillers for now
        tileOffsetsPosition = Int64(file!.endIndex)
        
        writeTileOffsets(true)
    }
    
    func writeTileOffsets(_ append: Bool = false) {
        var _pos: Int = Int(tileOffsetsPosition)
        
        for ty in 0 ..< tilesY {
            for tx in 0 ..< tilesX {
                if append {
                    file!.append(contentsOf: ByteUtil.get8Bytes(tileOffsets![Int(tx)][Int(ty)]))
                } else {
                    file!.replaceSubrange(_pos ..< _pos + 8, with: ByteUtil.get8Bytes(tileOffsets![Int(tx)][Int(ty)]))
                    
                    _pos += 8
                }
            }
        }
    }
    
    func writeEXRTile(_ tileX: Int32, _ tileY: Int32, _ w: Int32, _ h: Int32, _ tile: [Color], _ alpha: [Float]) {
        lockQueue.sync { // synchronized block
            var rgb: [UInt8]
            
            // setting comprSize to max integer so without compression things
            // don't go awry
            var pixptr: Int32 = 0
            var writeSize: Int32 = 0
            var comprSize: Int32 = Int32.max
            let tileRangeX: Int32 = (tileSize < w) ? tileSize : w
            let tileRangeY: Int32 = (tileSize < h) ? tileSize : h
            let channelBase: Int32 = tileRangeX * channelSize
            
            //  lets see if the alignment matches, you can comment this out if
            //  need be
            if tileSize != tileRangeX && tileX == 0 {
                UI.printInfo(.IMG, " bad X alignment ")
            }
            
            if tileSize != tileRangeY && tileY == 0 {
                UI.printInfo(.IMG, " bad Y alignment ")
            }
            
            tileOffsets![Int(tileX)][Int(tileY)] = Int64(file!.endIndex)
           
            //  the tile header: tile's x&y coordinate, levels x&y coordinate and
            //  tilesize
            file!.append(contentsOf: ByteUtil.get4Bytes(tileX))
            file!.append(contentsOf: ByteUtil.get4Bytes(tileY))
            file!.append(contentsOf: ByteUtil.get4Bytes(0))
            file!.append(contentsOf: ByteUtil.get4Bytes(0))
            
            //  just in case
            tmpbuf = [UInt8](repeating: 0, count: Int(tileSize * tileSize * channelSize) * 4)
            
            for ty in 0 ..< tileRangeY {
                for tx in 0 ..< tileRangeX {
                    let rgbf: [Float] = tile[Int(tx + ty * tileRangeX)].getRGB()
                    
                    if channelType == Self.FLOAT {
                        rgb = ByteUtil.get4Bytes(ByteUtil.floatToRawIntBits(alpha[Int(tx + ty * tileRangeX)]))
                        
                        tmpbuf![Int(pixptr) + 0] = rgb[0]
                        tmpbuf![Int(pixptr) + 1] = rgb[1]
                        tmpbuf![Int(pixptr) + 2] = rgb[2]
                        tmpbuf![Int(pixptr) + 3] = rgb[3]
                    } else if channelType == Self.HALF {
                        rgb = ByteUtil.get2Bytes(ByteUtil.floatToHalf(alpha[Int(tx + ty * tileRangeX)]))
                        
                        tmpbuf![Int(pixptr) + 0] = rgb[0]
                        tmpbuf![Int(pixptr) + 1] = rgb[1]
                    }
                    
                    for component in 1 ... 3 {
                        if channelType == Self.FLOAT {
                            rgb = ByteUtil.get4Bytes(ByteUtil.floatToRawIntBits(rgbf[3 - component]))
                            
                            tmpbuf![Int((channelBase * Int32(component)) + pixptr + 0)] = rgb[0]
                            tmpbuf![Int((channelBase * Int32(component)) + pixptr + 1)] = rgb[1]
                            tmpbuf![Int((channelBase * Int32(component)) + pixptr + 2)] = rgb[2]
                            tmpbuf![Int((channelBase * Int32(component)) + pixptr + 3)] = rgb[3]
                        } else if channelType == Self.HALF {
                            rgb = ByteUtil.get2Bytes(ByteUtil.floatToHalf(rgbf[3 - component]))
                            
                            tmpbuf![Int((channelBase * Int32(component)) + pixptr + 0)] = rgb[0]
                            tmpbuf![Int((channelBase * Int32(component)) + pixptr + 1)] = rgb[1]
                        }
                    }
                    
                    pixptr += channelSize
                }
                
                pixptr += (tileRangeX * channelSize * 3)
            }
            
            writeSize = tileRangeX * tileRangeY * channelSize * 4
            
            if compression != Self.NO_COMPRESSION {
                comprSize = Self.compress(UInt8(compression), tmpbuf!, writeSize, &comprbuf)
            }
            
            //  lastly, write the size of the tile and the tile itself
            //  (compressed or not)
            if comprSize < writeSize {
                file!.append(contentsOf: ByteUtil.get4Bytes(comprSize))
                file!.append(contentsOf: comprbuf!.prefix(Int(comprSize)))
            } else {
                file!.append(contentsOf: ByteUtil.get4Bytes(writeSize))
                file!.append(contentsOf: tmpbuf!.prefix(Int(writeSize)))
            }
        }
    }
    
    static func compress(_ tp: UInt8, _ inBytes: [UInt8], _ inSize: Int32, _ outBytes: inout [UInt8]?) -> Int32 {
        if inSize == 0 {
            return 0
        }
        
        var t1: Int32 = 0
        var t2: Int32 = (inSize + 1) / 2
        var inPtr: Int32 = 0
        var tmp: [UInt8] = [UInt8](repeating: 0, count: Int(inSize))
        
        //  zip and rle treat the data first, in the same way so I'm not
        //  repeating the code
        if (tp == ZIP_COMPRESSION) || (tp == RLE_COMPRESSION) {
            //  reorder the pixel data ~ straight from ImfZipCompressor.cpp :)
            while true {
                if inPtr < inSize {
                    tmp[Int(t1)] = inBytes[Int(inPtr)]
                    
                    t1 += 1
                    
                    inPtr += 1
                } else {
                    break
                }
                
                if inPtr < inSize {
                    tmp[Int(t2)] = inBytes[Int(inPtr)]
                    
                    t2 += 1
                    
                    inPtr += 1
                } else {
                    break
                }
            }
            
            //  Predictor ~ straight from ImfZipCompressor.cpp :)
            t1 = 1
            
            var p: Int32 = Int32(tmp[Int(t1) - 1])
            
            while t1 < inSize {
                let d: Int32 = (Int32(tmp[Int(t1)]) - p) + (128 + 256)
                
                p = Int32(tmp[Int(t1)])
                
                tmp[Int(t1)] = UInt8(bitPattern: Int8(truncatingIfNeeded: d))
                
                t1 += 1
            }
        }
        
        //  We'll just jump from here to the wanted compress/decompress stuff if
        //  need be
        switch tp {
            case Self.ZIP_COMPRESSION:
                outBytes = [UInt8](Data(tmp).zip()!)
                
                return Int32(outBytes!.count)
            case Self.RLE_COMPRESSION:
                return rleCompress(tmp, inSize, &outBytes)
            default:
                return -1
        }
    }
    
    static func rleCompress(_ inBytes: [UInt8], _ inLen: Int32, _ outBytes: inout [UInt8]?) -> Int32 {
        var runStart: Int32 = 0
        var runEnd: Int32 = 1
        var outWrite: Int32 = 0
        
        while runStart < inLen {
            while runEnd < inLen, inBytes[Int(runStart)] == inBytes[Int(runEnd)], (runEnd - runStart - 1) < RLE_MAX_RUN {
                runEnd += 1
            }
            
            if runEnd - runStart >= RLE_MIN_RUN {
                // Compressable run
                outBytes![Int(outWrite)] = UInt8(bitPattern: Int8(truncatingIfNeeded: (runEnd - runStart) - 1))
                
                outWrite += 1
                
                outBytes![Int(outWrite)] = inBytes[Int(runStart)]
                
                outWrite += 1
                
                runStart = runEnd
            } else {
                //  Uncompressable run
                while runEnd < inLen, ((runEnd + 1) >= inLen || inBytes[Int(runEnd)] != inBytes[Int(runEnd) + 1]) || ((runEnd + 2) >= inLen || inBytes[Int(runEnd) + 1] != inBytes[Int(runEnd) + 2]), (runEnd - runStart) < RLE_MAX_RUN {
                    runEnd += 1
                }
                
                outBytes![Int(outWrite)] = UInt8(bitPattern: Int8(truncatingIfNeeded: (runStart - runEnd)))
                
                outWrite += 1
                
                while runStart < runEnd {
                    outBytes![Int(outWrite)] = inBytes[Int(runStart)]
                    
                    outWrite += 1
                    
                    runStart += 1
                }
            }
            
            runEnd += 1
        }
        
        return outWrite
    }
}
