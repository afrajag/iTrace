//
//  SceneBuilder.swift
//  iTrace
//
//  Created by Fabrizio Pezzola on 07/05/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

protocol SceneBuilder: class {
    @discardableResult
    func build() -> SceneParameter?

    func previewRender(_ display: Display)

    func render(_ display: Display)
}
