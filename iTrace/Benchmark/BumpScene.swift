//
//  TestScene.swift
//  iTrace
//
//  Created by Fabrizio Pezzola on 09/03/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

import Yams

final class BumpScene: SceneBuilder {
    func build() -> SceneParameter? {
        let scene = SceneParameter("Bump")

        API.shared.searchpath("texture", "/Users/afrajag/Dropbox/Developing/Raytrace/sunflow_harium_test/examples/")
        // API.shared.searchpath("texture", "/Volumes/DeepBackup/Dropbox/Developing/Raytrace/sunflow_harium_test/examples/")
        API.shared.searchpath("texture", "/Users/afrajag/Desktop/hdr/")

        let image: ImageParameter = ImageParameter()
        image.resolutionX = 800
        image.resolutionY = 450
        image.aaMin = 0
        image.aaMax = 1
        image.aaSamples = 1
        image.filter = ImageParameter.FILTER_TRIANGLE
        scene.add(image)

        let camera: PinholeCameraParameter = PinholeCameraParameter("pinhole")
        camera.eye = Point3(-18.19, 8.97, -0.93)
        camera.target = Point3(-0.690, 0.97, -0.93)
        camera.up = Vector3(0, 1, 0)
        camera.fov = 30.0
        camera.aspect = 1.777777777777
        scene.add(camera)

        /*
          let gi: PathTracingGIParameter = PathTracingGIParameter()
          gi.Samples(32)
          gi.up(api)
         */

        /*
         let gi: AmbientOcclusionGIParameter = AmbientOcclusionGIParameter()
         gi.bright = Color(0.7, 0.7, 0.7)
         gi.dark = Color(0.1, 0.1, 0.1)
         gi.samples = 16
         scene.add(gi)
         */

        let lightParameter: SunSkyLightParameter = SunSkyLightParameter("sunsky")
        lightParameter.up = Vector3(0, 1, 0)
        lightParameter.east = Vector3(0, 0, 1)
        lightParameter.sunDirection = Vector3(-1, 1, -1)
        lightParameter.turbidity = 2
        lightParameter.samples = 32
        scene.add(lightParameter)

        let bumpy01: NormalMapModifierParameter = NormalMapModifierParameter("bumpy_01")
        bumpy01.texture = "textures/brick_normal.jpg"
        scene.add(bumpy01)

        let bumpy02: BumpMapModifierParameter = BumpMapModifierParameter("bumpy_02")
        bumpy02.texture = "textures/dirty_bump.jpg"
        bumpy02.scale = 0.02
        scene.add(bumpy02)

        let bumpy03: BumpMapModifierParameter = BumpMapModifierParameter("bumpy_03")
        bumpy03.texture = "textures/reptileskin_bump.png"
        bumpy03.scale = 0.02
        scene.add(bumpy03)

        let bumpy04: BumpMapModifierParameter = BumpMapModifierParameter("bumpy_04")
        bumpy04.texture = "textures/shiphull_bump.png"
        bumpy04.scale = 0.15
        scene.add(bumpy04)

        let bumpy05: BumpMapModifierParameter = BumpMapModifierParameter("bumpy_05")
        bumpy05.texture = "textures/slime_bump.jpg"
        bumpy05.scale = 0.15
        scene.add(bumpy05)

        let shiny: ShinyShaderParameter = ShinyShaderParameter("default")
        shiny.diffuse = Color(0.2, 0.2, 0.2)
        shiny.shininess = 0.3
        scene.add(shiny)

        let glassy: GlassShaderParameter = GlassShaderParameter("glassy")
        glassy.eta = 1.2
        glassy.color = Color(0.8, 0.8, 0.8)
        glassy.absorptionDistance = 7
        glassy.absorptionColor = Color(0.2, 0.7, 0.2).toLinear()
        scene.add(glassy)

        let simpleRed: DiffuseShaderParameter = DiffuseShaderParameter("simple_red")
        simpleRed.diffuse = Color(0.7, 0.15, 0.15).toLinear()
        scene.add(simpleRed)

        let simpleGreen: DiffuseShaderParameter = DiffuseShaderParameter("simple_green")
        simpleGreen.diffuse = Color(0.15, 0.7, 0.15).toLinear()
        scene.add(simpleGreen)

        let simpleYellow: DiffuseShaderParameter = DiffuseShaderParameter("simple_yellow")
        simpleYellow.diffuse = Color(0.8, 0.8, 0.2).toLinear()
        scene.add(simpleYellow)

        let floorShader: DiffuseShaderParameter = DiffuseShaderParameter("floor")
        // floorShader.Diffuse(Color(0.3, 0.3, 0.3))
        floorShader.texture = "textures/brick_color.jpg"
        // floorShader.texture = "envmap.hdr"
        scene.add(floorShader)

        let floor: PlaneParameter = PlaneParameter("plane_0")
        floor.center = Point3(0, 0, 0)
        floor.point1 = Point3(4, 0, 3)
        floor.point2 = Point3(-3, 0, 4)
        floor.shaders(floorShader)
        floor.modifiers(bumpy01)
        scene.add(floor)

        let teapot0: TeapotParameter = TeapotParameter("teapot_0")
        teapot0.subdivs = 20
        teapot0.shaders(simpleGreen)
        teapot0.modifiers(bumpy03)
        teapot0.rotateX(-90)
        teapot0.scale(0.018)
        teapot0.rotateY(245.0)
        teapot0.translate(1.5, 0, -1)
        scene.add(teapot0)
        /*
         let sphere0: SphereParameter = SphereParameter("sphere_0")
         sphere0.shaders(glassy)
         sphere0.rotateX(35)
         sphere0.scale(1.5)
         sphere0.rotateY(245)
         sphere0.translate(1.5, 1.5, 3)
         scene.add(sphere0)

         let sphere1: SphereParameter = SphereParameter("sphere_1")
         sphere1.shaders(shiny)
         sphere1.modifiers(bumpy05)
         sphere1.rotateX(35)
         sphere1.scale(1.5)
         sphere1.rotateY(245)
         sphere1.translate(1.5, 1.5, -5)
         scene.add(sphere1)

         let teapot1: TeapotParameter = TeapotParameter("teapot_1")
         teapot1.geometry(teapot0)
         teapot1.rotateX(-90)
         teapot1.scale(0.018)
         teapot1.rotateY(245.0)
         teapot1.translate(-1.5, 0, -3)
         teapot1.shaders(simpleYellow)
         teapot1.modifiers(bumpy04)
         scene.add(teapot1)

         let teapot3: TeapotParameter = TeapotParameter("teapot_3")
         teapot3.geometry(teapot0)
         teapot3.shaders(simpleRed)
         teapot3.modifiers(bumpy02)
         teapot3.rotateX(-90)
         teapot3.scale(0.018)
         teapot3.rotateY(245.0)
         teapot3.translate(-1.5, 0, 1)
         scene.add(teapot3)
         */
        // let encoder = YAMLEncoder()
        // let encodedYAML = try! encoder.encode(scene)
        // print(encodedYAML)

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
