//
//  SphereFlakeScene.swift
//  iTrace
//
//  Created by Fabrizio Pezzola on 09/03/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class SphereFlakeScene: SceneBuilder {
    func build() -> SceneParameter? {
        let scene = SceneParameter("SphereFlake")

        let image: ImageParameter = ImageParameter()
        image.resolutionX = 960
        image.resolutionY = 540
        image.aaMin = 4
        image.aaMax = 4
        image.aaSamples = 4
        image.filter = ImageParameter.FILTER_GAUSSIAN
        scene.add(image)

        let traceDepths: TraceDepthsParameter = TraceDepthsParameter()
        traceDepths.diffuse = 1
        traceDepths.reflection = 1
        traceDepths.refraction = 0
        scene.add(traceDepths)
        
        let camera: ThinLensCameraParameter = ThinLensCameraParameter("camera")
        camera.eye = Point3(-5, 0, -0.9)
        camera.target = Point3(0, 0, 0.2)
        camera.up = Vector3(0, 0, 1)
        camera.fov = 60.0
        camera.aspect = 1.777777777777
        camera.focusDistance = 5
        camera.lensRadius = 0.01
        scene.add(camera)
        
        let gi: PathTracingGIParameter = PathTracingGIParameter()
        gi.samples = 16
        scene.add(gi)
        
        let simple1: DiffuseShaderParameter! = DiffuseShaderParameter("simple1")
        simple1.diffuse = Color(0.5, 0.5, 0.5)
        scene.add(simple1)
        
        let glassy: GlassShaderParameter = GlassShaderParameter("glassy")
        glassy.eta = 1.333
        glassy.color = Color(0.8, 0.8, 0.8)
        glassy.absorptionDistance = 15
        glassy.absorptionColor = Color(0.2, 0.7, 0.2).toNonLinear()
        scene.add(glassy)
        
        let lightParameter: SunSkyLightParameter = SunSkyLightParameter("sunsky")
        lightParameter.up = Vector3(0, 0, 1)
        lightParameter.east = Vector3(0, 1, 0)
        lightParameter.sunDirection = Vector3(-1, 1, 0.2)
        lightParameter.turbidity = 2
        lightParameter.samples = 32
        scene.add(lightParameter)

        let metal: PhongShaderParameter = PhongShaderParameter("metal")
        metal.diffuse = Color(0.1, 0.1, 0.1)
        metal.specular = Color(0.1, 0.1, 0.1)
        metal.samples = 4
        scene.add(metal)
        
        let sphereFlakeParameter: SphereFlakeParameter = SphereFlakeParameter("flake")
        sphereFlakeParameter.shaders(metal)
        sphereFlakeParameter.level = 7
        scene.add(sphereFlakeParameter)
        
        let floor: PlaneParameter = PlaneParameter("plane_0")
        floor.center = Point3(0, 0, -1)
        floor.normal = Vector3(0, 0, 1)
        floor.shaders(simple1)
        scene.add(floor)
        
        return scene
    }

    func previewRender(_ display: Display) {
        API.shared.parameter("sampler", "ipr")
        API.shared.options(API.DEFAULT_OPTIONS)
        API.shared.render(API.DEFAULT_OPTIONS, display)
    }

    func render(_ display: Display) {
        API.shared.parameter("sampler", "fast")
        API.shared.options(API.DEFAULT_OPTIONS)
        API.shared.render(API.DEFAULT_OPTIONS, display)
    }
}
