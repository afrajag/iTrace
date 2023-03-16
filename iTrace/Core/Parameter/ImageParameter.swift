//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class ImageParameter: Parameter {
    static let PARAM_AA_CACHE: String = "aa.cache"
    static let PARAM_AA_CONTRAST: String = "aa.contrast"
    static let PARAM_AA_DISPLAY: String = "aa.display"
    static let PARAM_AA_JITTER: String = "aa.jitter"
    static let PARAM_AA_MIN: String = "aa.min"
    static let PARAM_AA_MAX: String = "aa.max"
    static let PARAM_AA_SAMPLES: String = "aa.samples"
    static let PARAM_RESOLUTION_X: String = "resolutionX"
    static let PARAM_RESOLUTION_Y: String = "resolutionY"
    static let PARAM_SAMPLER: String = "sampler"
    static let PARAM_FILTER: String = "filter"

    static let FILTER_TRIANGLE: String = "triangle"
    static let FILTER_GAUSSIAN: String = "gaussian"
    static let FILTER_MITCHELL: String = "mitchel"
    static let FILTER_BLACKMAN_HARRIS: String = "blackman-harris"

    static let TYPE_IMAGE: String = "image"
    
    var resolutionX: Int32 = 1920
    var resolutionY: Int32 = 1080
    var aaMin: Int32 = 0
    var aaMax: Int32 = 2
    var aaSamples: Int32 = 4
    var aaContrast: Float = 0
    var aaJitter: Bool = false
    var aaCache: Bool = false
    var sampler: String = ""
    var filter: String = ""

    private enum CodingKeys: String, CodingKey {
        case resolutionX
        case resolutionY
        case aaMin
        case aaMax
        case aaSamples
        case aaContrast
        case aaJitter
        case aaCache
        case sampler
        case filter
    }
    
    override init() {
        super.init()
        
        self.name = Self.TYPE_IMAGE
        
        self.type = ParameterType.TYPE_IMAGE
        
        initializable = true
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        
        self.name = name
        
        self.type = ParameterType.TYPE_IMAGE
        
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            resolutionX = try container.decode(Int32.self, forKey: .resolutionX)
            resolutionY = try container.decode(Int32.self, forKey: .resolutionY)
            aaMin = try container.decodeIfPresent(Int32.self, forKey: .aaMin) ?? 0
            aaMax = try container.decodeIfPresent(Int32.self, forKey: .aaMax) ?? 2
            aaSamples = try container.decodeIfPresent(Int32.self, forKey: .aaSamples) ?? 4
            aaContrast = try container.decodeIfPresent(Float.self, forKey: .aaContrast) ?? 0.0
            aaJitter = try container.decodeIfPresent(Bool.self, forKey: .aaJitter) ?? false
            aaCache = try container.decodeIfPresent(Bool.self, forKey: .aaCache) ?? false
            sampler = try container.decodeIfPresent(String.self, forKey: .sampler) ?? ""
            filter = try container.decodeIfPresent(String.self, forKey: .filter) ?? ""
            
            initializable = true
        } catch let DecodingError.dataCorrupted(context) {
            UI.printError(.SCENE, context.debugDescription)
        } catch let DecodingError.keyNotFound(key, context) {
            UI.printError(.SCENE, "[type: \(type!.rawValue)] - Key '\(key.stringValue)' not found at path: \(context.codingPath.reduce("") { $0 + "/" + $1.stringValue })")
        } catch let DecodingError.valueNotFound(_, context) {
            UI.printError(.SCENE, "[type: \(type!.rawValue)] - Value not found at path: \(context.codingPath.reduce("") { $0 + "/" + $1.stringValue })")
        } catch let DecodingError.typeMismatch(typeMismatch, context)  {
            UI.printError(.SCENE, "[type: \(type!.rawValue)] - Type '\(typeMismatch)' mismatch at path: \(context.codingPath.reduce("") { $0 + "/" + $1.stringValue })")
        } catch {
            UI.printError(.SCENE, error.localizedDescription)
        }
    }
    
    override func encode(to encoder: Encoder) throws {
        // no super calling because we wont 'name' attribute to be present
        //try super.encode(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(resolutionX, forKey: .resolutionX)
        try container.encode(resolutionY, forKey: .resolutionY)
        try container.encode(aaMin, forKey: .aaMin)
        try container.encode(aaMax, forKey: .aaMax)
        try container.encode(aaSamples , forKey: .aaSamples)
        try container.encode(aaContrast, forKey: .aaContrast)
        try container.encode(aaJitter, forKey: .aaJitter)
        try container.encode(aaCache , forKey: .aaCache)
        try container.encode(sampler, forKey: .sampler)
        try container.encode(filter, forKey: .filter)
    }
    
    override func setup() {
        // failed decode check
        if !initializable {
            UI.printError(.SCENE, "Error setting up: \(name) of type \(type!.rawValue)")
            return
        }
        
        if resolutionX > 0 {
            API.shared.parameter(Self.PARAM_RESOLUTION_X, resolutionX)
        }

        if resolutionY > 0 {
            API.shared.parameter(Self.PARAM_RESOLUTION_Y, resolutionY)
        }

        //  Always set AA params
        API.shared.parameter(Self.PARAM_AA_MIN, aaMin)
        API.shared.parameter(Self.PARAM_AA_MAX, aaMax)

        if aaSamples > 0 {
            API.shared.parameter(Self.PARAM_AA_SAMPLES, aaSamples)
        }

        if aaContrast == 0 {
            API.shared.parameter(Self.PARAM_AA_CONTRAST, aaContrast)
        }

        API.shared.parameter(Self.PARAM_AA_JITTER, aaJitter)

        if !sampler.isEmpty {
            API.shared.parameter(Self.PARAM_SAMPLER, sampler)
        }

        if !filter.isEmpty {
            API.shared.parameter(Self.PARAM_FILTER, filter)
        }

        API.shared.parameter(Self.PARAM_AA_CACHE, aaCache)

        API.shared.options(API.DEFAULT_OPTIONS)
    }
}
