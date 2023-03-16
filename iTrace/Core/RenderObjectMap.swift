//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

import Foundation

final class RenderObjectMap {
    var renderObjects: [String: RenderObjectHandle]
    var rebuildInstanceList: Bool = false
    var rebuildLightList: Bool = false

    init() {
        renderObjects = [String: RenderObjectHandle]()
        rebuildInstanceList = false
        rebuildLightList = false
    }

    func has(_ name: String) -> Bool {
        return renderObjects[name] != nil
    }

    func remove(_ name: String) {
        let obj: RenderObjectHandle? = renderObjects[name]

        if obj == nil {
            UI.printWarning(.API, "Unable to remove \"\(name)\" - object was not defined yet")

            return
        }

        UI.printDetailed(.API, "Removing object \"\(name)\"")

        renderObjects.removeValue(forKey: name)

        //  scan through all objects to make sure we don't have any
        //  references to the old object still around
        switch obj!.type {
        case RenderObjectType.SHADER:
            let s: Shader? = obj!.getShader()

            for e in renderObjects {
                let i: Instance? = e.value.getInstance()

                if i != nil {
                    UI.printWarning(.API, "Removing shader \"\(name)\" from instance \"\(e.key)\"")
                    i!.removeShader(s!)
                }
            }
        case RenderObjectType.MODIFIER:
            let m: Modifier? = obj!.getModifier()

            for e in renderObjects {
                let i: Instance? = e.value.getInstance()

                if i != nil {
                    UI.printWarning(.API, "Removing modifier \"\(name)\" from instance \"\(e.key)\"")
                    i!.removeModifier(m!)
                }
            }
        case RenderObjectType.GEOMETRY:
            let g: Geometry? = obj!.getGeometry()

            for e in renderObjects {
                let i: Instance? = e.value.getInstance()

                if i != nil && i!.hasGeometry(g!) {
                    UI.printWarning(.API, "Removing instance \"\(e.key)\" because it referenced geometry \"\(name)\"")
                    remove(e.key)
                }
            }
        case RenderObjectType.INSTANCE:
            rebuildInstanceList = true
        case RenderObjectType.LIGHT:
            rebuildLightList = true
        default:
            // UI.printWarning(.API, "Not implemented (remove)")
            break
        }
    }

    func update(_ name: String, _ pl: ParameterList, _ api: API) -> Bool {
        let obj: RenderObjectHandle? = renderObjects[name]!
        var success: Bool

        if obj == nil {
            UI.printError(.API, "Unable to update \"\(name)\" - object was not defined yet")

            success = false
        } else {
            UI.printDetailed(.API, "Updating \(obj!.typeName()) object \"\(name)\"")

            success = obj!.update(pl)

            if !success {
                UI.printError(.API, "Unable to update \"\(name)\" - removing")
                
                remove(name)
            } else {
                switch obj!.type {
                    case RenderObjectType.GEOMETRY,
                         RenderObjectType.INSTANCE:
                        rebuildInstanceList = true
                    case RenderObjectType.LIGHT:
                        rebuildLightList = true
                    default:
                        // UI.printWarning(.API, "Not implemented (update)")
                        break
                }
            }
        }

        return success
    }

    func updateScene(_ scene: Scene) {
        if rebuildInstanceList {
            UI.printInfo(.API, "Building scene instance list for rendering ...")

            var numInfinite: Int32 = 0
            var numInstance: Int32 = 0

            for e in renderObjects {
                let i: Instance? = e.value.getInstance()

                if i != nil {
                    i!.updateBounds()

                    let bb: BoundingBox? = i!.getBounds()

                    if bb == nil {
                        numInfinite += 1
                    } else if !bb!.isEmpty() {
                        numInstance += 1
                    } else {
                        UI.printWarning(.API, "Ignoring empty instance: \"\(e.key)\"")
                    }
                }
            }

            var infinite: [Instance] = [Instance](repeating: Instance(), count: Int(numInfinite))
            var instance: [Instance] = [Instance](repeating: Instance(), count: Int(numInstance))

            numInfinite = 0
            numInstance = 0

            for e in renderObjects {
                let i: Instance? = e.value.getInstance()

                if i != nil {
                    let bb: BoundingBox? = i!.getBounds()

                    if bb == nil {
                        infinite[Int(numInfinite)] = i!

                        numInfinite += 1
                    } else if !(bb!.isEmpty()) {
                        instance[Int(numInstance)] = i!

                        numInstance += 1
                    }
                }
            }

            scene.setInstanceLists(instance, infinite)

            rebuildInstanceList = false
        }

        if rebuildLightList {
            UI.printInfo(.API, "Building scene light list for rendering ...")

            var lightList: [LightSource] = [LightSource]()

            for e in renderObjects {
                let light: LightSource? = e.value.getLight()

                if light != nil {
                    lightList.append(light!)
                }
            }

            scene.setLightList(lightList)

            rebuildLightList = false
        }
    }

    func put(_ name: String, _ shader: Shader) {
        renderObjects[name] = RenderObjectHandle(shader)
    }

    func put(_ name: String, _ modifier: Modifier) {
        renderObjects[name] = RenderObjectHandle(modifier)
    }

    func put(_ name: String, _ primitives: PrimitiveList) {
        renderObjects[name] = RenderObjectHandle(primitives)
    }

    func put(_ name: String, _ tesselatable: Tesselatable) {
        renderObjects[name] = RenderObjectHandle(tesselatable)
    }

    func put(_ name: String, _ instance: Instance) {
        renderObjects[name] = RenderObjectHandle(instance)
    }

    func put(_ name: String, _ light: LightSource) {
        renderObjects[name] = RenderObjectHandle(light)
    }

    func put(_ name: String, _ camera: CameraBase) {
        renderObjects[name] = RenderObjectHandle(camera)
    }

    func put(_ name: String, _ options: Options) {
        renderObjects[name] = RenderObjectHandle(options)
    }

    func lookupGeometry(_ name: String?) -> Geometry? {
        if name == nil {
            return nil
        }

        let handle: RenderObjectHandle? = renderObjects[name!]

        return (handle == nil ? nil : handle!.getGeometry())
    }

    func lookupInstance(_ name: String?) -> Instance? {
        if name == nil {
            return nil
        }

        let handle: RenderObjectHandle? = renderObjects[name!]

        return (handle == nil ? nil : handle!.getInstance())
    }

    func lookupCamera(_ name: String?) -> CameraBase? {
        if name == nil {
            return nil
        }

        let handle: RenderObjectHandle? = renderObjects[name!]

        return (handle == nil ? nil : handle!.getCamera())
    }

    func lookupOptions(_ name: String?) -> Options? {
        if name == nil {
            return nil
        }

        let handle: RenderObjectHandle? = renderObjects[name!]

        return (handle == nil ? nil : handle!.getOptions())
    }

    func lookupShader(_ name: String?) -> Shader? {
        if name == nil {
            return nil
        }

        let handle: RenderObjectHandle? = renderObjects[name!]

        return (handle == nil ? nil : handle!.getShader())
    }

    func lookupModifier(_ name: String?) -> Modifier? {
        if name == nil {
            return nil
        }

        let handle: RenderObjectHandle? = renderObjects[name!]

        return (handle == nil ? nil : handle!.getModifier())
    }

    func lookupLight(_ name: String?) -> LightSource? {
        if name == nil {
            return nil
        }

        let handle: RenderObjectHandle? = renderObjects[name!]

        return (handle == nil ? nil : handle!.getLight())
    }

    enum RenderObjectType: String, CustomStringConvertible {
        case UNKNOWN
        case SHADER
        case MODIFIER
        case GEOMETRY
        case INSTANCE
        case LIGHT
        case CAMERA
        case OPTIONS

        var description: String {
            return rawValue
        }
    }

    final class RenderObjectHandle {
        var obj: RenderObject
        var type: RenderObjectType

        init(_ shader: Shader) {
            obj = shader
            type = RenderObjectType.SHADER
        }

        init(_ modifier: Modifier) {
            obj = modifier
            type = RenderObjectType.MODIFIER
        }

        init(_ tesselatable: Tesselatable) {
            obj = Geometry(tesselatable)
            type = RenderObjectType.GEOMETRY
        }

        init(_ prims: PrimitiveList) {
            obj = Geometry(prims)
            type = RenderObjectType.GEOMETRY
        }

        init(_ instance: Instance) {
            obj = instance
            type = RenderObjectType.INSTANCE
        }

        init(_ light: LightSource) {
            obj = light
            type = RenderObjectType.LIGHT
        }

        init(_ camera: CameraBase) {
            obj = camera
            type = RenderObjectType.CAMERA
        }

        init(_ options: Options) {
            obj = options
            type = RenderObjectType.OPTIONS
        }

        func update(_ pl: ParameterList) -> Bool {
            return obj.update(pl)
        }

        func typeName() -> String {
            return type.description
        }

        func getShader() -> Shader? {
            return (type == RenderObjectType.SHADER ? (obj as! Shader) : nil)
        }

        func getModifier() -> Modifier? {
            return (type == RenderObjectType.MODIFIER ? (obj as! Modifier) : nil)
        }

        func getGeometry() -> Geometry? {
            return (type == RenderObjectType.GEOMETRY ? (obj as! Geometry) : nil)
        }

        func getInstance() -> Instance? {
            return (type == RenderObjectType.INSTANCE ? (obj as! Instance) : nil)
        }

        func getLight() -> LightSource? {
            return (type == RenderObjectType.LIGHT ? (obj as! LightSource) : nil)
        }

        func getCamera() -> CameraBase? {
            return (type == RenderObjectType.CAMERA ? (obj as! CameraBase) : nil)
        }

        func getOptions() -> Options? {
            return (type == RenderObjectType.OPTIONS ? (obj as! Options) : nil)
        }
    }
}
