//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class FishEyeCameraParameter: CameraParameter {
    init(_ name: String) {
        super.init()
        
        self.name = name
        
        self.type = ParameterType.TYPE_FISH_EYE
        
        initializable = true
    }

    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    // FisheyeLens lens
    override func setup() {
        // failed decode check
        if !initializable {
            UI.printError(.SCENE, "Error setting up: \(name) of type \(type!.rawValue)")
            return
        }
        
        // applying transform to camera
        API.shared.parameter("transform", AffineTransform.lookAt(eye!, target!, up!))
        
        API.shared.parameter(Self.PARAM_SHUTTER_OPEN, shutterOpen)
        API.shared.parameter(Self.PARAM_SHUTTER_CLOSE, shutterClose)
        
        API.shared.camera(name, Self.TYPE_FISH_EYE)

        super.setup()
    }
}
