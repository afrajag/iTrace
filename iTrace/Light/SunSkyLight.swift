//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//
import Foundation

final class SunSkyLight: LightSource, PrimitiveList, Shader {
    var numSkySamples: Int32 = 0
    var basis: OrthoNormalBasis?
    var groundExtendSky: Bool = false
    var groundColor: Color?
    var sunDirWorld: Vector3?
    var turbidity: Float = 0.0
    var sunDir: Vector3?
    var sunSpectralRadiance: SpectralCurve?
    var sunColor: Color?
    var sunTheta: Float = 0.0
    var perezY: [Double] = [Double](repeating: 0, count: 5)
    var perezx: [Double] = [Double](repeating: 0, count: 5)
    var perezy: [Double] = [Double](repeating: 0, count: 5)
    var jacobian: Float = 0.0
    var colHistogram: [Float]?
    var imageHistogram: [[Float]]?

    static var solAmplitudes: [Float] = [165.5, 162.3, 211.2,
                                           258.8, 258.2, 242.3, 267.6, 296.6, 305.4, 300.6, 306.6,
                                           288.3, 287.1, 278.2, 271.0, 272.3, 263.6, 255.0, 250.6,
                                           253.1, 253.5, 251.3, 246.3, 241.7, 236.8, 232.1, 228.2,
                                           223.4, 219.7, 215.3, 211.0, 207.3, 202.4, 198.7, 194.3,
                                           190.7, 186.3, 182.6]

    static var solCurve: RegularSpectralCurve = RegularSpectralCurve(solAmplitudes, 380, 750)

    static var k_oWaveLengths: [Float] = [300, 305, 310, 315, 320, 325, 330, 335, 340, 345, 350, 355, 445, 450, 455, 460, 465, 470, 475, 480, 485, 490, 495, 500, 505, 510, 515, 520, 525, 530, 535, 540, 545, 550, 555, 560, 565, 570, 575, 580, 585, 590, 595, 600, 605, 610, 620, 630, 640, 650, 660, 670, 680, 690, 700, 710, 720, 730, 740, 750, 760, 770, 780, 790]

    static var k_oAmplitudes: [Float] = [10.0, 4.8, 2.7, 1.35,
                                           0.8, 0.380, 0.160, 0.075, 0.04, 0.019, 0.007, 0.0, 0.003, 0.003,
                                           0.004, 0.006, 0.008, 0.009, 0.012, 0.014, 0.017, 0.021, 0.025,
                                           0.03, 0.035, 0.04, 0.045, 0.048, 0.057, 0.063, 0.07, 0.075, 0.08,
                                           0.085, 0.095, 0.103, 0.110, 0.12, 0.122, 0.12, 0.118, 0.115, 0.12,
                                           0.125, 0.130, 0.12, 0.105, 0.09, 0.079, 0.067, 0.057, 0.048, 0.036,
                                           0.028, 0.023, 0.018, 0.014, 0.011, 0.010, 0.009, 0.007, 0.004, 0.0,
                                           0.0]

    static var k_gWaveLengths: [Float] = [759, 760, 770, 771]

    static var k_gAmplitudes: [Float] = [0, 3.0, 0.210, 0]

    static var k_waWaveLengths: [Float] = [689, 690, 700, 710, 720, 730, 740, 750, 760, 770, 780, 790, 800]

    static var k_waAmplitudes: [Float] = [0, 0.160e-1, 0.240e-1,
                                            0.125e-1, 0.100e+1, 0.870, 0.610e-1, 0.100e-2, 0.100e-4,
                                            0.100e-4, 0.600e-3, 0.175e-1, 0.360e-1]

    static var k_oCurve: IrregularSpectralCurve = IrregularSpectralCurve(k_oWaveLengths, k_oAmplitudes)
    static var k_gCurve: IrregularSpectralCurve = IrregularSpectralCurve(k_gWaveLengths, k_gAmplitudes)
    static var k_waCurve: IrregularSpectralCurve = IrregularSpectralCurve(k_waWaveLengths, k_waAmplitudes)

    var zenithY: Double = 0.0
    var zenithx: Double = 0.0
    var zenithy: Double = 0.0

    required init() {
        numSkySamples = 64

        sunDirWorld = Vector3(1, 1, 1)

        turbidity = 6

        basis = OrthoNormalBasis.makeFromWV(Vector3(0, 0, 1), Vector3(0, 1, 0))

        groundExtendSky = false

        groundColor = Color.BLACK

        initSunSky()
    }

    func computeAttenuatedSunlight(_ theta: Float, _ turbidity: Float) -> SpectralCurve {
        var data: [Float] = [Float](repeating: 0, count: 91)

        //  holds the sunsky curve data
        let alpha: Double = 1.3
        let lozone: Double = 0.35
        let w: Double = 2.0
        let beta: Double = 0.04608365822050 * Double(turbidity) - 0.04586025928522

        //  Relative optical mass
        let m: Double = 1.0 / cos(Double(theta)) + 0.00094 * pow(1.6386 - Double(theta), -1.253)

        var i = 0
        var lambda = 350

        while lambda <= 800 {
            //  Rayleigh scattering
            let tauR: Double = exp(-m * 0.008735 * pow(Double(lambda) / 1000.0, -4.08))

            //  Aerosol (water + dust) attenuation
            let tauA: Double = exp(-m * beta * pow(Double(lambda) / 1000.0, -alpha))

            //  Attenuation due to ozone absorption
            let tauO: Double = exp(-m * Double(Self.k_oCurve.sample(Float(lambda))) * lozone)

            //  Attenuation due to mixed gases absorption
            let tauG: Double = exp(-1.41 * Double(Self.k_gCurve.sample(Float(lambda))) * m / pow(1.0 + 118.93 * Double(Self.k_gCurve.sample(Float(lambda))) * m, 0.45))

            //  Attenuation due to water vapor absorptionpow(1.0 + 118.93 * Double(Self.k_gCurve.sample(Float(lambda))) * m, 0.45)
            let tauWA: Double = exp(-0.2385 * Double(Self.k_waCurve.sample(Float(lambda))) * w * m / pow(1.0 + 20.07 * Double(Self.k_waCurve.sample(Float(lambda))) * w * m, 0.45))

            //  100.0 comes from solAmplitudes begin in wrong units.
            let amp: Double = /* 100.0 * */ Double(Self.solCurve.sample(Float(lambda))) * tauR * tauA * tauO * tauG * tauWA

            data[i] = Float(amp)

            i += 1

            lambda += 5
        }

        return RegularSpectralCurve(data, 350, 800)
    }

    func perezFunction(_ lam: [Double], _ theta: Double, _ gamma: Double, _ lvz: Double) -> Double {
        let den = ((1.0 + lam[0] * exp(lam[1])) * (1.0 + lam[2] * exp(lam[3] * Double(sunTheta)) + lam[4] * cos(Double(sunTheta)) * cos(Double(sunTheta))))

        let num: Double = (1.0 + lam[0] * exp(lam[1] / cos(theta))) * (1.0 + lam[2] * exp(lam[3] * gamma) + lam[4] * cos(gamma) * cos(gamma))

        return lvz * num / den
    }

    func initSunSky() {
        let t: TraceTimer = TraceTimer()

        t.start()
        
        //  perform all the required initialization of constants
        sunDirWorld!.normalize()

        sunDir = basis!.untransform(sunDirWorld!, Vector3())

        sunDir!.normalize()

        sunTheta = Float(acos(sunDir!.z.clamp(-1, 1)))

        if sunDir!.z > 0 {
            sunSpectralRadiance = computeAttenuatedSunlight(sunTheta, turbidity)

            //  produce color suitable for rendering
            sunColor = RGBSpace.SRGB.convertXYZtoRGB(sunSpectralRadiance!.toXYZ().mul(1e-4)).constrainRGB()
        } else {
            sunSpectralRadiance = ConstantSpectralCurve(0)
        }

        //  sunSolidAngle = (float) (0.25 * Double.Pi * 1.39 * 1.39 / (150 * 150));
        let theta2: Float = sunTheta * sunTheta
        let theta3: Float = sunTheta * theta2
        let T: Float = turbidity
        let T2: Float = turbidity * turbidity

        let chi: Double = (4.0 / 9.0 - Double(T) / 120.0) * (Double.pi - 2.0 * Double(sunTheta))

        zenithY = (4.0453 * Double(T) - 4.971) * tan(chi) - 0.2155 * Double(T) + 2.4192

        zenithY *= 1000 //  conversion from kcd/m^2 to cd/m^2

        let _zx = ((0.00165 * theta3 - 0.00374 * theta2 + 0.00208 * sunTheta + 0) * T2)
        let _zx0 = (0.11693 * theta3 - 0.21196 * theta2 + 0.06052 * sunTheta + 0.25885)
        let _zx1 = ((-0.02902 * theta3 + 0.06377 * theta2 - 0.03202 * sunTheta + 0.00394) * T)

        zenithx = Double(_zx + // ((0.00165 * theta3 - 0.00374 * theta2 + 0.00208 * sunTheta + 0) * T2) +
            _zx1 + // ((-0.02902 * theta3 + 0.06377 * theta2 - 0.03202 * sunTheta + 0.00394) * T) +
            _zx0) // (0.11693 * theta3 - 0.21196 * theta2 + 0.06052 * sunTheta + 0.25885)

        let _zy = ((0.00275 * theta3 - 0.00610 * theta2 + 0.00316 * sunTheta + 0) * T2)
        let _zy0 = (0.15346 * theta3 - 0.26756 * theta2 + 0.06669 * sunTheta + 0.26688)
        let _zy1 = ((-0.04212 * theta3 + 0.08970 * theta2 - 0.04153 * sunTheta + 0.00515) * T)

        zenithy = Double(_zy + // ((0.00275 * theta3 - 0.00610 * theta2 + 0.00316 * sunTheta + 0) * T2) +
            _zy1 + // ((-0.04212 * theta3 + 0.08970 * theta2 - 0.04153 * sunTheta + 0.00515) * T) +
            _zy0) // (0.15346 * theta3 - 0.26756 * theta2 + 0.06669 * sunTheta + 0.26688)

        perezY[0] = Double(0.17872 * T - 1.46303)
        perezY[1] = Double(-0.3554 * T + 0.42749)
        perezY[2] = Double(-0.02266 * T + 5.32505)
        perezY[3] = Double(0.12064 * T - 2.57705)
        perezY[4] = Double(-0.06696 * T + 0.37027)
        perezx[0] = Double(-0.01925 * T - 0.25922)
        perezx[1] = Double(-0.06651 * T + 0.00081)
        perezx[2] = Double(-0.00041 * T + 0.21247)
        perezx[3] = Double(-0.06409 * T - 0.89887)
        perezx[4] = Double(-0.00325 * T + 0.04517)
        perezy[0] = Double(-0.01669 * T - 0.26078)
        perezy[1] = Double(-0.09495 * T + 0.00921)
        perezy[2] = Double(-0.00792 * T + 0.21023)
        perezy[3] = Double(-0.04405 * T - 1.65369)
        perezy[4] = Double(-0.01092 * T + 0.05291)

        let w: Int = 32
        let h: Int = 32

        var colHistogram: [Float]? = [Float](repeating: 0, count: w)
        var imageHistogram: [[Float]]? = [[Float]](repeating: [Float](repeating: 0, count: h), count: w)

        let du: Float = 1.0 / Float(w)
        let dv: Float = 1.0 / Float(h)

        for x in 0 ..< w {
            for y in 0 ..< h {
                let u: Float = (Float(x) + 0.5) * du
                let v: Float = (Float(y) + 0.5) * dv
                let c: Color = getSkyRGB(getDirection(u, v))

                imageHistogram![x][y] = c.getLuminance() * sin(Float.pi * v)

                if y > 0 {
                    imageHistogram![x][y] += imageHistogram![x][y - 1]
                }
            }

            colHistogram![x] = imageHistogram![x][h - 1]

            if x > 0 {
                colHistogram![x] += colHistogram![x - 1]
            }

            for y in 0 ..< h {
                imageHistogram![x][y] /= imageHistogram![x][h - 1]
            }
        }

        for x in 0 ..< w {
            colHistogram![x] /= colHistogram![w - 1]
        }

        jacobian = (2 * Float.pi * Float.pi) / Float(w * h)
        
        self.colHistogram = colHistogram
        self.imageHistogram = imageHistogram
        
        t.end()

        UI.printDetailed(.IMG, "  * Sunsky histogram creation time:  \(t.toString())")
    }

    func update(_ pl: ParameterList) -> Bool {
        let up: Vector3? = pl.getVector(SunSkyLightParameter.PARAM_UP, nil)
        let east: Vector3? = pl.getVector(SunSkyLightParameter.PARAM_EAST, nil)

        if up != nil, east != nil {
            basis = OrthoNormalBasis.makeFromWV(up!, east!)
        } else if up != nil {
            basis = OrthoNormalBasis.makeFromW(up!)
        }

        numSkySamples = pl.getInt(LightParameter.PARAM_SAMPLES, numSkySamples)!
        sunDirWorld = pl.getVector(SunSkyLightParameter.PARAM_SUN_DIRECTION, sunDirWorld)!
        turbidity = pl.getFloat(SunSkyLightParameter.PARAM_TURBIDITY, turbidity)!
        groundExtendSky = pl.getBool(SunSkyLightParameter.PARAM_GROUND_EXTENDSKY, groundExtendSky)!
        groundColor = pl.getColor(SunSkyLightParameter.PARAM_GROUND_COLOR, groundColor)!

        //  recompute model
        initSunSky()

        return true
    }

    func getSkyRGB(_ dir: Vector3) -> Color {
        if dir.z < 0, !groundExtendSky {
            return groundColor!
        }

        if dir.z < 0.001 {
            dir.z = 0.001
        }

        dir.normalize()

        let theta: Double = Double(acos(dir.z.clamp(-1, 1)))
        let gamma: Double = Double(acos(Vector3.dot(dir, sunDir!).clamp(-1, 1)))
        let x: Double = perezFunction(perezx, theta, gamma, zenithx)
        let y: Double = perezFunction(perezy, theta, gamma, zenithy)
        let Y: Double = perezFunction(perezY, theta, gamma, zenithY) * 1e-4
        let c: XYZColor = ChromaticitySpectrum.get(Float(x), Float(y))
        //  XYZColor c = new ChromaticitySpectrum((float) x, (float) y).toXYZ();
        let X: Float = Float(c.getX() * Float(Y) / c.getY())
        let Z: Float = Float(c.getZ() * Float(Y) / c.getY())

        return RGBSpace.SRGB.convertXYZtoRGB(X, Float(Y), Z)
    }

    func getNumSamples() -> Int32 {
        return 1 + numSkySamples
    }

    func getPhoton(_: Double, _: Double, _: Double, _: Double, _: Point3, _: Vector3, _: Color) {
        //  FIXME: not implemented
    }

    func getPower() -> Float {
        return 0
    }

    func getSamples(_ state: ShadingState) {
        // FIXME: controllare se con variabili locali le performance aumentano
        let numSkySamples: Int32 = self.numSkySamples
        let basis: OrthoNormalBasis? = self.basis
        let sunDirWorld: Vector3? = self.sunDirWorld
        let sunColor: Color? = self.sunColor
        let jacobian: Float = self.jacobian
        let colHistogram: [Float]? = self.colHistogram
        let imageHistogram: [[Float]]? = self.imageHistogram
        
        if Vector3.dot(sunDirWorld!, state.getGeoNormal()!) > 0, Vector3.dot(sunDirWorld!, state.getNormal()!) > 0 {
            let dest: LightSample = LightSample()

            dest.setShadowRay(Ray(state.getPoint(), sunDirWorld!))

            dest.getShadowRay().setMax(Float.greatestFiniteMagnitude)

            dest.setRadiance(sunColor!, sunColor!)

            dest.traceShadow(state)

            state.addSample(dest)
        }

        let n: Int = state.getDiffuseDepth() > 0 ? 1 : Int(numSkySamples)

        for i in 0 ..< n {
            //  random offset on unit square, we use the infinite version of
            //  getRandom because the light sampling is adaptive
            let randX: Double = state.getRandom(Int32(i), 0, Int32(n))
            let randY: Double = state.getRandom(Int32(i), 1, Int32(n))

            var x: Int = 0

            while randX >= Double(colHistogram![x]), x < colHistogram!.count - 1 {
                x += 1
            }

            let rowHistogram: [Float] = imageHistogram![x]

            var y: Int = 0

            while randY >= Double(rowHistogram[y]), y < rowHistogram.count - 1 {
                y += 1
            }

            //  sample from (x, y)
            var u: Float = 0.0

            if x == 0 {
                u = (Float(randX) / colHistogram![0])
            } else {
                u = ((Float(randX) - colHistogram![x - 1]) / (colHistogram![x] - colHistogram![x - 1]))
            }

            var v: Float = 0.0

            if y == 0 {
                v = (Float(randY) / rowHistogram[0])
            } else {
                v = ((Float(randY) - rowHistogram[y - 1]) / (rowHistogram[y] - rowHistogram[y - 1]))
            }

            let px: Float = (x == 0 ? colHistogram![0] : colHistogram![x] - colHistogram![x - 1])
            let py: Float = (y == 0 ? rowHistogram[0] : rowHistogram[y] - rowHistogram[y - 1])

            let su: Float = (Float(x) + u) / Float(colHistogram!.count)
            let sv: Float = (Float(y) + v) / Float(rowHistogram.count)

            let invP: Float = sin(sv * Float.pi) * jacobian / (Float(n) * px * py)

            let localDir: Vector3 = getDirection(su, sv)

            let dir: Vector3 = basis!.transform(localDir, Vector3())

            if Vector3.dot(dir, state.getGeoNormal()!) > 0, Vector3.dot(dir, state.getNormal()!) > 0 {
                let dest: LightSample = LightSample()

                dest.setShadowRay(Ray(state.getPoint(), dir))

                dest.getShadowRay().setMax(Float.greatestFiniteMagnitude)

                let radiance: Color = getSkyRGB(localDir)

                dest.setRadiance(radiance, radiance)

                dest.getDiffuseRadiance().mul(invP)

                dest.getSpecularRadiance().mul(invP)

                dest.traceShadow(state)

                state.addSample(dest)
            }
        }
    }

    func getBakingPrimitives() -> PrimitiveList? {
        return nil
    }

    func getNumPrimitives() -> Int32 {
        return 1
    }

    func getPrimitiveBound(_: Int32, _: Int32) -> Float {
        return 0
    }

    func getWorldBounds(_: AffineTransform?) -> BoundingBox? {
        return nil
    }

    func intersectPrimitive(_ r: Ray, _: Int32, _ state: IntersectionState) {
        if r.getMax() == Float.infinity {
            state.setIntersection(0)
        }
    }

    func prepareShadingState(_ state: ShadingState) {
        if state.getIncludeLights() {
            state.setShader(self)
        }
    }

    func getRadiance(_ state: ShadingState) -> Color {
        return getSkyRGB(basis!.untransform(state.getRay()!.getDirection())).constrainRGB()
    }

    func scatterPhoton(_: ShadingState, _: Color) {
        //  let photon escape
    }

    func getDirection(_ u: Float, _ v: Float) -> Vector3 {
        let dest: Vector3 = Vector3()
        var phi: Double = 0
        var theta: Double = 0

        theta = Double(u) * 2 * Double.pi

        phi = Double(v) * Double.pi

        let sin_phi: Double = sin(phi)

        dest.x = Float(-sin_phi * cos(theta))
        dest.y = Float(cos(phi))
        dest.z = Float(sin_phi * sin(theta))

        return dest
    }

    func createInstance() -> Instance? {
        return Instance.createTemporary(self, nil, self)!
    }
}
