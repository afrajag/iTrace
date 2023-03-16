//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

import PathKit

final class API: APIInterface {
    static var VERSION: String = "0.0.1"
    static var DEFAULT_OPTIONS: String = "::options"

    static let shared = API()
    
    var scene: Scene
    var includeSearchPath: SearchPath
    var textureSearchPath: SearchPath
    var parameterList: ParameterList
    var renderObjects: RenderObjectMap
    var currentFrame: Int32 = 0

    // Creates an empty scene.
    private init() {
        // Set up API instance
        PluginRegistry.initRegistry()

        scene = Scene()
        scene.initScene()

        includeSearchPath = SearchPath("include")
        textureSearchPath = SearchPath("texture")

        parameterList = ParameterList()
        renderObjects = RenderObjectMap()

        currentFrame = 1
    }

    // Reset the state of the API completely. The object table is cleared, and
    // all search paths are set back to their default values.
    func reset() {
        scene = Scene()
        scene.initScene()

        includeSearchPath = SearchPath("include")
        textureSearchPath = SearchPath("texture")

        parameterList = ParameterList()
        renderObjects = RenderObjectMap()

        currentFrame = 1
    }

    /*
     func plugin(_ type: String, _ name: String, _ code: String) {
     switch type {
     case "primitive":
     PluginRegistry.primitivePlugins.registerPlugin(name, code)
     case "tesselatable":
     PluginRegistry.tesselatablePlugins.registerPlugin(name, code)
     case "shader":
     PluginRegistry.shaderPlugins.registerPlugin(name, code)
     case "modifier":
     PluginRegistry.modifierPlugins.registerPlugin(name, code)
     case "camera_lens":
     PluginRegistry.cameraLensPlugins.registerPlugin(name, code)
     case "light":
     PluginRegistry.lightSourcePlugins.registerPlugin(name, code)
     case "accel":
     PluginRegistry.accelPlugins.registerPlugin(name, code)
     case "bucket_order":
     PluginRegistry.bucketOrderPlugins.registerPlugin(name, code)
     case "filter":
     PluginRegistry.filterPlugins.registerPlugin(name, code)
     case "gi_engine":
     PluginRegistry.giEnginePlugins.registerPlugin(name, code)
     case "caustic_photon_map":
     PluginRegistry.causticPhotonMapPlugins.registerPlugin(name, code)
     case "global_photon_map":
     PluginRegistry.globalPhotonMapPlugins.registerPlugin(name, code)
     case "image_sampler":
     PluginRegistry.imageSamplerPlugins.registerPlugin(name, code)
     case "parser":
     PluginRegistry.parserPlugins.registerPlugin(name, code)
     case "bitmap_reader":
     PluginRegistry.bitmapReaderPlugins.registerPlugin(name, code)
     case "bitmap_writer":
     PluginRegistry.bitmapWriterPlugins.registerPlugin(name, code)
     default:
     UI.printWarning(.API, "Unrecognized plugin type: \"\(xxx)\" - ignoring declaration of \"\(xxx)\"", type, name)
     }
     }
     */
    // Declare a parameter with the specified name and value. This parameter
    // will be added to the currently active parameter list.
    func parameter(_ name: String, _ value: String) {
        parameterList.addString(name, value)
    }

    func parameter(_ name: String, _ value: Bool) {
        parameterList.addBool(name, value)
    }

    func parameter(_ name: String, _ value: Int32) {
        parameterList.addInteger(name, value)
    }

    func parameter(_ name: String, _ value: Float) {
        parameterList.addFloat(name, value)
    }

    func parameter(_ name: String, _ color: Color) {
        parameterList.addColor(name, color)
    }

    func parameter(_ name: String, _ colorspace: String?, _ data: [Float]) {
        do {
            try parameterList.addColor(name, ColorFactory.createColor(colorspace, data))
        } catch ColorSpecificationException.invalidColor {
            UI.printError(.API, "Invalid color specification")
        } catch let ColorSpecificationException.invalidColorMessage(message) {
            UI.printError(.API, "Invalid color specification: \(message)")
        } catch let ColorSpecificationException.invalidColorExpected(expected, found) {
            UI.printError(.API, "Invalid data length, expecting \(expected) values, found \(found)")
        } catch {
            UI.printError(.API, "Invalid color specification [UNKNOWN]")
        }
    }

    func parameter(_ name: String, _ value: Point3) {
        parameterList.addPoints(name, ParameterList.InterpolationType.NONE, [value.x, value.y, value.z] as [Float])
    }

    func parameter(_ name: String, _ value: Vector3) {
        parameterList.addVectors(name, ParameterList.InterpolationType.NONE, [value.x, value.y, value.z] as [Float])
    }

    func parameter(_ name: String, _ value: Point2) {
        parameterList.addTexCoords(name, ParameterList.InterpolationType.NONE, [value.x, value.y] as [Float])
    }

    func parameter(_ name: String, _ value: AffineTransform) {
        parameterList.addMatrices(name, ParameterList.InterpolationType.NONE, value.asRowMajor())
    }

    func parameter(_ name: String, _ value: [Int32]) {
        parameterList.addIntegerArray(name, value)
    }

    func parameter(_ name: String, _ value: [String]) {
        parameterList.addStringArray(name, value)
    }

    // Declare a parameter with the specified name. The type may be one of the
    // follow: "float", "point", "vector", "texcoord", "matrix". The
    // interpolation determins how the parameter is to be interpreted over
    // surface (see {@link InterpolationType}). The data is specified in a
    // flattened float array.
    //
    // @param name parameter name
    // @param type parameter data type
    // @param interpolation parameter interpolation mode
    // @param data raw floating point data
    func parameter(_ name: String, _ type: String, _ interpolation: String, _ data: [Float]) {
        guard let interp = ParameterList.InterpolationType(rawValue: interpolation) else {
            UI.printError(.API, "Unknown interpolation type: \(interpolation) -- ignoring parameter \"\(name)\"")

            return
        }

        switch type {
            case "float":
                parameterList.addFloats(name, interp, data)
            case "point":
                parameterList.addPoints(name, interp, data)
            case "vector":
                parameterList.addVectors(name, interp, data)
            case "texcoord":
                parameterList.addTexCoords(name, interp, data)
            case "matrix":
                parameterList.addMatrices(name, interp, data)
            default:
                UI.printError(.API, "Unknown parameter type: \(type) -- ignoring parameter \"\(name)\"")
        }
    }

    // Remove the specified render object. Note that this may cause the removal
    // of other objects which depended on it.
    func remove(_ name: String) {
        renderObjects.remove(name)
    }

    // update the specified object using the currently active parameter list. The
    // object is removed if the update fails to avoid leaving inconsistently set
    // objects in the list.
    //
    // @param name name of the object to update
    // @return true if the update was succesfull, or
    //         false if the update failed
    @discardableResult
    func update(_ name: String) -> Bool {
        let success: Bool = renderObjects.update(name, parameterList, self)

        parameterList.clear(success)

        return success
    }

    // Add the specified path to the list of directories which are searched
    // automatically to resolve scene filenames or textures. Currently the
    // supported searchpath types are: "include" and "texture". All other types
    // will be ignored.
    //
    // @param path
    func searchpath(_ type: String, _ path: String) {
        switch type {
        case "include":
            includeSearchPath.addSearchPath(path)
        case "texture":
            textureSearchPath.addSearchPath(path)
        default:
            UI.printWarning(.API, "Invalid searchpath type: \"\(type)\"")
        }
    }

    // Attempts to resolve the specified filename by checking it against the
    // texture search path.
    func resolveTextureFilename(_ filename: String) -> String {
        return textureSearchPath.resolvePath(filename)
    }

    // Attempts to resolve the specified filename by checking it against the
    // include search path.
    func resolveIncludeFilename(_ filename: String) -> String {
        return includeSearchPath.resolvePath(filename)
    }

    // Defines a shader with a given name. If the shader type name is left
    // null, the shader with the given name will be updated (if
    // it exists).
    func shader(_ name: String, _ shaderType: String) {
        if !isIncremental(shaderType) {
            //  we are declaring a shader for the first time
            if renderObjects.has(name) {
                UI.printError(.API, "Unable to declare shader \"\(name)\", name is already in use")
                parameterList.clear(true)

                return
            }

            let shader: Shader? = PluginRegistry.shaderPlugins.createInstance(shaderType)

            if shader == nil {
                UI.printError(.API, "Unable to create shader of type \"\(shaderType)\"")

                return
            }

            renderObjects.put(name, shader!)
        }

        //  update existing shader (only if it is valid)
        if lookupShader(name) != nil {
            update(name)
        } else {
            UI.printError(.API, "Unable to update shader \"\(name)\" - shader object was not found")
            
            parameterList.clear(true)
        }
    }

    // Defines a modifier with a given name. If the modifier type name is left
    // null, the modifier with the given name will be updated
    // (if it exists).
    func modifier(_ name: String, _ modifierType: String) {
        if !isIncremental(modifierType) {
            //  we are declaring a shader for the first time
            if renderObjects.has(name) {
                UI.printError(.API, "Unable to declare modifier \"\(name)\", name is already in use")
                
                parameterList.clear(true)

                return
            }

            let modifier: Modifier? = PluginRegistry.modifierPlugins.createInstance(modifierType)

            if modifier == nil {
                UI.printError(.API, "Unable to create modifier of type \"\(modifierType)\"")

                return
            }

            renderObjects.put(name, modifier!)
        }

        //  update existing shader (only if it is valid)
        if lookupModifier(name) != nil {
            update(name)
        } else {
            UI.printError(.API, "Unable to update modifier \"\(name)\" - modifier object was not found")
            
            parameterList.clear(true)
        }
    }

    // Defines a geometry with a given name. The geometry is built from the
    // specified type. Note that geometries may be created from
    // {@link Tesselatable} objects or {@link PrimitiveList} objects. This means
    // that two seperate plugin lists will be searched for the geometry type.
    // {@link Tesselatable} objects are search first. If the type name is left
    // null, the geometry with the given name will be updated
    // (if it exists).
    func geometry(_ name: String, _ typeName: String) {
        if !isIncremental(typeName) {
            //  we are declaring a geometry for the first time
            if renderObjects.has(name) {
                UI.printError(.API, "Unable to declare geometry \"\(name)\", name is already in use")
                
                parameterList.clear(true)

                return
            }

            //  check tesselatable first
            if PluginRegistry.tesselatablePlugins.hasType(typeName) {
                let tesselatable: Tesselatable? = PluginRegistry.tesselatablePlugins.createInstance(typeName)

                if tesselatable == nil {
                    UI.printError(.API, "Unable to create tesselatable object of type \"\(typeName)\"")

                    return
                }

                renderObjects.put(name, tesselatable!)
            } else {
                let primitives: PrimitiveList? = PluginRegistry.primitivePlugins.createInstance(typeName)

                if primitives == nil {
                    UI.printError(.API, "Unable to create primitive of type \"\(typeName)\"")

                    return
                }

                renderObjects.put(name, primitives!)
            }
        }

        if lookupGeometry(name) != nil {
            update(name)
        } else {
            UI.printError(.API, "Unable to update geometry \"\(name)\" - geometry object was not found")
            
            parameterList.clear(true)
        }
    }

    // Instance the specified geometry into the scene. If geoname is
    // null, the specified instance object will be updated (if
    // it exists). In order to change the instancing relationship of an existing
    // instance, you should use the "geometry" string attribute.
    func instance(_ name: String, _ geoname: String) {
        if !isIncremental(geoname) {
            //  we are declaring this instance for the first time
            if renderObjects.has(name) {
                UI.printError(.API, "Unable to declare instance \"\(name)\", name is already in use")
                parameterList.clear(true)

                return
            }

            parameter("geometry", geoname)

            renderObjects.put(name, Instance())
        }

        if lookupInstance(name) != nil {
            update(name)
        } else {
            UI.printError(.API, "Unable to update instance \"\(name)\" - instance object was not found")

            parameterList.clear(true)
        }
    }

    // Defines a light source with a given name. If the light type name is left
    // null, the light source with the given name will be
    // updated (if it exists).
    func light(_ name: String, _ lightType: String) {
        if !isIncremental(lightType) {
            //  we are declaring this light for the first time
            if renderObjects.has(name) {
                UI.printError(.API, "Unable to declare light \"\(name)\", name is already in use")
                
                parameterList.clear(true)

                return
            }

            let light: LightSource? = PluginRegistry.lightSourcePlugins.createInstance(lightType)

            if light == nil {
                UI.printError(.API, "Unable to create light source of type \"\(lightType)\"")

                return
            }

            renderObjects.put(name, light!)
        }
        if lookupLight(name) != nil {
            update(name)
        } else {
            UI.printError(.API, "Unable to update instance \"\(name)\" - instance object was not found")
            
            parameterList.clear(true)
        }
    }

    // Defines a camera with a given name. The camera is built from the
    // specified camera lens type plugin. If the lens type name is left
    // null, the camera with the given name will be updated (if
    // it exists). It is not currently possible to change the lens of a camera
    // after it has been created.
    func camera(_ name: String, _ lensType: String) {
        if !isIncremental(lensType) {
            //  we are declaring this camera for the first time
            if renderObjects.has(name) {
                UI.printError(.API, "Unable to declare camera \"\(name)\", name is already in use")
                
                parameterList.clear(true)

                return
            }

            let lens: CameraLens? = PluginRegistry.cameraLensPlugins.createInstance(lensType)

            if lens == nil {
                UI.printError(.API, "Unable to create a camera lens of type \"\(lensType)\"")
                return
            }

            renderObjects.put(name, CameraBase(lens!))
        }

        //  update existing shader (only if it is valid)
        if lookupCamera(name) != nil {
            guard update(name) else {
                UI.printError(.API, "Update camera failed")
                return
            }
        } else {
            UI.printError(.API, "Unable to update camera \"\(name)\" - camera object was not found")
            
            parameterList.clear(true)
        }
    }

    // Defines an option object to hold the current parameters. If the object
    // already exists, the values will simply override previous ones.
    func options(_ name: String) {
        if lookupOptions(name) == nil {
            if renderObjects.has(name) {
                UI.printError(.API, "Unable to declare options \"\(name)\", name is already in use")
                
                parameterList.clear(true)
                
                return
            }

            renderObjects.put(name, Options())
        }

        // Debug.Assert(lookupOptions(name) != nil)

        guard update(name) else {
            UI.printError(.API, "Update options failed")
            
            return
        }
    }

    // Retrieve a geometry object by its name, or null if no
    // geometry was found, or if the specified object is not a geometry.
    func lookupGeometry(_ name: String) -> Geometry? {
        return renderObjects.lookupGeometry(name)
    }

    func isIncremental(_ typeName: String?) -> Bool {
        return typeName == nil || typeName == "incremental"
    }

    // Retrieve an instance object by its name, or null if no
    // instance was found, or if the specified object is not an instance.
    func lookupInstance(_ name: String) -> Instance? {
        return renderObjects.lookupInstance(name)
    }

    // Retrieve a shader object by its name, or null if no shader
    // was found, or if the specified object is not a shader.
    func lookupCamera(_ name: String) -> CameraBase? {
        return renderObjects.lookupCamera(name)
    }

    func lookupOptions(_ name: String) -> Options? {
        return renderObjects.lookupOptions(name)
    }

    // Retrieve a shader object by its name, or null if no shader
    // was found, or if the specified object is not a shader.
    func lookupShader(_ name: String) -> Shader? {
        return renderObjects.lookupShader(name)
    }

    // Retrieve a modifier object by its name, or null if no
    // modifier was found, or if the specified object is not a modifier.
    func lookupModifier(_ name: String) -> Modifier? {
        return renderObjects.lookupModifier(name)
    }

    // Retrieve a light object by its name, or null if no shader
    // was found, or if the specified object is not a light.
    func lookupLight(_ name: String) -> LightSource? {
        return renderObjects.lookupLight(name)
    }

    // Sets a global shader override to the specified shader name. If the shader
    // is not found, the overriding is disabled. The second parameter controls
    // whether the override applies to the photon tracing process.
    func shaderOverride(_ name: String, _ photonOverride: Bool) {
        scene.setShaderOverride(lookupShader(name)!, photonOverride)
    }

    // Render using the specified options and the specified display. If the
    // specified options do not exist - defaults will be used.
    func render(_ optionsName: String, _ display: Display?) {
        // TODO: controllare che non venga chiamato per primo un metodo di QMC da altre parti, in caso vedere dove chiamare il costruttore
        // doing some initialization ...
        Vector3.initVectorTables()
        QMC.buildSigPri()
        
        var _optionsName: String = optionsName

        if optionsName.isEmpty {
            _optionsName = "::options"
        }

        renderObjects.updateScene(scene)

        var opt: Options? = lookupOptions(_optionsName)

        if opt == nil {
            opt = Options()
        }

        scene.setCamera(lookupCamera(opt!.getString("camera", nil)!)!)

        //  shader override
        let shaderOverrideName: String = opt!.getString("override.shader", ShaderParameter.TYPE_NONE)!
        let overridePhotons: Bool = opt!.getBool("override.photons", false)!

        if shaderOverrideName == ShaderParameter.TYPE_NONE {
            scene.setShaderOverride(nil, false)
        } else {
            let shader: Shader? = lookupShader(shaderOverrideName)

            if shader == nil {
                UI.printWarning(.API, "Unable to find shader \"\(shaderOverrideName)\" for override, disabling")
            }

            scene.setShaderOverride(shader, overridePhotons)
        }

        //  baking
        let bakingInstanceName: String? = opt!.getString("baking.instance", nil)

        if bakingInstanceName != nil {
            let bakingInstance: Instance? = lookupInstance(bakingInstanceName!)

            if bakingInstance == nil {
                UI.printError(.API, "Unable to bake instance \"\(bakingInstanceName!)\" - not found")

                return
            }

            scene.setBakingInstance(bakingInstance)
        } else {
            scene.setBakingInstance(nil)
        }

        let sampler: ImageSampler? = PluginRegistry.imageSamplerPlugins.createInstance(opt!.getString("sampler", "bucket"))
        
        if display == nil {
            scene.render(opt!, sampler, GUIDisplay())
        } else {
            scene.render(opt!, sampler, display)
        }
    }

    // Parse the specified filename. The include paths are searched first. The
    // contents of the file are simply added to the active scene. This allows to
    // break up a scene into parts, even across file formats. The appropriate
    // parser is chosen based on file extension.
    func include(_ filename: String) -> Bool {
        if filename.isEmpty {
            return false
        }

        let _filename = includeSearchPath.resolvePath(filename)

        let file_extension: String = FileUtils.getExtension(_filename)!
        
        let parser: SceneParser? = PluginRegistry.parserPlugins.createInstance(file_extension)

        if parser == nil {
            UI.printError(.API, "Unable to find a suitable parser for: \"\(_filename)\"(extension: \(file_extension))")

            return false
        }

        let currentFolder: String = Path(_filename).isAbsolute ? FileUtils.getPath(_filename)! : "."

        includeSearchPath.addSearchPath(currentFolder)
        
        textureSearchPath.addSearchPath(currentFolder)

        return parser!.parse(_filename)
    }

    // Retrieve the bounding box of the scene. This method will be valid only
    // after a first call to {@link #render(string, Display)} has been made.
    func getBounds() -> BoundingBox {
        return scene.getBounds()
    }

    // This method does nothing, but may be overriden to create scenes
    // procedurally.
    func build() {}

    // Create an API object from the specified file. Java files are read by
    // Janino and are expected to implement a build method (they implement a
    // derived final class of API. The build method is called if the code
    // compiles succesfully. Other files types are handled by the parse method.
    static func create(_ filename: String, _: Int32 = 1) -> API? {
        if filename.isEmpty {
            return API()
        }

        /*
         if filename.EndsWith(".java") {
         	var t: TraceTimer = TraceTimer()

         UI.printInfo(.API, "Compiling \"\(filename)\" ...")

         t.start()
         // FileInputStream stream = new FileInputStream(filename);
         api = nil
         // (API) ClassBodyEvaluator.createFastClassBodyEvaluator(new Scanner(filename, stream), API.class, ClassLoader.getSystemClassLoader());
         // fixme: the dynamic loading
         // stream.close();

         //UI.printError(.API, "Could not compile: \"\(xxx)\"", filename)
         //UI.printError(.API, "\(xxx)", e)
         //return nil
         	t.end()

         	UI.printInfo(.API, "Compile time: \(t)")

         if api != nil {
         		var currentFolder: String = Path.GetDirectoryName(filename)

         // new File(filename).getAbsoluteFile().getParentFile().getAbsolutePath();
         		API.shared.includeSearchPath.addSearchPath(currentFolder)
         		API.shared.textureSearchPath.addSearchPath(currentFolder)
         	}

         	UI.printInfo(.API, "Build script running ...")

         t.start()
         	API.shared.currentFrame = frameNumber
         	API.shared.build()
         	t.end()

         	UI.printInfo(.API, "Build script time: \(t)")
         } else {
         	api = API()
         	api = (API.shared.include(filename) ? api : nil)
         }
         */
        
        var api: API? = API()
        
        api = API.shared.include(filename) ? api : nil
        
        return api
    }

    // Compile the specified code string via Janino. The code must implement a
    // build method as described above. The build method is not called on the
    // output, it is up the caller to do so.
    static func compile(_: String) -> API {
        let api: API = API()
        /*
         var t: TraceTimer = TraceTimer()

         t.start()
         var api: API = nil
         // (API) ClassBodyEvaluator.createFastClassBodyEvaluator(new Scanner(null, new stringReader(code)), API.class, (ClassLoader) null);
         // fixme: the dynamic loading
         t.end()

         UI.printInfo(.API, "Compile time: \(t)")

         return api

         //UI.printError(.API, "\(xxx)", e)
         return nil
         */
        return api
    }

    func currentFrame(_ currentFrame: Int32) {
        self.currentFrame = currentFrame
    }
}
