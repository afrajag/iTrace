//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class CornellBoxJensenScene: SceneBuilder {
    func build() -> SceneParameter? {
        let scene = SceneParameter("CornellBoxJensen")
        
        let image: ImageParameter = ImageParameter()
        image.resolutionX = 800
        image.resolutionY = 600
        image.aaMin = 0
        image.aaMax = 2
        image.filter = ImageParameter.FILTER_GAUSSIAN
        scene.add(image)
        
        let traceDepths: TraceDepthsParameter = TraceDepthsParameter()
        traceDepths.diffuse = 4
        traceDepths.reflection = 3
        traceDepths.refraction = 2
        scene.add(traceDepths)

        let illum: IlluminationParameter = IlluminationParameter()
        illum.emit = 1_000_000
        illum.map = "kd"
        illum.gather = 100
        illum.radius = 0.5
        
        let photons: PhotonParameter = PhotonParameter()
        photons.caustics = illum
        scene.add(photons)

        let path: PathTracingGIParameter = PathTracingGIParameter()
        path.samples = 100
        scene.add(path)
        
        /*
        let gi: InstantGIParameter = InstantGIParameter()
        gi.samples = 64
        gi.sets = 1
        gi.bias = 0.00003
        gi.biasSamples = 0
        scene.add(gi)
        */
        
        let camera: PinholeCameraParameter = PinholeCameraParameter("pinhole")
        camera.eye = Point3(0, -205, 50)
        camera.target = Point3(0, 0, 50)
        camera.up = Vector3(0, 0, 1)
        camera.fov = 45.0
        camera.aspect = 1.333333
        scene.add(camera)

        //  Materials
        let mirror: MirrorShaderParameter = MirrorShaderParameter("Mirror")
        mirror.color = Color(0.7, 0.7, 0.7)
        scene.add(mirror)

        let glass: GlassShaderParameter = GlassShaderParameter("Glass")
        glass.eta = 1.6
        glass.absorptionColor = Color(1, 1, 1)
        scene.add(glass)

        //  Lights
        let lightParameter: CornellBoxLightParameter = CornellBoxLightParameter("cornell-box-light")
        lightParameter.min = Point3(-60, -60, 0)
        lightParameter.max = Point3(60, 60, 100)
        lightParameter.left = Color(0.8, 0.25, 0.25)
        lightParameter.right = Color(0.25, 0.25, 0.8)
        lightParameter.top = Color(0.7, 0.7, 0.7)
        lightParameter.bottom = Color(0.7, 0.7, 0.7)
        lightParameter.back = Color(0.7, 0.7, 0.7)
        lightParameter.radiance = Color(15, 15, 15)
        lightParameter.samples = 32
        scene.add(lightParameter)

        let mirrorSphere: SphereParameter = SphereParameter("mirror-sphere")
        mirrorSphere.center = Point3(-30, 30, 20)
        mirrorSphere.radius = 20
        mirrorSphere.shaders("Mirror")
        scene.add(mirrorSphere)

        let glassSphere: SphereParameter = SphereParameter("glass-sphere")
        glassSphere.center = Point3(28, 2, 20)
        glassSphere.radius = 20
        glassSphere.shaders("Glass")
        scene.add(glassSphere)
        
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
}
