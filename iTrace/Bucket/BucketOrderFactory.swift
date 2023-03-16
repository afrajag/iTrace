//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class BucketOrderFactory {
    required init() {}
 
    static func create(_ order: String) -> BucketOrder {
        var flip: Bool = false
        var _order = order
        
        if _order.hasPrefix("inverse") || _order.hasPrefix("invert") || _order.hasPrefix("reverse") {
            let tokens: [String] = _order.components(separatedBy: .whitespaces).filter { $0 != "" }
            
            if tokens.count == 2 {
                _order = tokens[1]
                
                flip = true
            }
        }
        
        let o: BucketOrder? = PluginRegistry.bucketOrderPlugins.createInstance(_order)
        
        if o == nil {
            UI.printWarning(.BCKT, "Unrecognized bucket ordering: \"\(_order)\" - using hilbert")
            
            return create("hilbert")
        }
        
        return flip ? InvertedBucketOrder(o!) : o!
    }
}

