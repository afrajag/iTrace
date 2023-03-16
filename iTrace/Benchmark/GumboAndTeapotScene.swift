//
//  TestScene.swift
//  iTrace
//
//  Created by Fabrizio Pezzola on 09/03/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class GumboAndTeapotScene: SceneBuilder {
    func build() -> SceneParameter? {
        let scene = SceneParameter("GumboAndTeapot")
        
        let image: ImageParameter = ImageParameter()
        image.resolutionX = 800
        image.resolutionY = 450
        image.aaMin = 0
        image.aaMax = 1
        image.filter = ImageParameter.FILTER_TRIANGLE
        scene.add(image)
    
        /*
        let gi: InstantGIParameter = InstantGIParameter()
        gi.samples = 64
        gi.sets = 1
        gi.bias = 0.00003
        gi.biasSamples = 0
        scene.add(gi)
        */
        
        let camera: PinholeCameraParameter = PinholeCameraParameter("pinhole")
        camera.eye = Point3(-18.19, 8.97, -0.93)
        camera.target = Point3(-0.690, 0.97, -0.93)
        camera.up = Vector3(0, 1, 0)
        camera.fov = 30.0
        camera.aspect = 1.777777777777
        scene.add(camera)
        
        let lightParameter: SunSkyLightParameter = SunSkyLightParameter("sunsky")
        lightParameter.up = Vector3(0, 1, 0)
        lightParameter.east = Vector3(0, 0, 1)
        lightParameter.sunDirection = Vector3(1, 1, 1)
        lightParameter.turbidity = 4
        lightParameter.samples = 64
        scene.add(lightParameter)
        
        //  Materials
        let shiny: ShinyShaderParameter = ShinyShaderParameter("default")
        shiny.diffuse = Color(0.2, 0.2, 0.2)
        shiny.shininess = 0.1
        scene.add(shiny)
        
        let simple: DiffuseShaderParameter = DiffuseShaderParameter("simple")
        simple.diffuse = Color(0.2, 0.2, 0.2)
        scene.add(simple)
        
        let simpleRed: DiffuseShaderParameter = DiffuseShaderParameter("simple_red")
        simpleRed.diffuse = Color(0.8, 0.2, 0.2).toLinear()
        scene.add(simpleRed)
        
        let simpleGreen: DiffuseShaderParameter = DiffuseShaderParameter("simple_green")
        simpleGreen.diffuse = Color(0.2, 0.8, 0.2).toLinear()
        scene.add(simpleGreen)
        
        let simpleBlue: DiffuseShaderParameter = DiffuseShaderParameter("simple_blue")
        simpleBlue.diffuse = Color(0.2, 0.2, 0.8).toLinear()
        scene.add(simpleBlue)
        
        let simpleYellow: DiffuseShaderParameter = DiffuseShaderParameter("simple_yellow")
        simpleYellow.diffuse = Color(0.8, 0.8, 0.2).toLinear()
        scene.add(simpleYellow)
        
        let floorShader: DiffuseShaderParameter = DiffuseShaderParameter("floor")
        floorShader.diffuse = Color(0.1, 0.1, 0.1)
        scene.add(floorShader)
        
        let gumbo0: GumboParameter = GumboParameter("gumbo_0")
        gumbo0.subdivs = 7
        gumbo0.shaders(shiny)
        gumbo0.rotateX(-90)
        gumbo0.scale(0.1)
        gumbo0.rotateY(75)
        gumbo0.translate(-0.25, 0, 0.63)
        scene.add(gumbo0)
        
        let gumbo1: GumboParameter = GumboParameter("gumbo_1")
        gumbo1.subdivs = 4
        gumbo1.smooth = false
        gumbo1.shaders(simpleRed)
        gumbo1.rotateX(-90)
        gumbo1.scale(0.1)
        gumbo1.rotateY(25)
        gumbo1.translate(1.5, 0, -1.5)
        scene.add(gumbo1)
        
        let gumbo2: GumboParameter = GumboParameter("gumbo_2")
        gumbo2.subdivs = 3
        gumbo2.smooth = false
        gumbo2.shaders(simpleBlue)
        gumbo2.rotateX(-90)
        gumbo2.scale(0.1)
        gumbo2.rotateY(25)
        gumbo2.translate(0, 0, -3.0)
        scene.add(gumbo2)
        
        let gumbo3: GumboParameter = GumboParameter("gumbo_3")
        gumbo3.subdivs = 6
        gumbo3.smooth = false
        gumbo3.shaders(simpleGreen)
        gumbo3.rotateX(-90)
        gumbo3.scale(0.1)
        gumbo3.rotateY(-25)
        gumbo3.translate(1.5, 0, 1.5)
        scene.add(gumbo3)
        
        let gumbo4: GumboParameter = GumboParameter("gumbo_4")
        gumbo4.subdivs = 8
        gumbo4.smooth = false
        gumbo4.shaders(simpleYellow)
        gumbo4.rotateX(-90)
        gumbo4.scale(0.1)
        gumbo4.rotateY(-25)
        gumbo4.translate(0.0, 0, 3.0)
        scene.add(gumbo4)
        
        let floor: PlaneParameter = PlaneParameter("plane_0")
        floor.center = Point3(0, 0, 0)
        floor.normal = Vector3(0, 1, 0)
        floor.shaders(floorShader)
        scene.add(floor)
        
        let teapot0: TeapotParameter = TeapotParameter("teapot_0")
        teapot0.subdivs = 7
        teapot0.shaders(shiny)
        teapot0.rotateX(-90)
        teapot0.scale(0.008)
        teapot0.rotateY(245.0)
        teapot0.translate(-3, 0, -1)
        scene.add(teapot0)
        
        let teapot1: TeapotParameter = TeapotParameter("teapot_1")
        teapot1.subdivs = 4
        teapot1.smooth = false
        teapot1.shaders(simpleYellow)
        teapot1.rotateX(-90)
        teapot1.scale(0.008)
        teapot1.rotateY(245.0)
        teapot1.translate(-1.5, 0, -3)
        scene.add(teapot1)
        
        let teapot2: TeapotParameter = TeapotParameter("teapot_2")
        teapot2.subdivs = 3
        teapot2.smooth = false
        teapot2.shaders(simpleGreen)
        teapot2.rotateX(-90)
        teapot2.scale(0.008)
        teapot2.rotateY(245.0)
        teapot2.translate(0, 0, -5)
        scene.add(teapot2)
        
        let teapot3: TeapotParameter = TeapotParameter("teapot_3")
        teapot3.subdivs = 5
        teapot3.smooth = false
        teapot3.shaders(simpleRed)
        teapot3.rotateX(-90)
        teapot3.scale(0.008)
        teapot3.rotateY(245.0)
        teapot3.translate(-1.5, 0, 1)
        scene.add(teapot3)
        
        let teapot4: TeapotParameter = TeapotParameter("teapot_4")
        teapot4.subdivs = 7
        teapot4.smooth = false
        teapot4.shaders(simpleBlue)
        teapot4.rotateX(-90)
        teapot4.scale(0.008)
        teapot4.rotateY(245.0)
        teapot4.translate(0, 0, 3)
        scene.add(teapot4)
        
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
