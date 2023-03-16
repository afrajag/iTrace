//
//  JuliaScene.swift
//  iTrace
//
//  Created by Fabrizio Pezzola on 09/03/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class JuliaScene: SceneBuilder {
    func build() -> SceneParameter? {
        let scene = SceneParameter("Julia")

        let image: ImageParameter = ImageParameter()
        image.resolutionX = 512
        image.resolutionY = 512
        image.aaMin = 0
        image.aaMax = 2
        image.filter = ImageParameter.FILTER_GAUSSIAN
        scene.add(image)

        let traceDepths: TraceDepthsParameter = TraceDepthsParameter()
        traceDepths.diffuse = 1
        traceDepths.reflection = 0
        traceDepths.refraction = 0
        scene.add(traceDepths)
        
        let camera: PinholeCameraParameter = PinholeCameraParameter("camera")
        camera.eye = Point3(-5, 0, 0)
        camera.target = Point3(0, 0, 0)
        camera.up = Vector3(0, 1, 0)
        camera.fov = 58.0
        camera.aspect = 1
        scene.add(camera)
        
        let gi: PathTracingGIParameter = PathTracingGIParameter()
        gi.samples = 16
        scene.add(gi)
        
        let lightParameter: SphereLightParameter = SphereLightParameter("light0")
        lightParameter.radiance = Color(1, 1, 0.600000023841858).toLinear().mul(60)
        lightParameter.center = Point3(-5, 7, 5)
        lightParameter.radius = 2
        lightParameter.numSamples = 8
        scene.add(lightParameter)

        let lightParameter1: SphereLightParameter = SphereLightParameter("light1")
        lightParameter1.radiance = Color(0.600000023841858, 0.600000023841858, 1.0).toLinear().mul(20)
        lightParameter1.center = Point3(-15, -17, -15)
        lightParameter1.radius = 5
        lightParameter1.numSamples = 8
        scene.add(lightParameter1)
        
        let simple1: DiffuseShaderParameter! = DiffuseShaderParameter("simple1")
        simple1.diffuse = Color(0.5, 0.5, 0.5).toLinear()
        scene.add(simple1)
        
        let left: JuliaParameter = JuliaParameter("left")
        left.shaders("simple1")
        left.scale(2)
        left.rotateY(45)
        left.rotateX(-55)
        left.iterations = 8
        left.epsilon = 0.00100000004749745
        left.cx = -0.125
        left.cy = -0.256000012159348
        left.cz = 0.847000002861023
        left.cw = 0.0895000025629997
        scene.add(left)
        
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
