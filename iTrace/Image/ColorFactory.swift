//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class ColorFactory {
    // Return the name of the internal color space. This string can be used
    // interchangeably with null in the following methods.
    //
    // @return internal colorspace name
    static func getInternalColorspace() -> String {
        return "sRGB linear"
    }

    // Checks to see how many values are required to specify a color using the
    // given colorspace. This number can be variable for spectrum colors, in
    // which case the returned value is -1. If the colorspace name is invalid,
    // this method returns -2. No exception is thrown. This method is intended
    // for parsers that want to know how many floating values to retrieve from a
    // file.
    //
    // @param colorspace
    // @return number of floating point numbers expected, -1 for any, -2 on
    //         error
    static func getRequiredDataValues(_ colorspace: String?) -> Int32 {
        if colorspace == nil {
            return 3
        }

        if colorspace == "sRGB nonlinear" {
            return 3
        } else if colorspace == "sRGB linear" {
            return 3
        } else if colorspace == "XYZ" {
            return 3
        } else if colorspace == "blackbody" {
            return 1
        } else if colorspace!.starts(with: "spectrum") {
            return -1
        } else {
            return -2
        }
    }

    // Creates a color value in the renderer's internal color space from a
    // string (representing the color space name) and an array of floating point
    // values. If the colorspace string is null, we assume the data was supplied
    // in internal space. This method does much error checking and may throw a
    // {@link RuntimeException} if its parameters are not consistent. Here are
    // the currently supported color spaces:
    // <ul>
    // <li>"sRGB nonlinear" - requires 3 values</li>
    // <li>"sRGB linear" - requires 3 values</li>
    // <li>"XYZ" - requires 3 values</li>
    // <li>blackbody - requires 1 value (temperature in Kelvins)</li>
    // <li>spectrum [min] [max] - any number of values (must be
    // >0), [start] and [stop] is the range over which the spectrum is defined
    // in nanometers.</li>
    // </ul>
    //
    // @param colorspace color space name
    // @param data data describing this color
    // @return a valid color in the renderer's color space
    // @throws ColorSpecificationException
    static func createColor(_ colorspace: String?, _ data: [Float]) throws -> Color {
        let required: Int32 = getRequiredDataValues(colorspace)

        if required == -2 {
            throw ColorSpecificationException.invalidColorMessage("unknown colorspace \(colorspace!)")
        }

        if required != -1, required != data.count {
            throw ColorSpecificationException.invalidColorExpected(required, Int32(data.count))
        }

        if colorspace == nil {
            return Color(data[0], data[1], data[2])
        } else if colorspace == "sRGB nonlinear" {
            return Color(data[0], data[1], data[2]).toLinear()
        } else if colorspace == "sRGB linear" {
            return Color(data[0], data[1], data[2])
        } else if colorspace == "XYZ" {
            return RGBSpace.SRGB.convertXYZtoRGB(XYZColor(data[0], data[1], data[2]))
        } else if colorspace == "blackbody" {
            return RGBSpace.SRGB.convertXYZtoRGB(BlackbodySpectrum(data[0]).toXYZ())
        } else if colorspace!.starts(with: "spectrum") {
            let tokens = colorspace!.components(separatedBy: " ")

            if tokens.count != 3 {
                throw ColorSpecificationException.invalidColorMessage("invalid spectrum specification")
            }

            if data.isEmpty {
                throw ColorSpecificationException.invalidColorMessage("missing spectrum data")
            }

            // FIXME: controllare NumberFormatException
            // do {
            let lambdaMin: Float? = Float(tokens[1])
            let lambdaMax: Float? = Float(tokens[2])

            return RGBSpace.SRGB.convertXYZtoRGB(RegularSpectralCurve(data, lambdaMin!, lambdaMax!).toXYZ())
            // } catch {
            // throw ColorSpecificationException.invalidColorMessage("unable to parse spectrum wavelength range")
            // }
        }

        throw ColorSpecificationException.invalidColorMessage("Inconsistent code Please report this error. (Input \(colorspace!) - \(data.count))")
    }
}

enum ColorSpecificationException: Error {
    case invalidColor
    case invalidColorMessage(_ message: String)
    case invalidColorExpected(_ expected: Int32, _ found: Int32)
}
