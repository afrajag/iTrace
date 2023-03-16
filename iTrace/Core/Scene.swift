//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//
import Foundation

final class Scene {
    var lightServer: LightServer?
    var instanceList: InstanceList
    var infiniteInstanceList: InstanceList
    var camera: CameraBase?
    var intAccel: AccelerationStructure
    var acceltype: String = "auto"
    var stats: Statistics
    var bakingViewDependent: Bool = false
    var bakingInstance: Instance?
    var bakingPrimitives: PrimitiveList?
    var bakingAccel: AccelerationStructure?
    var rebuildAccel: Bool = false
    var imageWidth: Int32 = 0
    var imageHeight: Int32 = 0
    var threads: Int32 = 0
    var lowPriority: Bool = false

    init() {
        instanceList = InstanceList()
        infiniteInstanceList = InstanceList()
        intAccel = NullAccelerator()
        acceltype = "auto"
        stats = Statistics()
        bakingViewDependent = false
        bakingInstance = nil
        bakingPrimitives = nil
        bakingAccel = nil
        camera = nil
        imageWidth = 640
        imageHeight = 480
        threads = 0
        lowPriority = true
        rebuildAccel = true
    }

    // Creates an empty scene.
    func initScene() {
        lightServer = LightServer(self) // FIXME: dove la passa la scena?
    }

    // Get number of allowed threads for multi-threaded operations.
    //
    // @return number of threads that can be started
    func getThreads() -> Int32 {
        return (threads <= 0 ? Int32(ProcessInfo().processorCount) : threads)
    }

    // Get the priority level to assign to multi-threaded operations.
    //
    // @return thread priority
    func getThreadPriority() -> Float {
        return (lowPriority ? 0 /* ThreadPriority.Lowest */ : 0.5 /* ThreadPriority.Normal */ )
    }

    // Sets the current camera (no support for multiple cameras yet).
    //
    // @param camera camera to be used as the viewpoint for the scene
    func setCamera(_ camera: CameraBase?) {
        self.camera = camera
    }

    func getCamera() -> CameraBase? {
        return camera
    }

    // update the instance lists for this scene.
    //
    // @param instances regular instances
    // @param infinite infinite instances (no bounds)
    func setInstanceLists(_ instances: [Instance], _ infinite: [Instance]) {
        infiniteInstanceList = InstanceList(infinite)
        instanceList = InstanceList(instances)

        rebuildAccel = true
    }

    // update the light list for this scene.
    //
    // @param lights array of light source objects
    func setLightList(_ lights: [LightSource]) {
        lightServer!.setLights(lights)
    }

    // Enables shader overiding (set null to disable). The specified shader will
    // be used to shade all surfaces
    //
    // @param shader shader to run over all surfaces, or null to
    //            disable overriding
    // @param photonOverride true to override photon scattering
    //            with this shader or false to run the regular
    //            shaders
    func setShaderOverride(_ shader: Shader?, _ photonOverride: Bool) {
        lightServer!.setShaderOverride(shader, photonOverride)
    }

    // The provided instance will be considered for lightmap baking. If the
    // specified instance is null, lightmap baking will be
    // disabled and normal rendering will occur.
    //
    // @param instance instance to bake
    func setBakingInstance(_ instance: Instance?) {
        bakingInstance = instance
    }

    // Get the radiance seen through a particular pixel
    //
    // @param istate intersection state for ray tracing
    // @param rx pixel x coordinate
    // @param ry pixel y coordinate
    // @param lensU DOF sampling variable
    // @param lensV DOF sampling variable
    // @param time motion blur sampling variable
    // @param instance QMC instance seed
    // @return a shading state for the intersected primitive, or
    //         null if nothing is seen through the specified point
    func getRadiance(_ istate: IntersectionState, _ rx: Float, _ ry: Float, _ lensU: Double, _ lensV: Double, _ time: Double, _ instance: Int32, _ dim: Int32, _ cache: ShadingCache?) -> ShadingState? {
        istate.numEyeRays += 1

        let sceneTime: Float = camera!.getTime(Float(time))

        if bakingPrimitives == nil {
            let r: Ray? = camera!.getRay(rx, ry, imageWidth, imageHeight, lensU, lensV, sceneTime)

            return (r != nil ? lightServer!.getRadiance(rx, ry, sceneTime, instance, dim, r!, istate, cache) : nil)
        } else {
            let r: Ray = Ray(rx / Float(imageWidth), ry / Float(imageHeight), -1, 0, 0, 1)

            traceBake(r, istate)

            if !istate.hit() {
                return nil
            }

            let state: ShadingState = ShadingState.createState(istate, rx, ry, sceneTime, r, instance, dim, lightServer)

            bakingPrimitives!.prepareShadingState(state)

            if bakingViewDependent {
                state.setRay(camera!.getRay(state.getPoint(), sceneTime))
            } else {
                let p: Point3 = state.getPoint()
                let n: Vector3 = state.getNormal()!

                //  create a ray coming from directly above the point being
                //  shaded
                let incoming: Ray = Ray(p.x + n.x, p.y + n.y, p.z + n.z, -n.x, -n.y, -n.z)

                incoming.setMax(1)

                state.setRay(incoming)
            }

            lightServer!.shadeBakeResult(state)

            return state
        }
    }

    // Get scene world space bounding box.
    //
    // @return scene bounding box
    func getBounds() -> BoundingBox {
        return instanceList.getWorldBounds(nil)!
    }

    func accumulateStats(_ state: IntersectionState) {
        stats.accumulate(state)
    }

    func accumulateStats(_ cache: ShadingCache) {
        stats.accumulate(cache)
    }

    func trace(_ r: Ray, _ state: IntersectionState) {
        state.numRays += 1

        //  reset object
        state.instance = nil
        state.current = nil

        for i in 0 ..< infiniteInstanceList.getNumPrimitives() {
            infiniteInstanceList.intersectPrimitive(r, i, state)
        }

        //  reset for next accel structure
        state.current = nil

        intAccel.intersect(r, state)
    }

    func traceShadow(_ r: Ray, _ state: IntersectionState) -> Color {
        state.numShadowRays += 1

        trace(r, state)

        return (state.hit() ? Color.WHITE : Color.BLACK)
    }

    func traceBake(_ r: Ray, _ state: IntersectionState) {
        //  set the instance as if tracing a regular instanced object
        state.current = bakingInstance

        //  reset object
        state.instance = nil

        bakingAccel!.intersect(r, state)
    }

    func createAreaLightInstances() {
        var infiniteAreaLights: [Instance]?
        var areaLights: [Instance]?

        //  create an area light instance from each light source if possible
        for l in lightServer!.lights {
            let lightInstance: Instance? = l.createInstance()

            if lightInstance != nil {
                if lightInstance!.getBounds() == nil {
                    if infiniteAreaLights == nil {
                        infiniteAreaLights = [Instance]()
                    }

                    infiniteAreaLights!.append(lightInstance!)
                } else {
                    if areaLights == nil {
                        areaLights = [Instance]()
                    }

                    areaLights!.append(lightInstance!)
                }
            }
        }

        //  add area light sources to the list of instances if they exist
        if infiniteAreaLights != nil, infiniteAreaLights!.count > 0 {
            infiniteInstanceList.addLightSourceInstances(infiniteAreaLights!)
        } else {
            infiniteInstanceList.clearLightSources()
        }

        if areaLights != nil, areaLights!.count > 0 {
            instanceList.addLightSourceInstances(areaLights!)
        } else {
            instanceList.clearLightSources()
        }

        //  FIXME: this _could_ be done incrementally to avoid top-level rebuilds each frame
        rebuildAccel = true
    }

    func removeAreaLightInstances() {
        infiniteInstanceList.clearLightSources()

        instanceList.clearLightSources()
    }

    // Render the scene using the specified options, image sampler and display.
    //
    // @param options rendering options object
    // @param sampler image sampler
    // @param display display to send the image to, a default display will
    //            be created if null
    func render(_ options: Options, _ sampler: ImageSampler?, _ display: Display?) {
        stats.reset()

        if bakingInstance != nil {
            UI.printDetailed(.SCENE, "Creating primitives for lightmapping ...")

            bakingPrimitives = bakingInstance!.getBakingPrimitives()

            if bakingPrimitives == nil {
                UI.printError(.SCENE, "Lightmap baking is not supported for the given instance.")

                return
            }

            let n: Int32 = bakingPrimitives!.getNumPrimitives()

            UI.printInfo(.SCENE, "Building acceleration structure for lightmapping (\(n) num primitives) ...")

            bakingAccel = AccelerationStructureFactory.create("auto", n, true)

            bakingAccel!.build(bakingPrimitives!)
        } else {
            bakingPrimitives = nil

            bakingAccel = nil
        }

        bakingViewDependent = options.getBool("baking.viewdep", bakingViewDependent)!

        if (bakingInstance != nil && bakingViewDependent && camera == nil) || (bakingInstance == nil && camera == nil) {
            UI.printError(.SCENE, "No camera found")

            return
        }

        //  read from options
        threads = options.getInt("threads", 0)!
        lowPriority = options.getBool("threads.lowPriority", true)!
        imageWidth = options.getInt("resolutionX", 640)!
        imageHeight = options.getInt("resolutionY", 480)!

        //  limit resolution to 16k
        imageWidth = imageWidth.clamp(1, 1 << 14)
        imageHeight = imageHeight.clamp(1, 1 << 14)

        //  prepare lights
        createAreaLightInstances()

        // prepare ShadingState
        ShadingState.initState(options)

        //  get acceleration structure info
        //  count scene primitives
        var numPrimitives: Int64 = 0

        for i in 0 ..< instanceList.getNumPrimitives() {
            numPrimitives += Int64(instanceList.getNumPrimitives(i))
        }

        UI.printInfo(.SCENE, "Scene stats:")
        UI.printInfo(.SCENE, "  * Infinite instances:  \(infiniteInstanceList.getNumPrimitives())")
        UI.printInfo(.SCENE, "  * Instances:           \(instanceList.getNumPrimitives())")
        UI.printInfo(.SCENE, "  * Primitives:          \(numPrimitives)")

        let accelName: String? = options.getString("accel", nil)

        if accelName != nil {
            rebuildAccel = rebuildAccel || (acceltype != accelName)

            acceltype = accelName!
        }

        UI.printInfo(.SCENE, "  * Instance accel:      \(acceltype)")

        if rebuildAccel {
            intAccel = AccelerationStructureFactory.create(acceltype, instanceList.getNumPrimitives(), false)

            intAccel.build(instanceList)

            rebuildAccel = false
        }

        UI.printInfo(.SCENE, "  * Scene bounds:        \(getBounds())")
        UI.printInfo(.SCENE, "  * Scene center:        \(getBounds().getCenter())")
        UI.printInfo(.SCENE, "  * Scene diameter:      \(getBounds().getExtents().length)")
        UI.printInfo(.SCENE, "  * Lightmap bake:       \(bakingInstance != nil ? (bakingViewDependent ? "view" : "ortho") : "off")")

        if sampler == nil {
            return
        }

        if !lightServer!.build(options) {
            return
        }

        //  render
        UI.printInfo(.BCKT, "Rendering ...")

        stats.setResolution(imageWidth, imageHeight)

        sampler!.prepare(options, self, imageWidth, imageHeight)

        sampler!.render(display!)

        //  show statistics
        stats.displayStats()
        lightServer!.showStats()

        //  discard area lights
        removeAreaLightInstances()

        //  discard baking tesselation/accel structure
        bakingPrimitives = nil
        bakingAccel = nil

        UI.printInfo(.SCENE, "Done.")
    }

    // Create a photon map as prescribed by the given {@link PhotonStore}.
    //
    // @param map object that will recieve shot photons
    // @param type type of photons being shot
    // @param seed QMC seed parameter
    // @return true upon success
    func calculatePhotons(_ map: PhotonStore?, _ type: String, _ seed: Int32, _ options: Options) -> Bool {
        return lightServer!.calculatePhotons(map, type, seed, options)
    }
}
