//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class BanchOffParameter: GeometryParameter {
    init(_ name: String) {
        super.init()
        
        self.name = name
        
        self.type = ParameterType.TYPE_BANCHOFF
        
        initializable = true
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    override func setup() {
        super.setup()

        API.shared.geometry(name, Self.TYPE_BANCHOFF)

        setupInstance()
    }
}
