//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

import Foundation
import PathKit

enum MaterialLoadingError: Error {
    case UnexpectedFileFormat(error: String)
}

final class MaterialLoader {
    // Represent the state of parsing
    // at any point in time
    struct State {
        var materialName: String?
        var ambientColor: Color?
        var diffuseColor: Color?
        var specularColor: Color?
        var specularExponent: Double?
        var illuminationModel: IlluminationModel?
        var ambientTextureMapFilePath: String?
        var diffuseTextureMapFilePath: String?

        func isDirty() -> Bool {
            if materialName != nil {
                return true
            }

            if ambientColor != nil {
                return true
            }

            if diffuseColor != nil {
                return true
            }

            if specularColor != nil {
                return true
            }

            if specularExponent != nil {
                return true
            }

            if illuminationModel != nil {
                return true
            }

            if ambientTextureMapFilePath != nil {
                return true
            }

            if diffuseTextureMapFilePath != nil {
                return true
            }

            return false
        }
    }

    // Source markers
    static let newMaterialMarker = "newmtl"
    static let ambientColorMarker = "Ka"
    static let diffuseColorMarker = "Kd"
    static let specularColorMarker = "Ks"
    static let specularExponentMarker = "Ns"
    static let illuminationModeMarker = "illum"
    static let ambientTextureMapMarker = "map_Ka"
    static let diffuseTextureMapMarker = "map_Kd"

    let scanner: MaterialParser
    let basePath: String
    var state: State

    // Init an MaterialLoader with the
    // source of the .mtl file as a string
    init(source: String, basePath: String) {
        self.basePath = basePath
        
        scanner = MaterialParser(source: source)
        
        state = State()
    }

    // Read the specified source.
    // This operation is singled threaded and
    // should not be invoked again before
    // the call has returned
    func read() throws -> [Material] {
        resetState()
        var materials: [Material] = []

        do {
            while scanner.dataAvailable {
                let marker = scanner.readMarker()

                guard let m = marker, m.length > 0 else {
                    scanner.moveToNextLine()
                    
                    continue
                }

                if MaterialLoader.isAmbientColor(m) {
                    let color = try readColor()
                    
                    state.ambientColor = color

                    scanner.moveToNextLine()
                    
                    continue
                }

                if MaterialLoader.isDiffuseColor(m) {
                    let color = try readColor()
                    
                    state.diffuseColor = color

                    scanner.moveToNextLine()
                    
                    continue
                }

                if MaterialLoader.isSpecularColor(m) {
                    let color = try readColor()
                    
                    state.specularColor = color

                    scanner.moveToNextLine()
                    
                    continue
                }

                if MaterialLoader.isSpecularExponent(m) {
                    let specularExponent = try readSpecularExponent()

                    state.specularExponent = specularExponent

                    scanner.moveToNextLine()
                    
                    continue
                }

                if MaterialLoader.isIlluminationMode(m) {
                    let model = try readIlluminationModel()
                    
                    state.illuminationModel = model

                    scanner.moveToNextLine()
                    
                    continue
                }

                if MaterialLoader.isAmbientTextureMap(m) {
                    let mapFilename = try readFilename()

                    state.ambientTextureMapFilePath = Path(mapFilename).isAbsolute ? mapFilename : Path(components: [basePath, mapFilename]).string

                    scanner.moveToNextLine()
                    
                    continue
                }

                if MaterialLoader.isDiffuseTextureMap(m) {
                    let mapFilename = try readFilename()
                    
                    state.diffuseTextureMapFilePath = Path(mapFilename).isAbsolute ? mapFilename : Path(components: [basePath, mapFilename]).string

                    scanner.moveToNextLine()
                    
                    continue
                }

                if MaterialLoader.isNewMaterial(m) {
                    if let material = try buildMaterial() {
                        materials.append(material)
                    }

                    state = State()
                    
                    state.materialName = scanner.readLine()
                    
                    scanner.moveToNextLine()
                    
                    continue
                }
                
                scanner.readLine()
                
                scanner.moveToNextLine()
                
                continue
            }

            if let material = try buildMaterial() {
                materials.append(material)
            }

            state = State()
        }

        return materials
    }

    func resetState() {
        scanner.reset()
        
        state = State()
    }

    static func isNewMaterial(_ marker: String) -> Bool {
        return marker == newMaterialMarker
    }

    static func isAmbientColor(_ marker: String) -> Bool {
        return marker == ambientColorMarker
    }

    static func isDiffuseColor(_ marker: String) -> Bool {
        return marker == diffuseColorMarker
    }

    static func isSpecularColor(_ marker: String) -> Bool {
        return marker == specularColorMarker
    }

    static func isSpecularExponent(_ marker: String) -> Bool {
        return marker == specularExponentMarker
    }

    static func isIlluminationMode(_ marker: String) -> Bool {
        return marker == illuminationModeMarker
    }

    static func isAmbientTextureMap(_ marker: String) -> Bool {
        return marker == ambientTextureMapMarker
    }

    static func isDiffuseTextureMap(_ marker: String) -> Bool {
        return marker == diffuseTextureMapMarker
    }

    func readColor() throws -> Color {
        do {
            return try scanner.readColor()
        } catch let ObjectScannerError.InvalidData(error) {
            throw MaterialLoadingError.UnexpectedFileFormat(error: error)
        } catch let ObjectScannerError.UnreadableData(error) {
            throw MaterialLoadingError.UnexpectedFileFormat(error: error)
        }
    }

    func readIlluminationModel() throws -> IlluminationModel {
        do {
            let value = try scanner.readInt()
            if let model = IlluminationModel(rawValue: Int(value)) {
                return model
            }

            throw MaterialLoadingError.UnexpectedFileFormat(error: "Invalid illumination model: \(value)")
        } catch let ObjectScannerError.InvalidData(error) {
            throw MaterialLoadingError.UnexpectedFileFormat(error: error)
        }
    }

    func readSpecularExponent() throws -> Double {
        do {
            let value = try scanner.readDouble()

            guard value >= 0.0, value <= 1000.0 else {
                throw MaterialLoadingError.UnexpectedFileFormat(error: "Invalid Ns value: !(value)")
            }

            return value
        } catch let ObjectScannerError.InvalidData(error) {
            throw MaterialLoadingError.UnexpectedFileFormat(error: error)
        }
    }

    func readFilename() throws -> String {
        do {
            return try scanner.readString()
        } catch let ObjectScannerError.InvalidData(error) {
            throw MaterialLoadingError.UnexpectedFileFormat(error: error)
        }
    }

    func buildMaterial() throws -> Material? {
        guard state.isDirty() else {
            return nil
        }

        guard let name = state.materialName else {
            throw MaterialLoadingError.UnexpectedFileFormat(error: "Material name required for all materials")
        }

        return Material {
            $0.name = name
            $0.ambientColor = self.state.ambientColor
            $0.diffuseColor = self.state.diffuseColor
            $0.specularColor = self.state.specularColor
            $0.specularExponent = self.state.specularExponent
            $0.illuminationModel = self.state.illuminationModel
            $0.ambientTextureMapFilePath = self.state.ambientTextureMapFilePath
            $0.diffuseTextureMapFilePath = self.state.diffuseTextureMapFilePath

            return $0
        }
    }
}
