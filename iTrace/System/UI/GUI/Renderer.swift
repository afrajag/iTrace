//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

import AppKit

final class Renderer: NSView {
    static var BORDERS: [Color] = [Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW, Color.CYAN, Color.MAGENTA]
    
    var x: Int32 = 0
    var y: Int32 = 0
    
    var w: Int32 = 0
    var h: Int32 = 0
    
    // var data: [Color]?
    // var alpha: [Float]?
    
    var c: Color?
    var fillAlpha: Float = 1 // default to full opacity
    
    var width: Int32 = 0
    var height: Int32 = 0
    
    var data: [UInt8] = [UInt8]()
    
    var figure: NSBezierPath = NSBezierPath()
    
    var threadId: Int = 1
    var numThreads: Int = ProcessInfo().processorCount
    
    let lockQueue = DispatchQueue(label: "renderer.lock.serial.queue")
    
    override var isFlipped: Bool {
        return true
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let border: Color = Self.BORDERS[Int(threadId) % Self.BORDERS.count]
        
        if data.count != 0 {
            NSColor(red: CGFloat(border.r), green: CGFloat(border.g), blue: CGFloat(border.b), alpha: 1).set()
            
            // figure.lineWidth = 1 // hair line
            
            let image = byteArrayToCGImage(raw: &data, w: Int(width), h: Int(height))
            
            // let test = NSImage(data: Data(bytes: &data, count: Int(w*h)))
            let test = NSImage(cgImage: image!, size: NSSize(width: Int(w), height: Int(h)))
            
            test.draw(in: NSRect(x: 0, y: 0, width: Int(width), height: Int(height)))
            
            figure.stroke()
        }
    }
    
    func imageBegin(_ w: Int32, _ h: Int32, _ bucketSize: Int32) {
        data = [UInt8](repeating: 0, count: Int(w * h) * 4) //  RGBA8
        
        width = w
        height = h
    }
    
    func imagePrepare(_ x: Int32, _ y: Int32, _ w: Int32, _ h: Int32, _ threadId: Int32) {
        lockQueue.sync { // synchronized block
            self.threadId = Int(threadId)
            
            if Int(threadId) % numThreads == 0 {
                figure = NSBezierPath()
            }
            
            for by in 0 ..< h {
                for bx in 0 ..< w {
                    if (bx == 0) || (bx == (w - 1)) {
                        if ((5 * by) < h) || ((5 * (h - by - 1)) < h) {
                            figure.appendRect(NSRect(x: Int(x + bx), y: Int(y + by), width: 1, height: 1)) //  {x,y} destination
                        }
                    } else if (by == 0) || (by == (h - 1)) {
                        if ((5 * bx) < w) || ((5 * (w - bx - 1)) < w) {
                            figure.appendRect(NSRect(x: Int(x + bx), y: Int(y + by), width: 1, height: 1)) //  {x,y} destination
                        }
                    }
                }
            }
        }
        
        DispatchQueue.main.async {
            self.needsDisplay = true
        }
    }
    
    func imageUpdate(_ x: Int32, _ y: Int32, _ w: Int32, _ h: Int32, _ color: [Color], _ alpha: [Float]) {
        lockQueue.sync { // synchronized block
            self.x = x
            self.y = y
            self.w = w
            self.h = h
            // self.data = data
            // self.alpha = alpha
            
            let _color0 = ColorEncoder.unpremult(color, alpha) // gamma correction
            let _color = ColorEncoder.unlinearize(_color0)
            
            let tileData: [UInt8] = ColorEncoder.quantizeRGBA8(_color, alpha)
            
            var index = 0
            
            for j in 0 ..< h {
                var imageIndex: Int32 = 4 * ((y + j) * width + x)
                
                for _ in 0 ..< w {
                    data[Int(imageIndex) + 0] = tileData[index + 0]
                    data[Int(imageIndex) + 1] = tileData[index + 1]
                    data[Int(imageIndex) + 2] = tileData[index + 2]
                    data[Int(imageIndex) + 3] = tileData[index + 3]
                    
                    index += 4
                    imageIndex += 4
                }
            }
        }
        
        DispatchQueue.main.async {
            self.needsDisplay = true
        }
    }
    
    func imageFill(_ x: Int32, _ y: Int32, _ w: Int32, _ h: Int32, _ c: Color, _ alpha: Float) {
        lockQueue.sync { // synchronized block
            self.x = x
            self.y = y
            self.w = w
            self.h = h
            self.c = c
            self.fillAlpha = alpha
            
            let _col: Color = c.copy().mul(1.0 / alpha).toNonLinear()
            
            var index = 0
            
            for j in 0 ..< h {
                var imageIndex: Int32 = 4 * ((y + j) * width + x)
                
                for _ in 0 ..< w {
                    data[Int(imageIndex) + 0] = UInt8(Int32(_col.r * 255 + 0.5).clamp(0, 255))
                    data[Int(imageIndex) + 1] = UInt8(Int32(_col.g * 255 + 0.5).clamp(0, 255))
                    data[Int(imageIndex) + 2] = UInt8(Int32(_col.b * 255 + 0.5).clamp(0, 255))
                    data[Int(imageIndex) + 3] = UInt8(alpha)
                    
                    index += 4
                    imageIndex += 4
                }
            }
        }
        
        DispatchQueue.main.async {
            self.needsDisplay = true
        }
    }
    
    func byteArrayToCGImage(raw: UnsafeMutablePointer<UInt8>, w: Int, h: Int) -> CGImage! {
        // 4 bytes(rgba channels) for each pixel
        let bytesPerPixel: Int = 4
        
        // (8 bits per each channel)
        let bitsPerComponent: Int = 8
        
        let bitsPerPixel = bytesPerPixel * bitsPerComponent
        
        // channels in each row (width)
        let bytesPerRow: Int = w * bytesPerPixel
        
        let cfData = CFDataCreate(nil, raw, w * h * bytesPerPixel)
        
        let cgDataProvider = CGDataProvider(data: cfData!)!
        
        let deviceColorSpace = CGColorSpaceCreateDeviceRGB()
        
        let image: CGImage! = CGImage(width: w,
                                      height: h,
                                      bitsPerComponent: bitsPerComponent,
                                      bitsPerPixel: bitsPerPixel,
                                      bytesPerRow: bytesPerRow,
                                      space: deviceColorSpace,
                                      bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
                                      provider: cgDataProvider,
                                      decode: nil,
                                      shouldInterpolate: true,
                                      intent: CGColorRenderingIntent.defaultIntent)
        
        return image
    }
}
