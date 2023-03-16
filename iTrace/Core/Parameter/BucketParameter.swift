//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class BucketParameter: Parameter {
    static let PARAM_BUCKET_SIZE: String = "bucket.size"
    static let PARAM_BUCKET_ORDER: String = "bucket.order"
    static let ORDER_COLUMN: String = "column"
    static let ORDER_DIAGONAL: String = "diagonal"
    static let ORDER_HILBERT: String = "hilbert"
    static let ORDER_SPIRAL: String = "spiral"
    static let ORDER_RANDOM: String = "random"
    static let ORDER_ROW: String = "row"

    static let TYPE_BUCKET = "bucket"
    
    var size: Int32 = 0
    var order: String = ""

    private enum CodingKeys: String, CodingKey {
        case size
        case order
    }
    
    override init() {
        super.init()
        
        self.name = Self.TYPE_BUCKET
        
        self.type = ParameterType.TYPE_BUCKET
        
        initializable = true
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        
        self.name = name
        
        self.type = ParameterType.TYPE_BUCKET
        
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            size = try container.decode(Int32.self, forKey: .size)
            order = try container.decode(String.self, forKey: .order)
            
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
        
        try container.encode(size, forKey: .size)
        try container.encode(order, forKey: .order)
    }
    
    override func setup() {
        // failed decode check
        if !initializable {
            UI.printError(.SCENE, "Error setting up: \(name) of type \(type!.rawValue)")
            return
        }
        
        if size > 0 {
            API.shared.parameter(Self.PARAM_BUCKET_SIZE, size)
        }

        if !order.isEmpty {
            API.shared.parameter(Self.PARAM_BUCKET_ORDER, order)
        }
        
        API.shared.options(API.DEFAULT_OPTIONS)
    }
}
