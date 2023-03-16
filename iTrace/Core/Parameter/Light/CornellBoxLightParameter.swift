//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class CornellBoxLightParameter: LightParameter {
    static let PARAM_MIN_CORNER: String = "corner0"
    static let PARAM_MAX_CORNER: String = "corner1"
    static let PARAM_LEFT_COLOR: String = "leftColor"
    static let PARAM_RIGHT_COLOR: String = "rightColor"
    static let PARAM_TOP_COLOR: String = "topColor"
    static let PARAM_BOTTOM_COLOR: String = "bottomColor"
    static let PARAM_BACK_COLOR: String = "backColor"

    var samples: Int32 = 0
    var min: Point3?
    var max: Point3?
    var radiance: Color?
    var left: Color?
    var right: Color?
    var top: Color?
    var bottom: Color?
    var back: Color?

    private enum CodingKeys: String, CodingKey {
        case samples
        case min
        case max
        case radiance
        case left
        case right
        case top
        case bottom
        case back
    }

    init(_ name: String) {
        super.init()
        
        self.name = name
        
        self.type = ParameterType.TYPE_CORNELL_BOX
        
        initializable = true
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        
        self.name = name
        
        self.type = ParameterType.TYPE_CORNELL_BOX
        
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            samples = try container.decode(Int32.self, forKey: .samples)
            min = try container.decode(Point3.self, forKey: .min)
            max = try container.decode(Point3.self, forKey: .max)
            radiance = try container.decode(Color.self, forKey: .radiance)
            left = try container.decode(Color.self, forKey: .left)
            right = try container.decode(Color.self, forKey: .right)
            top = try container.decode(Color.self, forKey: .top)
            bottom = try container.decode(Color.self, forKey: .bottom)
            back = try container.decode(Color.self, forKey: .back)
            
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
        try super.encode(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(samples, forKey: .samples)
        try container.encode(min, forKey: .min)
        try container.encode(max, forKey: .max)
        try container.encode(radiance, forKey: .radiance)
        try container.encode(left, forKey: .left)
        try container.encode(right , forKey: .right)
        try container.encode(top, forKey: .top)
        try container.encode(bottom, forKey: .bottom)
        try container.encode(back, forKey: .back)
    }
    
    override func setup() {
        // failed decode check
        if !initializable {
            UI.printError(.SCENE, "Error setting up: \(name) of type \(type!.rawValue)")
            return
        }
        
        API.shared.parameter(Self.PARAM_MIN_CORNER, min!)
        API.shared.parameter(Self.PARAM_MAX_CORNER, max!)
        API.shared.parameter(Self.PARAM_LEFT_COLOR, nil, left!.getRGB())
        API.shared.parameter(Self.PARAM_RIGHT_COLOR, nil, right!.getRGB())
        API.shared.parameter(Self.PARAM_TOP_COLOR, nil, top!.getRGB())
        API.shared.parameter(Self.PARAM_BOTTOM_COLOR, nil, bottom!.getRGB())
        API.shared.parameter(Self.PARAM_BACK_COLOR, nil, back!.getRGB())
        API.shared.parameter(Self.PARAM_RADIANCE, nil, radiance!.getRGB())
        API.shared.parameter(Self.PARAM_SAMPLES, samples)

        API.shared.light(name, Self.TYPE_CORNELL_BOX)
    }
}
