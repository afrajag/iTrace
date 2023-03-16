//
//  TestScene.swift
//  iTrace
//
//  Created by Fabrizio Pezzola on 09/03/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class WireframeDemoScene: SceneBuilder {
    func build() -> SceneParameter? {
        //  Including a scene
        let scene = GumboAndTeapotScene().build()
        
        //  Loading a custom procedural shader
        PluginRegistry.shaderPlugins.registerPlugin("custom_wireframe", CustomWireShader.self)
        //API.shared.parameter("width", Float.pi * 0.5 / 8192)
        API.shared.shader("ao_wire", "custom_wireframe")
        
        //  Overriding existent shaders
        //API.shared.parameter("override.shader", "ao_wire")
        //API.shared.parameter("override.photons", true)
        let overShader: OverrideParameter = OverrideParameter()
        overShader.shader = "ao_wire"
        overShader.photons = true
        scene!.add(overShader)
        
        let image: ImageParameter = ImageParameter()
        image.resolutionX = 320
        image.resolutionY = 240
        image.aaMin = 2
        image.aaMax = 2
        image.filter = ImageParameter.FILTER_BLACKMAN_HARRIS
        scene!.add(image)

        return scene
    }

    func previewRender(_ display: Display) {
        API.shared.parameter("sampler", "ipr")
        API.shared.options(API.DEFAULT_OPTIONS)
        API.shared.render(API.DEFAULT_OPTIONS, display)
    }

    func render(_ display: Display) {
        API.shared.parameter("sampler", "bucket")
        API.shared.options(API.DEFAULT_OPTIONS)
        API.shared.render(API.DEFAULT_OPTIONS, display)
    }

    final class CustomWireShader: WireframeShader {
        //  set to false to overlay wires on regular shaders
        private var ambocc: Bool = true

        override func getFillColor(_ state: ShadingState) -> Color {
            return ambocc ? state.occlusion(16, 6.0) : state.getShader()!.getRadiance(state)
        }
    }
}
