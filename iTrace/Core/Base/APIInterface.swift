//
//  APIInterface.swift
//  iTrace
//
//  Created by Fabrizio Pezzola on 18/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

protocol APIInterface: class {
    // Reset the state of the API completely. The object table is cleared, and
    // all search paths are set back to their default values.
    func reset()

    // Declare a plugin of the specified type with the given name from a java
    // code string. The code will be compiled with Janino and registered as a
    // new plugin type upon success.
    //
    // @param type
    // @param name
    // @param code
    // FIXME: da riabilitare
    // func plugin(_ type: String, _ name: String, _ code: String)

    // Declare a parameter with the specified name and value. This parameter
    // will be added to the currently active parameter list.
    //
    // @param name parameter name
    // @param value parameter value
    func parameter(_ name: String, _ value: String)

    // Declare a parameter with the specified name and value. This parameter
    // will be added to the currently active parameter list.
    //
    // @param name parameter name
    // @param value parameter value
    func parameter(_ name: String, _ value: Bool)

    // Declare a parameter with the specified name and value. This parameter
    // will be added to the currently active parameter list.
    //
    // @param name parameter name
    // @param value parameter value
    func parameter(_ name: String, _ value: Int32)

    // Declare a parameter with the specified name and value. This parameter
    // will be added to the currently active parameter list.
    //
    // @param name parameter name
    // @param value parameter value
    func parameter(_ name: String, _ value: Float)

    // Declare a color parameter in the given colorspace using the specified
    // name and value. This parameter will be added to the currently active
    // parameter list.
    func parameter(_ name: String, _ color: Color)

    // Declare a color parameter in the given colorspace using the specified
    // name and value. This parameter will be added to the currently active
    // parameter list.
    //
    // @param name parameter name
    // @param colorspace color space or null to assume internal
    //            color space
    // @param data floating point color data
    func parameter(_ name: String, _ colorspace: String?, _ data: [Float])

    // Declare a parameter with the specified name and value. This parameter
    // will be added to the currently active parameter list.
    //
    // @param name parameter name
    // @param value parameter value
    func parameter(_ name: String, _ value: Point3)

    // Declare a parameter with the specified name and value. This parameter
    // will be added to the currently active parameter list.
    //
    // @param name parameter name
    // @param value parameter value
    func parameter(_ name: String, _ value: Vector3)

    // Declare a parameter with the specified name and value. This parameter
    // will be added to the currently active parameter list.
    //
    // @param name parameter name
    // @param value parameter value
    func parameter(_ name: String, _ value: Point2)

    // Declare a parameter with the specified name and value. This parameter
    // will be added to the currently active parameter list.
    //
    // @param name parameter name
    // @param value parameter value
    func parameter(_ name: String, _ value: AffineTransform)

    // Declare a parameter with the specified name and value. This parameter
    // will be added to the currently active parameter list.
    //
    // @param name parameter name
    // @param value parameter value
    func parameter(_ name: String, _ value: [Int32])

    // Declare a parameter with the specified name and value. This parameter
    // will be added to the currently active parameter list.
    //
    // @param name parameter name
    // @param value parameter value
    func parameter(_ name: String, _ value: [String])

    // Declare a parameter with the specified name. The type may be one of the
    // follow: "float", "point", "vector", "texcoord", "matrix". The
    // interpolation determines how the parameter is to be interpreted over
    // surface (see {@link InterpolationType}). The data is specified in a
    // flattened float array.
    //
    // @param name parameter name
    // @param type parameter data type
    // @param interpolation parameter interpolation mode
    // @param data raw floating point data
    func parameter(_ name: String, _ type: String, _ interpolation: String, _ data: [Float])

    // Remove the specified render object. Note that this may cause the removal
    // of other objects which depended on it.
    //
    // @param name name of the object to remove
    func remove(_ name: String)

    // Add the specified path to the list of directories which are searched
    // automatically to resolve scene filenames or textures. Currently the
    // supported searchpath types are: "include" and "texture". All other types
    // will be ignored.
    //
    // @param path
    func searchpath(_ type: String, _ path: String)

    // Defines a shader with a given name. If the shader type name is left
    // null, the shader with the given name will be updated (if
    // it exists).
    //
    // @param name a unique name given to the shader
    // @param shaderType a shader plugin type
    func shader(_ name: String, _ shaderType: String)

    // Defines a modifier with a given name. If the modifier type name is left
    // null, the modifier with the given name will be updated
    // (if it exists).
    //
    // @param name a unique name given to the modifier
    // @param modifierType a modifier plugin type name
    func modifier(_ name: String, _ modifierType: String)

    // Defines a geometry with a given name. The geometry is built from the
    // specified type. Note that geometries may be created from
    // {@link Tesselatable} objects or {@link PrimitiveList} objects. This means
    // that two seperate plugin lists will be searched for the geometry type.
    // {@link Tesselatable} objects are search first. If the type name is left
    // null, the geometry with the given name will be updated
    // (if it exists).
    //
    // @param name a unique name given to the geometry
    // @param typeName a tesselatable or primitive plugin type name
    func geometry(_ name: String, _ typeName: String)

    // Instance the specified geometry into the scene. If geoname is
    // null, the specified instance object will be updated (if
    // it exists). In order to change the instancing relationship of an existing
    // instance, you should use the "geometry" string attribute.
    //
    // @param name instance name
    // @param geoname name of the geometry to instance
    func instance(_ name: String, _ geoname: String)

    // Defines a light source with a given name. If the light type name is left
    // null, the light source with the given name will be
    // updated (if it exists).
    //
    // @param name a unique name given to the light source
    // @param lightType a light source plugin type name
    func light(_ name: String, _ lightType: String)

    // Defines a camera with a given name. The camera is built from the
    // specified camera lens type plugin. If the lens type name is left
    // null, the camera with the given name will be updated (if
    // it exists). It is not currently possible to change the lens of a camera
    // after it has been created.
    //
    // @param name camera name
    // @param lensType a camera lens plugin type name
    func camera(_ name: String, _ lensType: String)

    // Defines an option object to hold the current parameters. If the object
    // already exists, the values will simply override previous ones.
    //
    // @param name
    func options(_ name: String)

    // Render using the specified options and the specified display. If the
    // specified options do not exist - defaults will be used.
    //
    // @param optionsName name of the {@link RenderObject} which contains the
    //            options
    // @param display display object
    func render(_ optionsName: String, _ display: Display?)

    // Parse the specified filename. The include paths are searched first. The
    // contents of the file are simply added to the active scene. This allows to
    // break up a scene into parts, even across file formats. The appropriate
    // parser is chosen based on file extension.
    //
    // @param filename filename to load
    // @return true upon sucess, false if an error
    //         occured.
    @discardableResult
    func include(_ filename: String) -> Bool

    // Set the value of the current frame. This value is intended only for
    // procedural animation creation. It is not used by the Sunflow core in
    // anyway. The default value is 1.
    //
    // @param currentFrame current frame number
    func currentFrame(_ currentFrame: Int32)
}
