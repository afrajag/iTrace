//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class PluginRegistry {
    static var primitivePlugins = PrimitiveListPlugins()
    static var tesselatablePlugins = TesselatablePlugins()
    static var shaderPlugins = ShaderPlugins()
    static var modifierPlugins = ModifierPlugins()
    static var lightSourcePlugins = LightSourcePlugins()
    static var cameraLensPlugins = CameraLensPlugins()
    static var accelPlugins = AccelerationStructurePlugins()
    static var bucketOrderPlugins = BucketOrderPlugins()
    static var filterPlugins = FilterPlugins()
    static var giEnginePlugins = GIEnginePlugins()
    static var causticPhotonMapPlugins = CausticPhotonMapInterfacePlugins()
    static var globalPhotonMapPlugins = GlobalPhotonMapInterfacePlugins()
    static var imageSamplerPlugins = ImageSamplerPlugins()
    static var parserPlugins = SceneParserPlugins()
    static var bitmapReaderPlugins = BitmapReaderPlugins()
    static var bitmapWriterPlugins = BitmapWriterPlugins()

    // Register all plugins on startup:
    static func initRegistry() {
        //  primitives
        Self.primitivePlugins.registerPlugin("sphere", Sphere.self)
        Self.primitivePlugins.registerPlugin("triangle_mesh", TriangleMesh.self)
        Self.primitivePlugins.registerPlugin("plane", Plane.self)
        Self.primitivePlugins.registerPlugin("quad_mesh", QuadMesh.self)
        Self.primitivePlugins.registerPlugin("background", Background.self)
        Self.primitivePlugins.registerPlugin("cylinder", Cylinder.self)
        Self.primitivePlugins.registerPlugin("box", Box.self)
        Self.primitivePlugins.registerPlugin("ubox", UnitBox.self)
        Self.primitivePlugins.registerPlugin("banchoff", BanchoffSurface.self)
        Self.primitivePlugins.registerPlugin("hair", Hair.self)
        Self.primitivePlugins.registerPlugin("julia", JuliaFractal.self)
        Self.primitivePlugins.registerPlugin("particles", ParticleSurface.self)
        Self.primitivePlugins.registerPlugin("torus", Torus.self)
        Self.primitivePlugins.registerPlugin("sphereflake", SphereFlake.self)
        Self.primitivePlugins.registerPlugin("sponge", MengerSponge.self)

        //  tesselatable
        Self.tesselatablePlugins.registerPlugin("bezier_mesh", BezierMesh.self)
        Self.tesselatablePlugins.registerPlugin("file_mesh", FileMesh.self)
        Self.tesselatablePlugins.registerPlugin("gumbo", Gumbo.self)
        Self.tesselatablePlugins.registerPlugin("teapot", Teapot.self)

        //  shaders
        Self.shaderPlugins.registerPlugin("ambient_occlusion", AmbientOcclusionShader.self)
        Self.shaderPlugins.registerPlugin("ward", AnisotropicWardShader.self)
        Self.shaderPlugins.registerPlugin("constant", ConstantShader.self)
        Self.shaderPlugins.registerPlugin("diffuse", DiffuseShader.self)
        Self.shaderPlugins.registerPlugin("glass", GlassShader.self)
        Self.shaderPlugins.registerPlugin("mirror", MirrorShader.self)
        Self.shaderPlugins.registerPlugin("wireframe", WireframeShader.self)
        Self.shaderPlugins.registerPlugin("shiny_diffuse", ShinyDiffuseShader.self)
        Self.shaderPlugins.registerPlugin("uber", UberShader.self)
        Self.shaderPlugins.registerPlugin("phong", PhongShader.self)
        Self.shaderPlugins.registerPlugin("triangle_mesh", TriangleMeshLight.self)
        
        //  textured shaders
        Self.shaderPlugins.registerPlugin("textured_ambient_occlusion", TexturedAmbientOcclusionShader.self)
        Self.shaderPlugins.registerPlugin("textured_diffuse", TexturedDiffuseShader.self)
        Self.shaderPlugins.registerPlugin("textured_phong", TexturedPhongShader.self)
        Self.shaderPlugins.registerPlugin("textured_shiny_diffuse", TexturedShinyDiffuseShader.self)
        Self.shaderPlugins.registerPlugin("textured_ward", TexturedWardShader.self)
        
        //  preview shaders
        Self.shaderPlugins.registerPlugin("quick_gray", QuickGrayShader.self)
        Self.shaderPlugins.registerPlugin("simple", SimpleShader.self)
        Self.shaderPlugins.registerPlugin("show_normals", NormalShader.self)
        Self.shaderPlugins.registerPlugin("show_uvs", UVShader.self)
        Self.shaderPlugins.registerPlugin("show_instance_id", IDShader.self)
        Self.shaderPlugins.registerPlugin("show_primitive_id", PrimIDShader.self)
        Self.shaderPlugins.registerPlugin("view_caustics", ViewCausticsShader.self)
        Self.shaderPlugins.registerPlugin("view_global", ViewGlobalPhotonsShader.self)
        Self.shaderPlugins.registerPlugin("view_irradiance", ViewIrradianceShader.self)
        
        //  modifiers
        Self.modifierPlugins.registerPlugin("bump_map", BumpMappingModifier.self)
        Self.modifierPlugins.registerPlugin("normal_map", NormalMapModifier.self)
        Self.modifierPlugins.registerPlugin("perlin", PerlinModifier.self)

        //  light sources
        Self.lightSourcePlugins.registerPlugin("directional", DirectionalSpotlight.self)
        Self.lightSourcePlugins.registerPlugin("ibl", ImageBasedLight.self)
        Self.lightSourcePlugins.registerPlugin("point", PointLight.self)
        Self.lightSourcePlugins.registerPlugin("cornell_box", CornellBox.self)
        Self.lightSourcePlugins.registerPlugin("sunsky", SunSkyLight.self)
        Self.lightSourcePlugins.registerPlugin("spherical", SphereLight.self)
        Self.lightSourcePlugins.registerPlugin("triangle_mesh", TriangleMeshLight.self)
        
        //  camera lenses
        Self.cameraLensPlugins.registerPlugin("pinhole", PinholeLens.self)
        Self.cameraLensPlugins.registerPlugin("thinlens", ThinLens.self)
        Self.cameraLensPlugins.registerPlugin("fisheye", FisheyeLens.self)
        Self.cameraLensPlugins.registerPlugin("spherical", SphericalLens.self)
         
        //  accels
        Self.accelPlugins.registerPlugin("bih", BoundingIntervalHierarchy.self)
        Self.accelPlugins.registerPlugin("null", NullAccelerator.self)
        Self.accelPlugins.registerPlugin("kdtree", KDTree.self)
        Self.accelPlugins.registerPlugin("uniformgrid", UniformGrid.self)
        
        //  bucket orders
        Self.bucketOrderPlugins.registerPlugin("column", ColumnBucketOrder.self)
        Self.bucketOrderPlugins.registerPlugin("diagonal", DiagonalBucketOrder.self)
        Self.bucketOrderPlugins.registerPlugin("hilbert", HilbertBucketOrder.self)
        Self.bucketOrderPlugins.registerPlugin("random", RandomBucketOrder.self)
        Self.bucketOrderPlugins.registerPlugin("row", RowBucketOrder.self)
        Self.bucketOrderPlugins.registerPlugin("spiral", SpiralBucketOrder.self)

        //  filters
        Self.filterPlugins.registerPlugin("blackman-harris", BlackmanHarrisFilter.self)
        Self.filterPlugins.registerPlugin("box", BoxFilter.self)
        Self.filterPlugins.registerPlugin("catmull-rom", CatmullRomFilter.self)
        Self.filterPlugins.registerPlugin("gaussian", GaussianFilter.self)
        Self.filterPlugins.registerPlugin("triangle", TriangleFilter.self)
        Self.filterPlugins.registerPlugin("lanczos", LanczosFilter.self)
        Self.filterPlugins.registerPlugin("mitchell", MitchellFilter.self)
        Self.filterPlugins.registerPlugin("sinc", SincFilter.self)
        Self.filterPlugins.registerPlugin("bspline", CubicBSpline.self)

        //  gi engines
        Self.giEnginePlugins.registerPlugin("igi", InstantGI.self)
        Self.giEnginePlugins.registerPlugin("irr-cache", IrradianceCacheGIEngine.self)
        Self.giEnginePlugins.registerPlugin("ambocc", AmbientOcclusionGIEngine.self)
        Self.giEnginePlugins.registerPlugin("fake", FakeGIEngine.self)
        Self.giEnginePlugins.registerPlugin("path", PathTracingGIEngine.self)
        
        //  caustic photon maps
        Self.causticPhotonMapPlugins.registerPlugin("kd", CausticPhotonMap.self)

        //  global photon maps
        Self.globalPhotonMapPlugins.registerPlugin("grid", GridPhotonMap.self)
        Self.globalPhotonMapPlugins.registerPlugin("kd", GlobalPhotonMap.self)
        
        //  image samplers
        Self.imageSamplerPlugins.registerPlugin("fast", SimpleRenderer.self)
        Self.imageSamplerPlugins.registerPlugin("bucket", BucketRenderer.self)
        Self.imageSamplerPlugins.registerPlugin("ipr", ProgressiveRenderer.self)
        Self.imageSamplerPlugins.registerPlugin("multipass", MultipassRenderer.self)
        
        //  parsers
        Self.parserPlugins.registerPlugin("itr", ITRParser.self)
        Self.parserPlugins.registerPlugin("yml", ITRParser.self)
        Self.parserPlugins.registerPlugin("jtr", JTRParser.self)
        
        //  bitmap readers
        Self.bitmapReaderPlugins.registerPlugin("png", PNGBitmapReader.self)
        Self.bitmapReaderPlugins.registerPlugin("PNG", PNGBitmapReader.self)
        Self.bitmapReaderPlugins.registerPlugin("jpg", JPGBitmapReader.self)
        Self.bitmapReaderPlugins.registerPlugin("JPG", JPGBitmapReader.self)
        Self.bitmapReaderPlugins.registerPlugin("gif", GIFBitmapReader.self)
        Self.bitmapReaderPlugins.registerPlugin("GIF", GIFBitmapReader.self)
        Self.bitmapReaderPlugins.registerPlugin("hdr", HDRBitmapReader.self)
        Self.bitmapReaderPlugins.registerPlugin("HDR", HDRBitmapReader.self)
        Self.bitmapReaderPlugins.registerPlugin("tga", TGABitmapReader.self)
        Self.bitmapReaderPlugins.registerPlugin("TGA", TGABitmapReader.self)
        
        //  bitmap writers
        Self.bitmapWriterPlugins.registerPlugin("tga", TGABitmapWriter.self)
        Self.bitmapWriterPlugins.registerPlugin("ppm", PPMBitmapWriter.self)
        Self.bitmapWriterPlugins.registerPlugin("png", PNGBitmapWriter.self)
        Self.bitmapWriterPlugins.registerPlugin("exr", EXRBitmapWriter.self)
        Self.bitmapWriterPlugins.registerPlugin("hdr", HDRBitmapWriter.self)
    }
}
