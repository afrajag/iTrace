//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

import Foundation
import ImageIO

protocol BitmapReader: Initializable
{
    // Load the specified filename. This method should throw exception if it
    // encounters any errors. If the file is valid but its contents are not
    // (invalid header for example), a {@link BitmapFormatException} may be
    // thrown. It is an error for this method to return null.
    //
    // @param filename image filename to load
    // @return a new {@link Bitmap} object
    // @param isLinear if this is true, the bitmap is assumed to
    //            be already in linear space. This can be usefull when reading
    //            greyscale images for bump mapping for example. HDR formats can
    //            ignore this flag since they usually always store data in
    //            linear form.
    func load(_ filename: String, _ isLinear: Bool) throws -> Bitmap?
}

enum BitmapFormatException: Error
{
    case message(_ message: String)
}

// Helper final class finds pixels values within the given image
final class ImageHelper
{
    // The image URL
    private let filename: String

    // The image source to find pixels in
    private var imageSource: CGImageSource?

    // The image source to find pixels in
    private var image: CGImage?

    // Image width
    var width: Int = 0
    
    // Image height
    var height: Int = 0
    
    // The real pixel data
    private var pixelData: CFData?

    // The image data
    private var data: UnsafePointer<UInt8>?

    // The expected length of the image data
    private var expectedLengthA: Int?

    // The expected rgb length of the image
    private var expectedLengthRGB: Int?

    // The expected rgba length of the image
    private var expectedLengthRGBA: Int?

    // The actual number of bytes in the image
    private var numBytes: CFIndex?

    // - Parameter image: The image to find pixels in
    init(_ filename: String)
    {
        self.filename = filename
    }

    // Function loads all the image data for quick access later
    func loadImage() throws
    {
        // Create image URL
        let fileURL = NSURL(fileURLWithPath: filename)

        // Load image from URL
        imageSource = CGImageSourceCreateWithURL(fileURL, nil)

        if imageSource == nil {
            throw BitmapFormatException.message("Load texture failed")
        }
        
        // Get the image as a CGImage
        image = CGImageSourceCreateImageAtIndex(imageSource!, 0, nil)
        
        width = image!.width
        height = image!.height
        
        // Get the pixel data
        pixelData = image?.dataProvider?.data
        
        // Get the pointer to the start of the array
        data = CFDataGetBytePtr(pixelData)!

        // Calculate the expected lengths
        expectedLengthA = Int(image!.width * image!.height)
        expectedLengthRGB = 3 * expectedLengthA!
        expectedLengthRGBA = 4 * expectedLengthA!

        // Get the length of the data
        numBytes = CFDataGetLength(pixelData)
    }

    // Function sets all member vars to nil to help speed up GC
    func unloadImage()
    {
        // FIXME: salvataggio image per prova, togliere
        //let nsImage = NSImage(cgImage: image!, size: CGSize(width: 100, height: 100))
        //let _filename = "/Users/afrajag/Desktop/test_\(Int.random(in: 100...1000)).png"
        //try! NSBitmapImageRep(data: nsImage.tiffRepresentation!)!.representation(using: .png, properties: [:])!.write(to: NSURL(fileURLWithPath: _filename) as URL, options: .atomicWrite)
        
        pixelData = nil
        image = nil
        imageSource = nil
        data = nil
        expectedLengthA = nil
        expectedLengthRGB = nil
        expectedLengthRGBA = nil
        numBytes = nil
    }

    // Function gets the pixel colour from the given image using the provided x y coordinates
    // - Parameter pixelX: The X Pixel coordinate
    // - Parameter pixelY: The Y Pixel coordinate
    // - Parameter bgr: Whether we should return RGB, by default this is false so must be set if you want BGR
    func getPixel(_ pixelX: Int, _ pixelY: Int, _ bgr: Bool = false) -> [UInt8]
    {
        // If we have all the required member vars for this operation
        if let data = self.data,
            let expectedLengthA = self.expectedLengthA,
            let expectedLengthRGB = self.expectedLengthRGB,
            let expectedLengthRGBA = self.expectedLengthRGBA,
            let numBytes = self.numBytes
        {
            // Get the index of the pixel we want
            let index = image!.width * pixelY + pixelX

            // Check the number of bytes
            switch numBytes
            {
                case expectedLengthA:
                    return [0, 0, 0, data[index]]
                case expectedLengthRGB:
                    if bgr
                    {
                        return [data[3 * index + 2], data[3 * index + 1], data[3 * index], 1]
                    }
                    else
                    {
                        return [data[3 * index], data[3 * index + 1], data[3 * index + 2], 1]
                    }
                case expectedLengthRGBA:
                    if bgr
                    {
                        return [data[4 * index + 2], data[4 * index + 1], data[4 * index], data[4 * index + 3]]
                    }
                    else
                    {
                        return [data[4 * index], data[4 * index + 1], data[4 * index + 2], data[4 * index + 3]]
                    }
                default:
                    // unsupported format
                    return [0, 0, 0, 0]
            }
        }
        else
        {
            // Something didnt load properly or has been destroyed
            return [0, 0, 0, 0]
        }
    }
}
