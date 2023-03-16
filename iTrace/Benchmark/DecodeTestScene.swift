//
//  TestScene.swift
//  iTrace
//
//  Created by Fabrizio Pezzola on 09/03/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

import Foundation

final class DecodeTestScene: SceneBuilder {
    func build() -> SceneParameter? {
        let scene = SceneParameter("DecodeTestScene")
        
        let _ = """
        {
          "name" : "TestScene",
          "parameters" : [
            {
              "type" : "image",
              "values" : {
                "aaMax" : 2,
                "aaJitter" : false,
                "resolutionX" : 640,
                "aaCache" : false,
                "sampler" : "",
                "filter" : "gaussian",
                "aaContrast" : 0,
                "aaMin" : 0,
                "resolutionY" : 480,
                "aaSamples" : 4
              }
            },
            {
              "type" : "tracedepths",
              "values" : {
                "diffuse" : 4,
                "reflection" : 3,
                "refraction" : 2
              }
            },
            {
              "type" : "ambient_occlusion_gi",
              "values" : {
                "dark" : {
                  "r" : 0.10000000149011612,
                  "g" : 0.10000000149011612,
                  "b" : 0.10000000149011612
                },
                "samples" : 16,
                "maxDist" : 0,
                "bright" : {
                  "r" : 0.69999998807907104,
                  "g" : 0.69999998807907104,
                  "b" : 0.69999998807907104
                }
              }
            },
            {
              "type" : "pinhole",
              "values" : {
                "aspect" : 1.3333330154418945,
                "name" : "pinhole",
                "target" : {
                  "x" : 0,
                  "y" : 0,
                  "z" : 0
                },
                "up" : {
                  "x" : 0,
                  "y" : 1,
                  "z" : 0
                },
                "shiftX" : 0,
                "shiftY" : 0,
                "fov" : 40,
                "shutterClose" : 0,
                "eye" : {
                  "x" : 13,
                  "y" : 3,
                  "z" : 3
                },
                "shutterOpen" : 0
              }
            },
            {
              "type" : "point_light",
              "values" : {
                "name" : "pointlight",
                "center" : {
                  "x" : 0,
                  "y" : 2,
                  "z" : 0
                },
                "power" : {
                  "r" : 100,
                  "g" : 100,
                  "b" : 100
                }
              }
            },
            {
              "type" : "sunsky",
              "values" : {
                "up" : {
                  "x" : 0,
                  "y" : 1,
                  "z" : 0
                },
                "samples" : 32,
                "groundColor" : null,
                "sunDirection" : {
                  "x" : -1,
                  "y" : 1,
                  "z" : -1
                },
                "turbidity" : 2,
                "east" : {
                  "x" : 0,
                  "y" : 0,
                  "z" : 1
                },
                "extendSky" : false,
                "name" : "sunsky"
              }
            },
            {
              "type" : "normal_map",
              "values" : {
                "name" : "bumpy_01",
                "texture" : "textures/brick_normal.jpg"
              }
            },
            {
              "type" : "mirror_shader",
              "values" : {
                "name" : "Mirror",
                "reflection" : {
                  "r" : 0.69999998807907104,
                  "g" : 0.69999998807907104,
                  "b" : 0.69999998807907104
                }
              }
            },
            {
              "type" : "glass_shader",
              "values" : {
                "eta" : 1.6000000238418579,
                "absorptionDistance" : 0,
                "absorptionColor" : {
                  "r" : 1,
                  "g" : 1,
                  "b" : 1
                },
                "name" : "Glass",
                "color" : {
                  "r" : 1,
                  "g" : 1,
                  "b" : 1
                }
              }
            },
            {
              "type" : "diffuse_shader",
              "values" : {
                "name" : "Diffuse",
                "texture" : "textures/brick_normal.jpg",
                "diffuse" : {
                  "r" : 1,
                  "g" : 1,
                  "b" : 1
                }
              }
            },
            {
              "type" : "diffuse_shader",
              "values" : {
                "name" : "Diffuse-ground",
                "texture" : "",
                "diffuse" : {
                  "r" : 0.69999998807907104,
                  "g" : 0.69999998807907104,
                  "b" : 0.69999998807907104
                }
              }
            },
            {
              "type" : "plane",
              "values" : {
                "center" : {
                  "x" : 0,
                  "y" : 0,
                  "z" : 0
                },
                "point1" : null,
                "point2" : null,
                "normal" : {
                  "x" : 0,
                  "y" : 1,
                  "z" : 0
                },
                "instance" : {
                  "name" : "ground.instance",
                  "geometry" : "ground",
                  "shaders" : [
                    "bumpy_01"
                  ]
                },
                "accel" : "",
                "name" : "ground"
              }
            },
            {
              "type" : "sphere",
              "values" : {
                "center" : {
                  "x" : 0,
                  "y" : 1,
                  "z" : 0
                },
                "radius" : 1,
                "instance" : {
                  "shaders" : [
                    "Glass"
                  ]
                },
                "name" : "glass-sphere",
                "accel" : ""
              }
            },
            {
              "type" : "sphere",
              "values" : {
                "center" : {
                  "x" : 4,
                  "y" : 1,
                  "z" : 0
                },
                "radius" : 1,
                "instance" : {
                  "shaders" : [
                    "Diffuse"
                  ]
                },
                "name" : "mirror-sphere",
                "accel" : ""
              }
            },
            {
              "type" : "sphere",
              "values" : {
                "center" : {
                  "x" : -4,
                  "y" : 1,
                  "z" : 0
                },
                "radius" : 1,
                "instance" : {
                  "shaders" : [
                    "Mirror"
                  ]
                },
                "name" : "diffuse-sphere",
                "accel" : ""
              }
            }
          ]
        }
        """.data(using: .utf8)!
        
        //scene.decode(json)
        
        API.shared.searchpath("texture", "/Users/afrajag/Desktop/")
        API.shared.searchpath("texture", "/Users/afrajag/Dropbox/Developing/Raytrace/sunflow_harium_test/examples/")

        
        let image: ImageParameter = ImageParameter()
        image.resolutionX = 640
        image.resolutionY = 480
        image.aaMin = 0
        image.aaMax = 2
        image.filter = ImageParameter.FILTER_GAUSSIAN
        scene.add(image)
        
        let traceDepths: TraceDepthsParameter = TraceDepthsParameter()
        traceDepths.diffuse = 4
        traceDepths.reflection = 3
        traceDepths.refraction = 2
        scene.add(traceDepths)

        /*
         let gi: PathTracingGIParameter = PathTracingGIParameter()
         gi.Samples(32)
         gi.up(api)
         scene.add(gi)
         */

        /*
         let gi: FakeGIParameter = FakeGIParameter()
         gi.Sky(Color.CYAN)
         gi.Ground(Color.YELLOW)
         gi.Up(Vector3(0,0,1))
         gi.up(api)
         scene.add(gi)
         */

        let gi: AmbientOcclusionGIParameter = AmbientOcclusionGIParameter()
        gi.bright = Color(0.7, 0.7, 0.7)
        gi.dark = Color(0.1, 0.1, 0.1)
        gi.samples = 16
        scene.add(gi)

        let camera: PinholeCameraParameter = PinholeCameraParameter("pinhole")
        camera.eye = Point3(13, 3, 3)
        camera.target = Point3(0, 0, 0)
        camera.up = Vector3(0, 1, 0)
        camera.fov = 40.0
        camera.aspect = 1.333333
        scene.add(camera)

        // Lights
        
        let lightParameter: PointLightParameter = PointLightParameter("pointlight")
        lightParameter.lightPoint = Point3(0,2,0)
        lightParameter.power = Color(100,100,100)
        lightParameter.setup()
        scene.add(lightParameter)

        // Fake light
        /*
         let constant: ConstantShaderParameter = ConstantShaderParameter("Constant")
         constant.Color(Color(2,2,2))
         constant.up(api)

         let fakeLight: SphereParameter = SphereParameter()
         fakeLight.Name("fake-light")
         fakeLight.Center(Point3(0,20,0))
         fakeLight.shaders("Constant")
         fakeLight.Radius(10)
         fakeLight.up(api)
         scene.add(sunlightParameter)
         */

        
        let sunlightParameter: SunSkyLightParameter = SunSkyLightParameter("sunsky")
        sunlightParameter.up = Vector3(0, 1, 0)
        sunlightParameter.east = Vector3(0, 0, 1)
        sunlightParameter.sunDirection = Vector3(-1, 1, -1)
        sunlightParameter.turbidity = 2
        sunlightParameter.samples = 32
        scene.add(sunlightParameter)
        
        // Background
        let background: BackgroundParameter = BackgroundParameter()
        background.color = Color(0.6, 0.6, 1)
        // background.up(api)

        // Materials
        let bumpy01: NormalMapModifierParameter = NormalMapModifierParameter("bumpy_01")
        bumpy01.texture = "textures/brick_normal.jpg"
        scene.add(bumpy01)

        let mirror: MirrorShaderParameter = MirrorShaderParameter("Mirror")
        mirror.color = Color(0.7, 0.7, 0.7)
        scene.add(mirror)

        let glass: GlassShaderParameter = GlassShaderParameter("Glass")
        glass.eta = 1.6
        glass.absorptionColor = Color(1, 1, 1)
        scene.add(glass)

        let diffuse: DiffuseShaderParameter = DiffuseShaderParameter("Diffuse")
        // diffuse.diffuse = Color(0.4, 0.2, 0.1)
        diffuse.texture = "textures/brick_normal.jpg"
        scene.add(diffuse)

        let diffuseGround: DiffuseShaderParameter = DiffuseShaderParameter("Diffuse-ground")
        diffuseGround.diffuse = Color(0.7, 0.7, 0.7)
        scene.add(diffuseGround)

        // Primitives
        // ground
        let ground: PlaneParameter = PlaneParameter("ground")
        ground.center = Point3(0, 0, 0)
        ground.normal = Vector3(0, 1, 0)
        ground.shaders("Diffuse")
        ground.modifiers("bumpy_01")
        scene.add(ground)

        // Fixed spheres
        let glassSphere: SphereParameter = SphereParameter("glass-sphere")
        glassSphere.center = Point3(-0, 1, 0)
        glassSphere.shaders("Glass")
        glassSphere.radius = 1
        scene.add(glassSphere)

        let mirrorSphere: SphereParameter = SphereParameter("mirror-sphere")
        mirrorSphere.center = Point3(4, 1, 0)
        mirrorSphere.shaders("Diffuse")
        mirrorSphere.radius = 1
        scene.add(mirrorSphere)

        let diffuseSphere: SphereParameter = SphereParameter("diffuse-sphere")
        diffuseSphere.center = Point3(-4, 1, 0)
        diffuseSphere.shaders("Mirror")
        diffuseSphere.radius = 1
        scene.add(diffuseSphere)
        
        /*
        // Random spheres
        for a in -7 ..< 7 {
            for b in -7 ..< 7 {
                let choose_mat: Double = Double.random(in: 0 ..< 1)

                let center = Point3(Float(a) + 0.9 * Float.random(in: 0 ..< 1), 0.2, Float(b) + 0.9 * Float.random(in: 0 ..< 1))

                if center.distanceTo(Point3(4, 0.2, 0)) > 0.9 {
                    if choose_mat < 0.8 {
                        // diffuse
                        let diffuseRandom: DiffuseShaderParameter = DiffuseShaderParameter("Diffuse-\(a)-\(b)")
                        diffuseRandom.diffuse = Color(Float.random(in: 0 ..< 1) * Float.random(in: 0 ..< 1), Float.random(in: 0 ..< 1) * Float.random(in: 0 ..< 1), Float.random(in: 0 ..< 1) * Float.random(in: 0 ..< 1))
                        scene.add(diffuseRandom)

                        let diffuseRandomSphere: SphereParameter = SphereParameter("diffuse-sphere-\(a)-\(b)")
                        diffuseRandomSphere.center = center
                        diffuseRandomSphere.shaders("Diffuse-\(a)-\(b)")
                        diffuseRandomSphere.radius = 0.2
                        scene.add(diffuseRandomSphere)
                    } else if choose_mat < 0.95 {
                        // metal
                        let metalRandomSphere: SphereParameter = SphereParameter("metal-sphere-\(a)-\(b)")
                        metalRandomSphere.center = center
                        metalRandomSphere.shaders("Mirror")
                        metalRandomSphere.radius = 0.2
                        scene.add(metalRandomSphere)
                    } else {
                        // glass
                        let glassRandomSphere: SphereParameter = SphereParameter("glass-sphere-\(a)-\(b)")
                        glassRandomSphere.center = center
                        glassRandomSphere.shaders("Glass")
                        glassRandomSphere.radius = 0.2
                        scene.add(glassRandomSphere)
                    }
                }
            }
        }
        */
        
        //scene.decode(scene.encode().data(using: .utf8)!)
        
        //print(scene.encode())
        
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
