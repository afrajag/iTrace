//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

//
//  Initializable.swift
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

protocol Initializable: class, CustomStringConvertible {
    var description: String { get }

    init()
}

extension Initializable {
    var description: String { "\(Self.self)" }
}
