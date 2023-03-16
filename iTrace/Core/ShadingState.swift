//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//
import Foundation

final class ShadingState {
    var istate: IntersectionState?
    var server: LightServer?
    var result: Color?
    var p: Point3?
    var n: Vector3?
    var tex: Point2?
    var ng: Vector3?
    var basis: OrthoNormalBasis?
    var cosND: Float = 0.0
    var bias: Float = 0.0
    var behind: Bool = false
    var instance: Instance?
    var primitiveID: Int32 = 0
    var r: Ray?
    var d: Int32 = 0
    var i: Int32 = 0
    var qmcD0I: Double = 0.0
    var qmcD1I: Double = 0.0
    var shader: Shader?
    var modifier: Modifier?
    var diffuseDepth: Int32 = 0
    var reflectionDepth: Int32 = 0
    var refractionDepth: Int32 = 0
    var includeLights: Bool = false
    var includeSpecular: Bool = false
    var lightSampleList: [LightSample] = [LightSample]()
    var map: PhotonStore?
    var rx: Float = 0.0
    var ry: Float = 0.0
    var time: Float = 0.0
    var hitU: Float = 0.0
    var hitV: Float = 0.0
    var hitW: Float = 0.0
    var o2w: AffineTransform?
    var w2o: AffineTransform?

    static var minBias: Float = 0.001

    static func initState(_ options: Options) {
        minBias = options.getFloat("bias", 0.001)!
    }

    // Create objects needed for surface shading: point, normal, texture
    // coordinates and basis.
    func initState() {
        p = Point3()
        n = Vector3()
        tex = Point2()
        ng = Vector3()

        basis = nil
    }

    private init(_ previous: ShadingState?, _ istate: IntersectionState, _ r: Ray, _ i: Int32, _ d: Int32) {
        self.r = r
        self.istate = istate
        self.i = i
        self.d = d

        time = istate.time

        instance = istate.instance! //  local copy

        primitiveID = istate.id

        hitU = istate.u
        hitV = istate.v
        hitW = istate.w

        //  get matrices for current time
        o2w = instance!.getObjectToWorld(time)
        w2o = instance!.getWorldToObject(time)

        if previous == nil {
            diffuseDepth = 0
            reflectionDepth = 0
            refractionDepth = 0
        } else {
            diffuseDepth = previous!.diffuseDepth
            reflectionDepth = previous!.reflectionDepth
            refractionDepth = previous!.refractionDepth

            server = previous!.server

            map = previous!.map

            rx = previous!.rx
            ry = previous!.ry

            self.i += previous!.i
            self.d += previous!.d
        }

        behind = false

        cosND = Float.nan

        includeLights = true
        includeSpecular = true

        qmcD0I = QMC.halton(self.d, self.i)
        qmcD1I = QMC.halton(self.d + 1, self.i)

        result = nil

        bias = Self.minBias
    }

    static func createPhotonState(_ r: Ray, _ istate: IntersectionState, _ i: Int32, _ map: PhotonStore, _ server: LightServer) -> ShadingState {
        let s: ShadingState = ShadingState(nil, istate, r, i, 4)

        s.server = server
        s.map = map

        return s
    }

    static func createState(_ istate: IntersectionState, _ rx: Float, _ ry: Float, _ time: Float, _ r: Ray, _ i: Int32, _ d: Int32, _ server: LightServer!) -> ShadingState {
        let s: ShadingState = ShadingState(nil, istate, r, i, d)

        s.server = server
        s.rx = rx
        s.ry = ry
        s.time = time

        return s
    }

    static func createDiffuseBounceState(_ previous: ShadingState, _ r: Ray, _ i: Int32) -> ShadingState {
        let s: ShadingState = ShadingState(previous, previous.istate!, r, i, 2)

        s.diffuseDepth += 1

        return s
    }

    static func createGlossyBounceState(_ previous: ShadingState, _ r: Ray, _ i: Int32) -> ShadingState {
        let s: ShadingState = ShadingState(previous, previous.istate!, r, i, 2)

        s.includeLights = false
        s.includeSpecular = false

        s.reflectionDepth += 1

        return s
    }

    static func createReflectionBounceState(_ previous: ShadingState, _ r: Ray, _ i: Int32) -> ShadingState {
        let s: ShadingState = ShadingState(previous, previous.istate!, r, i, 2)

        s.reflectionDepth += 1

        return s
    }

    static func createRefractionBounceState(_ previous: ShadingState, _ r: Ray, _ i: Int32) -> ShadingState {
        let s: ShadingState = ShadingState(previous, previous.istate!, r, i, 2)

        s.refractionDepth += 1

        return s
    }

    static func createFinalGatherState(_ state: ShadingState, _ r: Ray, _ i: Int32) -> ShadingState {
        let finalGatherState: ShadingState = ShadingState(state, state.istate!, r, i, 2)

        finalGatherState.diffuseDepth += 1

        finalGatherState.includeLights = false
        finalGatherState.includeSpecular = false

        return finalGatherState
    }

    func setRay(_ r: Ray) {
        self.r = r
    }

    // Run the shader! at this surface point.
    //
    // @return shaded result
    func shade() -> Color {
        return server!.shadeHit(self)
    }

    func correctShadingNormal() {
        //  correct shading normals pointing the wrong way
        if Vector3.dot(n!, ng!) < 0 {
            n!.negate()

            basis!.flipW()
        }
    }

    // Flip the surface normals to ensure they are facing the current ray!. This
    // method also offsets the shading point away from the surface so that new
    // ray!s will not intersect the same surface again by mistake.
    func faceforward() {
        //  make sure we are on the right side of the material
        if r!.dot(ng!) < 0 {
        } else {
            //  this ensure the ray! and the geomtric normal are pointing in the
            //  same direction
            ng!.negate()
            n!.negate()

            basis!.flipW()

            behind = true
        }

        cosND = max(-r!.dot(n!), 0) //  can't be negative

        //  offset the shaded point away from the surface to prevent
        //  self-intersection errors
        // FIXME: ma che e' !?
        // bias = max(bias, 25.0 * Float.ulpOfOne)
        if abs(ng!.x) > abs(ng!.y) && abs(ng!.x) > abs(ng!.z) {
            bias = max(bias, 25 * abs(p!.x).ulp)
        } else if abs(ng!.y) > abs(ng!.z) {
            bias = max(bias, 25 * abs(p!.y).ulp)
        } else {
            bias = max(bias, 25 * abs(p!.z).ulp)
        }

        p!.x += bias * ng!.x
        p!.y += bias * ng!.y
        p!.z += bias * ng!.z
    }

    // Get x coordinate of the pixel being shaded.
    //
    // @return pixel x coordinate
    func getRasterX() -> Float {
        return rx
    }

    // Get y coordinate of the pixel being shaded.
    //
    // @return pixel y coordinate
    func getRasterY() -> Float {
        return ry
    }

    // Cosine between the shading normal and the ray!. This is set by
    // {@link #faceforward()}.
    //
    // @return cosine between shading normal and the ray!
    func getCosND() -> Float {
        return cosND
    }

    // Returns true if the ray! hit the surface from behind. This is set by
    // {@link #faceforward()}.
    //
    // @return true if the surface was hit from behind.
    func isBehind() -> Bool {
        return behind
    }

    func getIntersectionState() -> IntersectionState? {
        return istate
    }

    // Get u barycentric coordinate of the intersection point.
    //
    // @return u barycentric coordinate
    func getU() -> Float {
        return hitU
    }

    // Get v barycentric coordinate of the intersection point.
    //
    // @return v barycentric coordinate
    func getV() -> Float {
        return hitV
    }

    //      	 * Get w barycentric coordinate of the intersection point.
    //      	 *
    //      	 * @return w barycentric coordinate
    func getW() -> Float {
        return hitW
    }

    // Get the instance which was intersected
    //
    // @return intersected instance object
    func getInstance() -> Instance? {
        return instance
    }

    // Get the primitive ID which was intersected
    //
    // @return intersected primitive ID
    func getPrimitiveID() -> Int32 {
        return primitiveID
    }

    // Transform the given point from object space to world space. A new
    //  		 * {@link Point3} object is returned.
    //  		 *
    // @param p object space position to transform
    // @return transformed position
    func transformObjectToWorld(_ p: Point3) -> Point3 {
        return (o2w == nil ? Point3(p) : o2w!.transformP(p))
    }

    //  	 	 * Transform the given point from world space to object space. A new
    //  		 * {@link Point3} object is returned.
    //
    // @param p world space position to transform
    // @return transformed position
    func transformWorldToObject(_ p: Point3) -> Point3 {
        return (w2o == nil ? Point3(p) : w2o!.transformP(p))
    }

    // Transform the given normal from object space to world space. A new
    // {@link Vector3} object is returned.
    //
    // @param n object space normal to transform
    // @return transformed normal
    func transformNormalObjectToWorld(_ n: Vector3) -> Vector3 {
        return (o2w == nil ? Vector3(n) : w2o!.transformTransposeV(n))
    }

    // Transform the given normal from world space to object space. A new
    // {@link Vector3} object is returned.
    //
    // @param n world space normal to transform
    // @return transformed normal
    func transformNormalWorldToObject(_ n: Vector3) -> Vector3 {
        return (o2w == nil ? Vector3(n) : o2w!.transformTransposeV(n))
    }

    // Transform the given vector from object space to world space. A new
    // {@link Vector3} object is returned.
    //
    // @param v object space vector to transform
    // @return transformed vector
    func transformVectorObjectToWorld(_ v: Vector3) -> Vector3 {
        return (o2w == nil ? Vector3(v) : o2w!.transformV(v))
    }

    //  		 * Transform the given vector from world space to object space. A new
    // {@link Vector3} object is returned.
    //
    // @param v world space vector to transform
    // @return transformed vector
    func transformVectorWorldToObject(_ v: Vector3) -> Vector3 {
        return (o2w == nil ? Vector3(v) : w2o!.transformV(v))
    }

    func setResult(_ c: Color) {
        result = c
    }

    // Get the result! of shading this point
    //
    // @return shaded result!
    func getResult() -> Color? {
        return result
    }

    func getLightServer() -> LightServer? {
        return server
    }

    // Add the specified light sample to the list of lights to be used
    //
    // @param sample a valid light sample
    func addSample(_ sample: LightSample) {
        //  add to list
        lightSampleList.insert(sample, at: 0)
        // sample.next = lightSample
        // lightSample = sample
    }

    // Get a QMC sample from an infinite sequence.
    //
    // @param j sample number (starts from 0)
    // @param dim dimension to sample
    // @return pseudo-random value in [0,1)
    func getRandom(_ j: Int32, _ dim: Int32) -> Double {
        switch dim {
        case 0:
            return QMC.mod1(qmcD0I + QMC.halton(0, j))
        case 1:
            return QMC.mod1(qmcD1I + QMC.halton(1, j))
        default:
            return QMC.mod1(QMC.halton(d + dim, i) + QMC.halton(dim, j))
        }
    }

    // Get a QMC sample from a finite sequence of n elements. This provides
    // better stratification than the infinite version, but does not allow for
    // adaptive sampling.
    //
    // @param j sample number (starts from 0)
    // @param dim dimension to sample
    // @param n number of samples
    // @return pseudo-random value in [0,1)
    func getRandom(_ j: Int32, _ dim: Int32, _ n: Int32) -> Double {
        switch dim {
        case 0:
            return QMC.mod1(qmcD0I + (Double(j) / Double(n)))
        case 1:
            return QMC.mod1(qmcD1I + QMC.halton(0, j))
        default:
            return QMC.mod1(QMC.halton(d + dim, i) + QMC.halton(dim - 1, j))
        }
    }

    //
    // Checks to see if the shader should include emitted light.
    //
    // @return true if emitted light should be included,
    //         false otherwise
    //
    func getIncludeLights() -> Bool {
        return includeLights
    }

    //
    // Checks to see if the shader should include specular terms.
    //
    // @return true if specular terms should be included,
    //         false otherwise
    //
    func getIncludeSpecular() -> Bool {
        return includeSpecular
    }

    // Get the shader to be used to shade this surface.
    //
    // @return shader! to be used
    func getShader() -> Shader? {
        return shader
    }

    // Record which shader! should be executed for the intersected surface.
    //
    // @param shader! surface shader! to use to shade the current intersection
    //            point
    func setShader(_ shader: Shader?) {
        self.shader = shader
    }

    func getModifier() -> Modifier? {
        return modifier
    }

    // Record which modifier! should be applied to the intersected surface
    //
    // @param modifier! modifier! to use the change this shading state
    func setModifier(_ modifier: Modifier?) {
        self.modifier = modifier
    }

    // Get the current total tracing depth. First generation ray!s have a depth
    // of 0.
    //
    // @return current tracing depth
    func getDepth() -> Int32 {
        return diffuseDepth + reflectionDepth + refractionDepth
    }

    // Get the current diffuse tracing depth. This is the number of diffuse
    // surfaces reflected from.
    //
    // @return current diffuse tracing depth
    func getDiffuseDepth() -> Int32 {
        return diffuseDepth
    }

    // Get the current reflection tracing depth. This is the number of specular
    // surfaces reflected from.
    //
    // @return current reflection tracing depth
    func getReflectionDepth() -> Int32 {
        return reflectionDepth
    }

    // Get the current refraction tracing depth. This is the number of specular
    // surfaces refracted from.
    //
    // @return current refraction tracing depth
    func getRefractionDepth() -> Int32 {
        return refractionDepth
    }

    // Get hit point.
    //
    // @return hit point
    func getPoint() -> Point3 {
        return p!
    }

    // Get shading normal at the hit point. This may differ from the geometric
    // normal
    //
    // @return shading normal
    func getNormal() -> Vector3? {
        return n
    }

    // Get texture coordinates at the hit point.
    //
    // @return texture coordinate
    func getUV() -> Point2? {
        return tex
    }

    // Gets the geometric normal of the current hit point.
    //
    // @return geometric normal of the current hit point
    func getGeoNormal() -> Vector3? {
        return ng
    }

    // Gets the local orthonormal basis for the current hit point.
    //
    // @return local basis or null if undefined
    func getBasis() -> OrthoNormalBasis? {
        return basis
    }

    // Define the orthonormal basis for the current hit point.
    //
    // @param basis
    func setBasis(_ basis: OrthoNormalBasis) {
        self.basis = basis
    }

    // Gets the ray that is associated with this state.
    //
    // @return ray associated with this state.
    func getRay() -> Ray? {
        return r
    }

    // Get a transformation matrix that will transform camera space points into
    // world space.
    //
    // @return camera to world transform
    func getCameraToWorld() -> AffineTransform {
        let c: CameraBase? = server!.getScene()!.getCamera()!

        return (c != nil ? c!.getCameraToWorld(time) : AffineTransform.IDENTITY)
    }

    // Get a transformation matrix that will transform world space points into
    // camera space.
    //
    // @return world to camera transform
    func getWorldToCamera() -> AffineTransform {
        let c: CameraBase? = server!.getScene()!.getCamera()!

        return (c != nil ? c!.getWorldToCamera(time) : AffineTransform.IDENTITY)
    }

    // Get the three triangle corners in object space if the hit object is a
    // mesh, returns false otherwise.
    //
    // @param p array of 3 points
    // @return true if the points were read succesfully,
    //         falseotherwise
    func getTrianglePoints() -> [Point3]? {
        let prims: PrimitiveList? = instance!.getGeometry()!.getPrimitiveList()

        if prims is TriangleMesh {
            let m: TriangleMesh = prims as! TriangleMesh

            let _p0 = Point3()
            let _p1 = Point3()
            let _p2 = Point3()

            m.getPoint(primitiveID, 0, _p0)
            m.getPoint(primitiveID, 1, _p1)
            m.getPoint(primitiveID, 2, _p2)

            return [_p0, _p1, _p2]
        }

        return nil
    }

    // Initialize the use of light samples. Prepares a list of visible lights
    // from the current point.
    func initLightSamples() {
        server!.initLightSamples(self)
    }

    // Add caustic samples to the current light sample set. This method does
    // nothing if caustics are not enabled.
    func initCausticSamples() {
        server!.initCausticSamples(self)
    }

    // Returns the color obtained by recursively tracing the specified ray!. The
    // reflection is assumed to be glossy.
    //
    // @param r ray to trace
    // @param i instance number of this sample
    // @return color observed along specified ray!.
    func traceGlossy(_ r: Ray, _ i: Int32) -> Color {
        return server!.traceGlossy(self, r, i)
    }

    // Returns the color obtained by recursively tracing the specified ray!. The
    // reflection is assumed to be specular.
    //
    // @param r ray to trace
    // @param i instance number of this sample
    // @return color observed along specified ray!.
    func traceReflection(_ r: Ray, _ i: Int32) -> Color {
        return server!.traceReflection(self, r, i)
    }

    // Returns the color obtained by recursively tracing the specified ray.
    //
    // @param r ray to trace
    // @param i instance number of this sample
    // @return color observed along specified ray!.
    func traceRefraction(_ r: Ray, _ i: Int32) -> Color {
        //  this assumes the refraction ray is pointing away from the normal
        r.ox -= 2.0 * bias * ng!.x
        r.oy -= 2.0 * bias * ng!.y
        r.oz -= 2.0 * bias * ng!.z

        return server!.traceRefraction(self, r, i)
    }

    // Trace transparency, this is equivalent to tracing a refraction ray in the
    // incoming ray direction.
    //
    // @return color observed behind the current shading point
    func traceTransparency() -> Color {
        return traceRefraction(Ray(p!.x, p!.y, p!.z, r!.dx, r!.dy, r!.dz), 0)
    }

    // Trace a shadow ray! against the scene, and computes the accumulated
    // opacity along the ray.
    //
    // @param r ray to trace
    // @return opacity along the shadow ray!
    func traceShadow(_ r: Ray) -> Color {
        return server!.getScene()!.traceShadow(r, istate!)
    }

    // Records a photon at the specified location.
    //
    // @param dir incoming direction of the photon
    // @param power photon power
    // @param diffuse diffuse reflectance at the given point
    func storePhoton(_ dir: Vector3, _ power: Color, _ diffuse: Color) {
        map!.store(self, dir, power, diffuse)
    }

    // Trace a new photon from the current location. This assumes that the
    // photon was reflected by a specular surface.
    //
    // @param r ray to trace photon along
    // @param power power of the new photon
    func traceReflectionPhoton(_ r: Ray, _ power: Color) {
        if map!.allowReflectionBounced() {
            server!.traceReflectionPhoton(self, r, power)
        }
    }

    // Trace a new photon from the current location. This assumes that the
    // photon was refracted by a specular surface.
    //
    // @param r ray to trace photon along
    // @param power power of the new photon
    func traceRefractionPhoton(_ r: Ray, _ power: Color) {
        if map!.allowRefractionBounced() {
            //  this assumes the refraction ray! is pointing away from the normal
            r.ox -= 0.002 * ng!.x
            r.oy -= 0.002 * ng!.y
            r.oz -= 0.002 * ng!.z

            server!.traceRefractionPhoton(self, r, power)
        }
    }

    // Trace a new photon from the current location. This assumes that the
    // photon was reflected by a diffuse surface.
    //
    // @param r ray to trace photon along
    // @param power power of the new photon
    func traceDiffusePhoton(_ r: Ray, _ power: Color) {
        if map!.allowDiffuseBounced() {
            server!.traceDiffusePhoton(self, r, power)
        }
    }

    // Returns the glboal diffuse radiance estimate given by the current
    // {@link GIEngine} if present.
    //
    // @return global diffuse radiance estimate
    func getGlobalRadiance() -> Color {
        return server!.getGlobalRadiance(self)
    }

    // Gets the total irradiance reaching the current point from diffuse
    // surfaces.
    //
    // @param diffuseReflectance diffuse reflectance at the current point, can
    //            be used for importance tracking
    // @return indirect diffuse irradiance reaching the point
    func getIrradiance(_ diffuseReflectance: Color) -> Color {
        return server!.getIrradiance(self, diffuseReflectance)
    }

    // Trace a gather ray and return the intersection result as a new
    // render state
    //
    // @param r ray to shoot
    // @param i instance of the ray
    // @return new render state object corresponding to the intersection result
    func traceFinalGather(_ r: Ray, _ i: Int32) -> ShadingState? {
        return server!.traceFinalGather(self, r, i)
    }

    // Simple black and white ambient occlusion.
    //
    // @param samples number of sample rays
    // @param maxDist maximum Length of the ray!s
    // @return occlusion color
    func occlusion(_ samples: Int32, _ maxDist: Float) -> Color {
        return occlusion(samples, maxDist, Color.WHITE, Color.BLACK)
    }

    // Ambient occlusion routine, returns a value between bright and dark
    // depending on the amount of geometric occlusion in the scene.
    //
    // @param samples number of sample rays
    // @param maxDist maximum Length of the rays
    // @param bright color when nothing is occluded
    // @param dark color when fully occluded
    // @return occlusion color
    func occlusion(_ samples: Int32, _ maxDist: Float, _ bright: Color, _ dark: Color) -> Color {
        if n == nil {
            //  in case we got called on a geometry without orientation
            return bright
        }

        //  make sure we are on the right side of the material
        faceforward()

        let onb: OrthoNormalBasis? = getBasis()
        let w: Vector3 = Vector3()
        let result: Color = Color.black()

        for i in 0 ..< samples {
            let xi: Float = Float(getRandom(i, 0, samples))
            let xj: Float = Float(getRandom(i, 1, samples))
            let phi: Float = 2 * Float.pi * xi
            let cosPhi: Float = cos(phi)
            let sinPhi: Float = sin(phi)
            let sinTheta: Float = sqrt(xj)
            let cosTheta: Float = sqrt(1.0 - xj)

            w.x = cosPhi * sinTheta
            w.y = sinPhi * sinTheta
            w.z = cosTheta

            onb!.transform(w)

            let r: Ray = Ray(p!, w)

            r.setMax(maxDist)

            result.add(Color.blend(bright, dark, traceShadow(r)))
        }

        return result.mul(1.0 / Float(samples))
    }

    // Computes a plain diffuse response to the current light samples and global
    // illumination.
    //
    // @param diff diffuse color
    // @return shaded result!
    func diffuse(_ diff: Color) -> Color {
        //  integrate a diffuse function
        let lr: Color = Color.black()

        if diff.isBlack() {
            return lr
        }

        for sample in lightSampleList {
            lr.madd(sample.dot(n!), sample.getDiffuseRadiance())
        }

        lr.add(getIrradiance(diff))

        return lr.mul(diff).mul(1.0 / Float.pi)
    }

    // Computes a phong specular response to the current light samples and
    // global illumination.
    //
    // @param spec specular color
    // @param power phong exponent
    // @param numray!s number of glossy ray!s to trace
    // @return shaded color
    func specularPhong(_ spec: Color, _ power: Float, _ numRays: Int32) -> Color {
        //  integrate a phong specular function
        let lr: Color = Color.black()

        if !includeSpecular || spec.isBlack() {
            return lr
        }

        //  reflected direction
        let dn: Float = 2 * cosND
        let refDir: Vector3 = Vector3()

        refDir.x = (dn * n!.x) + r!.dx
        refDir.y = (dn * n!.y) + r!.dy
        refDir.z = (dn * n!.z) + r!.dz

        //  direct lighting
        for sample in lightSampleList {
            let cosNL: Float = sample.dot(n!)
            let cosLR: Float = sample.dot(refDir)

            if cosLR > 0 {
                lr.madd(cosNL * Float(pow(cosLR, power)), sample.getSpecularRadiance())
            }
        }

        //  indirect lighting
        if numRays > 0 {
            let numSamples: Int32 = (getDepth() == 0 ? numRays : 1)
            let onb: OrthoNormalBasis = OrthoNormalBasis.makeFromW(refDir)
            let mul: Float = (2.0 * Float.pi / (power + 1)) / Float(numSamples)

            for i in 0 ..< numSamples {
                //  specular indirect lighting
                let r1: Double = getRandom(i, 0, numSamples)
                let r2: Double = getRandom(i, 1, numSamples)
                let u: Double = 2 * Double.pi * r1
                let s: Double = Double(pow(Float(r2), 1 / (power + 1)))
                let s1: Double = Double(sqrt(1 - (s * s)))

                var w: Vector3 = Vector3(Float(cos(u) * s1), Float(sin(u) * s1), Float(s))

                w = onb.transform(w, Vector3())

                let wn: Float = Vector3.dot(w, n!)

                if wn > 0 {
                    lr.madd(wn * mul, traceGlossy(Ray(p!, w), i))
                }
            }
        }

        lr.mul(spec).mul((power + 2) / (2.0 * Float.pi))

        return lr
    }
}
