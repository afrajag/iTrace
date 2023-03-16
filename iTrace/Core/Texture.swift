//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//
import Foundation

final class Texture {
    var filename: String
    var isLinear: Bool = false
    var bitmap: Bitmap?
    var loaded: Int32 = 0

    let lockQueue = DispatchQueue(label: "texture.lock.serial.queue")

    // Creates a new texture from the specfied file.
    //
    // @param filename image file to load
    // @param isLinear is the texture gamma corrected already
    init(_ filename: String, _ isLinear: Bool) {
        self.filename = filename
        self.isLinear = isLinear

        loaded = 0
    }

    func load() {
        lockQueue.sync { // synchronized block
            if loaded != 0 {
                return
            }
            
            let file_extension: String = FileUtils.getExtension(filename)!
            
            do {
                UI.printInfo(.TEX, "Reading texture bitmap from: \"\(filename)\" ...")

                if let reader: BitmapReader = PluginRegistry.bitmapReaderPlugins.createInstance(file_extension) {
                    try bitmap = reader.load(filename, isLinear)

                    if bitmap!.getWidth() == 0 || bitmap!.getHeight() == 0 {
                        UI.printError(.TEX, "Bitmap reading failed")

                        bitmap = nil
                    }
                }

                if bitmap == nil {
                    UI.printError(.TEX, "Bitmap reading failed")

                    bitmap = BitmapBlack()
                } else {
                    UI.printDetailed(.TEX, "Texture bitmap reading complete: \(bitmap!.getWidth())x\(bitmap!.getHeight()) pixels found")
                }
            } catch BitmapFormatException.message(let errString) {
                UI.printError(.TEX, "Loading texture error: \(errString)")

                bitmap = BitmapBlack()
            } catch {
                UI.printError(.TEX, "Loading texture error")

                bitmap = BitmapBlack()
            }
            
            loaded = 1
        }
        
    }

    func getBitmap() -> Bitmap {
        if loaded == 0 {
            load()
        }

        return bitmap!
    }

    // Gets the color at location (x,y) in the texture. The lookup is performed
    // using the fractional component of the coordinates, treating the texture
    // as a unit square tiled in both directions. Bicubic filtering is performed
    // on the four nearest pixels to the lookup point.
    //
    // @param x x coordinate into the texture
    // @param y y coordinate into the texture
    // @return filtered color at location (x,y)
    func getPixel(_ x: Float, _ y: Float) -> Color {
        let bitmap: Bitmap = getBitmap()

        let _x = MathUtils.frac(x)
        let _y = MathUtils.frac(y)

        let dx: Float = _x * Float(bitmap.getWidth() - 1)
        let dy: Float = _y * Float(bitmap.getHeight() - 1)
        let ix0: Int32 = Int32(dx)
        let iy0: Int32 = Int32(dy)
        let ix1: Int32 = (ix0 + 1) % bitmap.getWidth()
        let iy1: Int32 = (iy0 + 1) % bitmap.getHeight()

        var u: Float = dx - Float(ix0)
        var v: Float = dy - Float(iy0)

        u = u * u * (3.0 - (2.0 * u))
        v = v * v * (3.0 - (2.0 * v))

        let k00: Float = (1.0 - u) * (1.0 - v)
        let c00: Color = bitmap.readColor(ix0, iy0)
        let k01: Float = (1.0 - u) * v
        let c01: Color = bitmap.readColor(ix0, iy1)
        let k10: Float = u * (1.0 - v)
        let c10: Color = bitmap.readColor(ix1, iy0)
        let k11: Float = u * v
        let c11: Color = bitmap.readColor(ix1, iy1)

        var c: Color = Color.mul(k00, c00)

        c = c.madd(k01, c01)
        c = c.madd(k10, c10)
        c = c.madd(k11, c11)

        return c
    }

    func getNormal(_ x: Float, _ y: Float, _ basis: OrthoNormalBasis) -> Vector3 {
        let rgb: [Float] = getPixel(x, y).getRGB()
        return basis.transform(Vector3(2 * rgb[0] - 1, 2 * rgb[1] - 1, 2 * rgb[2] - 1)).normalize()
    }

    func getBump(_ x: Float, _ y: Float, _ basis: OrthoNormalBasis, _ scale: Float) -> Vector3 {
        let bitmap: Bitmap = getBitmap()

        let dx: Float = 1.0 / Float(bitmap.getWidth())
        let dy: Float = 1.0 / Float(bitmap.getHeight())

        let b0: Float = getPixel(x, y).getLuminance()
        let bx: Float = getPixel(x + dx, y).getLuminance()
        let by: Float = getPixel(x, y + dy).getLuminance()

        return basis.transform(Vector3(scale * (b0 - bx), scale * (b0 - by), 1)).normalize()
    }

    enum TextureError: Error {
        case loadingError
    }
}
