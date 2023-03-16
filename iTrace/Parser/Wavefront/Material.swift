//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

import Foundation

final class MaterialBuilder {
    var name: String = ""
    var ambientColor: Color?
    var diffuseColor: Color?
    var specularColor: Color?
    var illuminationModel: IlluminationModel?
    var specularExponent: Double?
    var ambientTextureMapFilePath: String?
    var diffuseTextureMapFilePath: String?
}

final class Material {
    let name: String
    let ambientColor: Color
    let diffuseColor: Color
    let specularColor: Color
    let illuminationModel: IlluminationModel
    let specularExponent: Double?
    let ambientTextureMapFilePath: String?
    let diffuseTextureMapFilePath: String?

    init(builderBlock: (MaterialBuilder) -> MaterialBuilder) {
        let builder = builderBlock(MaterialBuilder())

        self.name = builder.name
        self.ambientColor = builder.ambientColor ?? Color.BLACK
        self.diffuseColor = builder.diffuseColor ?? Color.BLACK
        self.specularColor = builder.specularColor ?? Color.BLACK
        self.illuminationModel = builder.illuminationModel ?? .Constant
        self.specularExponent = builder.specularExponent
        self.ambientTextureMapFilePath = builder.ambientTextureMapFilePath
        self.diffuseTextureMapFilePath = builder.diffuseTextureMapFilePath
    }
}

extension Material: Equatable {}

func ==(lhs: Material, rhs: Material) -> Bool {
    let result = (lhs.name == rhs.name) &&
        lhs.ambientColor.fuzzyEquals(rhs.ambientColor) &&
        lhs.diffuseColor.fuzzyEquals(rhs.diffuseColor) &&
        lhs.specularColor.fuzzyEquals(rhs.specularColor) &&
        lhs.illuminationModel == rhs.illuminationModel

    return result
}

enum IlluminationModel: Int {
    // This is a constant color illumination model. The color is the specified Kd for the material. The formula is:
    // color = Kd
    case Constant = 0

    // This is a diffuse illumination model using Lambertian shading.
    // The color includes an ambient and diffuse shading terms for each light source. The formula is
    // color = KaIa + Kd { SUM j=1..ls, (N * Lj)Ij }
    case Diffuse = 1

    // This is a diffuse and specular illumination model using Lambertian shading
    // and Blinn's interpretation of Phong's specular illumination model (BLIN77).
    // The color includes an ambient constant term, and a diffuse and specular shading term for each light source. The formula is:
    // color = KaIa + Kd { SUM j=1..ls, (N*Lj)Ij } + Ks { SUM j=1..ls, ((H*Hj)^Ns)Ij }
    case DiffuseSpecular = 2

    // Term definitions are: Ia ambient light, Ij light j's intensity, Ka ambient reflectance, Kd diffuse reflectance,
    // Ks specular reflectance, H unit vector bisector between L and V, L unit light vector, N unit surface normal, V unit view vector
}
