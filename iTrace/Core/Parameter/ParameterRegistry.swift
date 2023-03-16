//
//  ParameterRegistry.swift
//  iTrace
//
//  Created by Fabrizio Pezzola on 23/03/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

struct CodableParameter: Codable {
    let type: ParameterType
    let values: Any?
    
    // MARK: Codable
    
    enum CodingKeys: String, CodingKey {
        case type
        case values
    }
    
    init(_ type: ParameterType, _ values: Any) {
        self.type = type
        self.values = values
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(ParameterType.self, forKey: .type)
        
        if let decode = ParameterRegistry.decoders[type] {
            values = try decode(container)
        } else {
            values = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(type, forKey: .type)
        
        if let payload = values {
            guard let encode = ParameterRegistry.encoders[type] else {
                let context = EncodingError.Context(codingPath: [], debugDescription: "Unknown object: \(type)")
                throw EncodingError.invalidValue(self, context)
            }
            
            try encode(payload, &container)
        } else {
            try container.encodeNil(forKey: .values)
        }
    }
}

struct ParameterRegistry {
    // MARK: Registration
    
    typealias ParameterDecoder = (KeyedDecodingContainer<CodableParameter.CodingKeys>) throws -> Any
    typealias ParameterEncoder = (Any, inout KeyedEncodingContainer<CodableParameter.CodingKeys>) throws -> Void
    
    static var decoders: [ParameterType: ParameterDecoder] = [:]
    static var encoders: [ParameterType: ParameterEncoder] = [:]
    
    static func register<A: Codable>(_ type: A.Type, for typeName: ParameterType) {
        decoders[typeName] = { container in
            try container.decode(A.self, forKey: .values)
        }
        
        encoders[typeName] = { payload, container in
            try container.encode(payload as! A, forKey: .values)
        }
    }
    
    static func initRegistry() {
        // scene parameters
        ParameterRegistry.register(BackgroundParameter.self, for: .TYPE_BACKGROUND)
        ParameterRegistry.register(BucketParameter.self, for: .TYPE_BUCKET)
        ParameterRegistry.register(IlluminationParameter.self, for: .TYPE_ILLUMINATION)
        ParameterRegistry.register(ImageParameter.self, for: .TYPE_IMAGE)
        ParameterRegistry.register(InstanceParameter.self, for: .TYPE_INSTANCE)
        ParameterRegistry.register(OverrideParameter.self, for: .TYPE_OVERRIDE)
        ParameterRegistry.register(PhotonParameter.self, for: .TYPE_PHOTON)
        ParameterRegistry.register(TraceDepthsParameter.self, for: .TYPE_TRACE_DEPTHS)
        ParameterRegistry.register(TransformParameter.self, for: .TYPE_TRANSFORM)
        
        // camera parameters
        ParameterRegistry.register(FishEyeCameraParameter.self, for: .TYPE_FISH_EYE)
        ParameterRegistry.register(PinholeCameraParameter.self, for: .TYPE_PINHOLE)
        ParameterRegistry.register(SphericalCameraParameter.self, for: .TYPE_SPHERICAL)
        ParameterRegistry.register(ThinLensCameraParameter.self, for: .TYPE_THINLENS)
        
        // object parameters
        ParameterRegistry.register(BanchOffParameter.self, for: .TYPE_BANCHOFF)
        ParameterRegistry.register(BezierMeshParameter.self, for: .TYPE_BEZIER_MESH)
        ParameterRegistry.register(BoxParameter.self, for: .TYPE_BOX)
        ParameterRegistry.register(CylinderParameter.self, for: .TYPE_CYLINDER)
        ParameterRegistry.register(FileMeshParameter.self, for: .TYPE_FILE_MESH)
        ParameterRegistry.register(GenericMeshParameter.self, for: .TYPE_GENERIC_MESH)
        ParameterRegistry.register(TriangleMeshParameter.self, for: .TYPE_TRIANGLE_MESH)
        ParameterRegistry.register(GumboParameter.self, for: .TYPE_GUMBO)
        ParameterRegistry.register(HairParameter.self, for: .TYPE_HAIR)
        ParameterRegistry.register(JuliaParameter.self, for: .TYPE_JULIA)
        ParameterRegistry.register(ParticlesParameter.self, for: .TYPE_PARTICLES)
        ParameterRegistry.register(PlaneParameter.self, for: .TYPE_PLANE)
        ParameterRegistry.register(SphereFlakeParameter.self, for: .TYPE_SPHEREFLAKE)
        ParameterRegistry.register(SphereParameter.self, for: .TYPE_SPHERE)
        ParameterRegistry.register(TeapotParameter.self, for: .TYPE_TEAPOT)
        ParameterRegistry.register(TorusParameter.self, for: .TYPE_TORUS)
        
        // gi parameters
        ParameterRegistry.register(AmbientOcclusionGIParameter.self, for: .TYPE_AMBIENT_OCCLUSION_GI)
        ParameterRegistry.register(FakeGIParameter.self, for: .TYPE_FAKE_GI)
        ParameterRegistry.register(InstantGIParameter.self, for: .TYPE_INSTANT_GI)
        ParameterRegistry.register(IrrCacheGIParameter.self, for: .TYPE_IRRADIANCE_CACHE_GI)
        ParameterRegistry.register(PathTracingGIParameter.self, for: .TYPE_PATH_TRACING_GI)
        
        // light parameters
        ParameterRegistry.register(CornellBoxLightParameter.self, for: .TYPE_CORNELL_BOX)
        ParameterRegistry.register(DirectionalLightParameter.self, for: .TYPE_DIRECTIONAL_LIGHT)
        ParameterRegistry.register(ImageBasedLightParameter.self, for: .TYPE_IMAGE_BASED_LIGHT)
        ParameterRegistry.register(PointLightParameter.self, for: .TYPE_POINT_LIGHT)
        ParameterRegistry.register(SphereLightParameter.self, for: .TYPE_SPHERE_LIGHT)
        ParameterRegistry.register(SunSkyLightParameter.self, for: .TYPE_SUNSKY)
        ParameterRegistry.register(TriangleMeshLightParameter.self, for: .TYPE_TRIANGLE_MESH_LIGHT)
        
        // modifier parameters
        ParameterRegistry.register(BumpMapModifierParameter.self, for: .TYPE_BUMP_MAP)
        ParameterRegistry.register(NormalMapModifierParameter.self, for: .TYPE_NORMAL_MAP)
        ParameterRegistry.register(PerlinModifierParameter.self, for: .TYPE_PERLIN)
        
        // shader parameters
        ParameterRegistry.register(AmbientOcclusionShaderParameter.self, for: .TYPE_AMBIENT_OCCLUSION)
        ParameterRegistry.register(ConstantShaderParameter.self, for: .TYPE_CONSTANT)
        ParameterRegistry.register(DiffuseShaderParameter.self, for: .TYPE_DIFFUSE)
        ParameterRegistry.register(GlassShaderParameter.self, for: .TYPE_GLASS)
        ParameterRegistry.register(MirrorShaderParameter.self, for: .TYPE_MIRROR)
        ParameterRegistry.register(PhongShaderParameter.self, for: .TYPE_PHONG)
        ParameterRegistry.register(ShinyShaderParameter.self, for: .TYPE_SHINY_DIFFUSE)
        ParameterRegistry.register(UberShaderParameter.self, for: .TYPE_UBER)
        ParameterRegistry.register(WardShaderParameter.self, for: .TYPE_WARD)
        ParameterRegistry.register(WireframeShaderParameter.self, for: .TYPE_WIREFRAME)
    }
    
    static func getParameter(_ param: CodableParameter) -> Any? {
        switch param.type {
            // scene parameters
            case .TYPE_BACKGROUND   : return param.values as! BackgroundParameter
            case .TYPE_BUCKET       : return param.values as! BucketParameter
            case .TYPE_ILLUMINATION : return param.values as! IlluminationParameter
            case .TYPE_IMAGE        : return param.values as! ImageParameter
            case .TYPE_INSTANCE     : return param.values as! InstanceParameter
            case .TYPE_OVERRIDE     : return param.values as! OverrideParameter
            case .TYPE_PHOTON       : return param.values as! PhotonParameter
            case .TYPE_TRACE_DEPTHS : return param.values as! TraceDepthsParameter
            case .TYPE_TRANSFORM    : return param.values as! TransformParameter
            
            // camera parameters
            case .TYPE_FISH_EYE  : return param.values as! FishEyeCameraParameter
            case .TYPE_PINHOLE   : return param.values as! PinholeCameraParameter
            case .TYPE_SPHERICAL : return param.values as! SphericalCameraParameter
            case .TYPE_THINLENS  : return param.values as! ThinLensCameraParameter
            
            // object parameters
            case .TYPE_BANCHOFF      : return param.values as! BanchOffParameter
            case .TYPE_BEZIER_MESH   : return param.values as! BezierMeshParameter
            case .TYPE_BOX           : return param.values as! BoxParameter
            case .TYPE_CYLINDER      : return param.values as! CylinderParameter
            case .TYPE_FILE_MESH     : return param.values as! FileMeshParameter
            case .TYPE_GENERIC_MESH  : return param.values as! GenericMeshParameter
            case .TYPE_TRIANGLE_MESH : return param.values as! TriangleMeshParameter
            case .TYPE_GUMBO         : return param.values as! GumboParameter
            case .TYPE_HAIR          : return param.values as! HairParameter
            case .TYPE_JULIA         : return param.values as! JuliaParameter
            case .TYPE_PARTICLES     : return param.values as! ParticlesParameter
            case .TYPE_PLANE         : return param.values as! PlaneParameter
            case .TYPE_SPHEREFLAKE   : return param.values as! SphereFlakeParameter
            case .TYPE_SPHERE        : return param.values as! SphereParameter
            case .TYPE_TEAPOT        : return param.values as! TeapotParameter
            case .TYPE_TORUS         : return param.values as! TorusParameter
            
            // gi parameters
            case .TYPE_AMBIENT_OCCLUSION_GI : return param.values as! AmbientOcclusionGIParameter
            case .TYPE_FAKE_GI              : return param.values as! FakeGIParameter
            case .TYPE_INSTANT_GI           : return param.values as! InstantGIParameter
            case .TYPE_IRRADIANCE_CACHE_GI  : return param.values as! IrrCacheGIParameter
            case .TYPE_PATH_TRACING_GI      : return param.values as! PathTracingGIParameter
            
            // light parameters
            case .TYPE_CORNELL_BOX          : return param.values as! CornellBoxLightParameter
            case .TYPE_DIRECTIONAL_LIGHT    : return param.values as! DirectionalLightParameter
            case .TYPE_IMAGE_BASED_LIGHT    : return param.values as! ImageBasedLightParameter
            case .TYPE_POINT_LIGHT          : return param.values as! PointLightParameter
            case .TYPE_SPHERE_LIGHT         : return param.values as! SphereLightParameter
            case .TYPE_SUNSKY               : return param.values as! SunSkyLightParameter
            case .TYPE_TRIANGLE_MESH_LIGHT  : return param.values as! TriangleMeshLightParameter
            
            // modifier parameters
            case .TYPE_BUMP_MAP     : return param.values as! BumpMapModifierParameter
            case .TYPE_NORMAL_MAP   : return param.values as! NormalMapModifierParameter
            case .TYPE_PERLIN       : return param.values as! PerlinModifierParameter
                    
            // shader parameters
            case .TYPE_AMBIENT_OCCLUSION : return param.values as! AmbientOcclusionShaderParameter
            case .TYPE_CONSTANT          : return param.values as! ConstantShaderParameter
            case .TYPE_DIFFUSE           : return param.values as! DiffuseShaderParameter
            case .TYPE_GLASS             : return param.values as! GlassShaderParameter
            case .TYPE_MIRROR            : return param.values as! MirrorShaderParameter
            case .TYPE_PHONG             : return param.values as! PhongShaderParameter
            case .TYPE_SHINY_DIFFUSE     : return param.values as! ShinyShaderParameter
            case .TYPE_UBER              : return param.values as! UberShaderParameter
            case .TYPE_WARD              : return param.values as! WardShaderParameter
            case .TYPE_WIREFRAME         : return param.values as! WireframeShaderParameter
        }
    }
}

enum ParameterType: String, Codable {
    // scene parameters
    case TYPE_BACKGROUND = "background"
    case TYPE_BUCKET = "bucket"
    case TYPE_ILLUMINATION = "illumination"
    case TYPE_IMAGE = "image"
    case TYPE_INSTANCE = "instance"
    case TYPE_OVERRIDE = "override"
    case TYPE_PHOTON = "photon"
    case TYPE_TRACE_DEPTHS = "tracedepths"
    case TYPE_TRANSFORM = "transform"
    
    // camera parameters
    case TYPE_FISH_EYE = "fisheye"
    case TYPE_PINHOLE = "pinhole"
    case TYPE_SPHERICAL = "spherical"
    case TYPE_THINLENS = "thinlens"
    
    // gi parameters
    case TYPE_AMBIENT_OCCLUSION_GI = "ambient_occlusion_gi"
    case TYPE_INSTANT_GI = "instant_gi"
    case TYPE_IRRADIANCE_CACHE_GI = "irradiance_cache_gi"
    case TYPE_FAKE_GI = "fake_gi"
    case TYPE_PATH_TRACING_GI = "path_tracing_gi"
    
    // object parameters
    case TYPE_BANCHOFF = "banchoff"
    case TYPE_BEZIER_MESH = "bezier_mesh"
    case TYPE_BOX = "box"
    case TYPE_CYLINDER = "cylinder"
    case TYPE_FILE_MESH = "file_mesh"
    case TYPE_GENERIC_MESH = "generic_mesh"
    case TYPE_TRIANGLE_MESH = "triangle_mesh"
    case TYPE_GUMBO = "gumbo"
    case TYPE_HAIR = "hair"
    case TYPE_JULIA = "julia"
    case TYPE_PARTICLES = "particles"
    case TYPE_PLANE = "plane"
    case TYPE_SPHEREFLAKE = "sphereflake"
    case TYPE_SPHERE = "sphere"
    case TYPE_TEAPOT = "teapot"
    case TYPE_TORUS = "torus"
    
    // light parameters
    case TYPE_CORNELL_BOX = "cornell_box"
    case TYPE_DIRECTIONAL_LIGHT = "directional_light"
    case TYPE_IMAGE_BASED_LIGHT = "image_light"
    case TYPE_POINT_LIGHT = "point_light"
    case TYPE_SPHERE_LIGHT = "sphere_light"
    case TYPE_SUNSKY = "sunsky"
    case TYPE_TRIANGLE_MESH_LIGHT = "mesh_light"
    
    // modifier parameters
    case TYPE_BUMP_MAP = "bump_map"
    case TYPE_NORMAL_MAP = "normal_map"
    case TYPE_PERLIN = "perlin"
    
    // shader parameters
    case TYPE_AMBIENT_OCCLUSION = "ambient_occlusion"
    case TYPE_CONSTANT = "constant_shader"
    case TYPE_DIFFUSE = "diffuse_shader"
    case TYPE_GLASS = "glass_shader"
    case TYPE_MIRROR = "mirror_shader"
    case TYPE_PHONG = "phong_shader"
    case TYPE_SHINY_DIFFUSE = "shiny_diffuse_shader"
    case TYPE_UBER = "uber_shader"
    case TYPE_WARD = "ward_shader"
    case TYPE_WIREFRAME = "wireframe_shader"
}
