//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//
import Foundation

final class CornellBox: PrimitiveList, Shader, LightSource {
    var radiance: Color?
    var samples: Int32 = 0
    var area: Float = 0.0
    var lightBounds: BoundingBox?
    var minX: Float = 0.0
    var minY: Float = 0.0
    var minZ: Float = 0.0
    var maxX: Float = 0.0
    var maxY: Float = 0.0
    var maxZ: Float = 0.0
    var left: Color?
    var right: Color?
    var top: Color?
    var bottom: Color?
    var back: Color?
    var lxmin: Float = 0.0
    var lymin: Float = 0.0
    var lxmax: Float = 0.0
    var lymax: Float = 0.0

    required init() {
        updateGeometry(Point3(-1, -1, -1), Point3(1, 1, 1))

        //  cube colors
        left = Color(0.80, 0.25, 0.25)
        right = Color(0.25, 0.25, 0.80)

        let gray: Color = Color(0.7, 0.7, 0.7)

        top = gray
        bottom = gray
        back = gray

        //  light source
        radiance = Color.WHITE

        samples = 16
    }

    func updateGeometry(_ c0: Point3, _ c1: Point3) {
        //  figure out cube extents
        lightBounds = BoundingBox(c0)

        lightBounds!.include(c1)

        //  cube extents
        minX = lightBounds!.getMinimum().x
        minY = lightBounds!.getMinimum().y
        minZ = lightBounds!.getMinimum().z
        maxX = lightBounds!.getMaximum().x
        maxY = lightBounds!.getMaximum().y
        maxZ = lightBounds!.getMaximum().z

        //  work around epsilon problems for light test
        lightBounds!.enlargeUlps()

        //  light source geometry
        lxmin = maxX / 3 + 2 * minX / 3
        lxmax = minX / 3 + 2 * maxX / 3
        lymin = maxY / 3 + 2 * minY / 3
        lymax = minY / 3 + 2 * maxY / 3

        area = (lxmax - lxmin) * (lymax - lymin)
    }

    func update(_ pl: ParameterList) -> Bool {
        let corner0: Point3? = pl.getPoint(CornellBoxLightParameter.PARAM_MIN_CORNER, nil)
        let corner1: Point3? = pl.getPoint(CornellBoxLightParameter.PARAM_MAX_CORNER, nil)

        if corner0 != nil, corner1 != nil {
            updateGeometry(corner0!, corner1!)
        }

        //  shader colors
        left = pl.getColor(CornellBoxLightParameter.PARAM_LEFT_COLOR, left!)
        right = pl.getColor(CornellBoxLightParameter.PARAM_RIGHT_COLOR, right!)
        top = pl.getColor(CornellBoxLightParameter.PARAM_TOP_COLOR, top!)
        bottom = pl.getColor(CornellBoxLightParameter.PARAM_BOTTOM_COLOR, bottom!)
        back = pl.getColor(CornellBoxLightParameter.PARAM_BACK_COLOR, back!)

        //  light
        radiance = pl.getColor(LightParameter.PARAM_RADIANCE, radiance!)
        samples = pl.getInt(LightParameter.PARAM_SAMPLES, samples)!

        return true
    }

    func getBounds() -> BoundingBox {
        return lightBounds!
    }

    func getBound(_ i: Int32) -> Float {
        switch i {
        case 0:
            return minX
        case 1:
            return maxX
        case 2:
            return minY
        case 3:
            return maxY
        case 4:
            return minZ
        case 5:
            return maxZ
        default:
            return 0
        }
    }

    func intersects(_ box: BoundingBox) -> Bool {
        //  this could be optimized
        let b: BoundingBox = BoundingBox()

        b.include(Point3(minX, minY, minZ))
        b.include(Point3(maxX, maxY, maxZ))

        if b.intersects(box) {
            //  the box is overlapping or enclosed
            if !b.contains(Point3(box.getMinimum().x, box.getMinimum().y, box.getMinimum().z)) {
                return true
            }

            if !b.contains(Point3(box.getMinimum().x, box.getMinimum().y, box.getMaximum().z)) {
                return true
            }

            if !b.contains(Point3(box.getMinimum().x, box.getMaximum().y, box.getMinimum().z)) {
                return true
            }

            if !b.contains(Point3(box.getMinimum().x, box.getMaximum().y, box.getMaximum().z)) {
                return true
            }

            if !b.contains(Point3(box.getMaximum().x, box.getMinimum().y, box.getMinimum().z)) {
                return true
            }

            if !b.contains(Point3(box.getMaximum().x, box.getMinimum().y, box.getMaximum().z)) {
                return true
            }

            if !b.contains(Point3(box.getMaximum().x, box.getMaximum().y, box.getMinimum().z)) {
                return true
            }

            if !b.contains(Point3(box.getMaximum().x, box.getMaximum().y, box.getMaximum().z)) {
                return true
            }
            //  all vertices of the box are inside - the surface! of the box is
            //  not intersected
        }

        return false
    }

    func prepareShadingState(_ state: ShadingState) {
        state.initState()

        state.getRay()!.getPoint(state.getPoint())

        let n: Int32 = state.getPrimitiveID()

        switch n {
        case 0:
            state.getNormal()!.set(Vector3(1, 0, 0))
        case 1:
            state.getNormal()!.set(Vector3(-1, 0, 0))
        case 2:
            state.getNormal()!.set(Vector3(0, 1, 0))
        case 3:
            state.getNormal()!.set(Vector3(0, -1, 0))
        case 4:
            state.getNormal()!.set(Vector3(0, 0, 1))
        case 5:
            state.getNormal()!.set(Vector3(0, 0, -1))
        default:
            state.getNormal()!.set(Vector3(0, 0, 0))
        }

        state.getGeoNormal()!.set(state.getNormal()!)

        state.setBasis(OrthoNormalBasis.makeFromW(state.getNormal()!))

        state.setShader(self)
    }

    func intersectPrimitive(_ r: Ray, _: Int32, _ state: IntersectionState) {
        var intervalMin: Float = -Float.infinity
        var intervalMax: Float = Float.infinity
        let orgX: Float = r.ox
        let invDirX: Float = 1 / r.dx
        var t1: Float
        var t2: Float

        t1 = (minX - orgX) * invDirX
        t2 = (maxX - orgX) * invDirX

        var sideIn: Int32 = -1
        var sideOut: Int32 = -1

        if invDirX > 0 {
            if t1 > intervalMin {
                intervalMin = t1
                sideIn = 0
            }

            if t2 < intervalMax {
                intervalMax = t2
                sideOut = 1
            }
        } else {
            if t2 > intervalMin {
                intervalMin = t2
                sideIn = 1
            }

            if t1 < intervalMax {
                intervalMax = t1
                sideOut = 0
            }
        }

        if intervalMin > intervalMax {
            return
        }

        let orgY: Float = r.oy
        let invDirY: Float = 1 / r.dy

        t1 = (minY - orgY) * invDirY
        t2 = (maxY - orgY) * invDirY

        if invDirY > 0 {
            if t1 > intervalMin {
                intervalMin = t1
                sideIn = 2
            }

            if t2 < intervalMax {
                intervalMax = t2
                sideOut = 3
            }
        } else {
            if t2 > intervalMin {
                intervalMin = t2
                sideIn = 3
            }

            if t1 < intervalMax {
                intervalMax = t1
                sideOut = 2
            }
        }

        if intervalMin > intervalMax {
            return
        }

        let orgZ: Float = r.oz
        let invDirZ: Float = 1 / r.dz

        t1 = (minZ - orgZ) * invDirZ //  no front wall
        t2 = (maxZ - orgZ) * invDirZ

        if invDirZ > 0 {
            if t1 > intervalMin {
                intervalMin = t1
                sideIn = 4
            }

            if t2 < intervalMax {
                intervalMax = t2
                sideOut = 5
            }
        } else {
            if t2 > intervalMin {
                intervalMin = t2
                sideIn = 5
            }

            if t1 < intervalMax {
                intervalMax = t1
                sideOut = 4
            }
        }

        if intervalMin > intervalMax {
            return
        }

        assert(sideIn != -1)
        assert(sideOut != -1)

        //  can't hit minY wall, there is none
        if sideIn != 2, r.isInside(intervalMin) {
            r.setMax(intervalMin)

            state.setIntersection(sideIn)
        } else if sideOut != 2, r.isInside(intervalMax) {
            r.setMax(intervalMax)

            state.setIntersection(sideOut)
        }
    }

    func getRadiance(_ state: ShadingState) -> Color {
        let side: Int32 = state.getPrimitiveID()
        var kd: Color?

        switch side {
        case 0:
            kd = left
        case 1:
            kd = right
        case 3:
            kd = back
        case 4:
            kd = bottom
        case 5:
            let lx: Float = state.getPoint().x
            let ly: Float = state.getPoint().y

            if lx >= lxmin, lx < lxmax, ly >= lymin, ly < lymax, state.getRay()!.dz > 0 {
                return (state.includeLights ? radiance : Color.BLACK)!
            }

            kd = top
        default:
            assert(false)
        }

        //  make sure we are on the right side of the material
        state.faceforward()

        //  setup lighting
        state.initLightSamples()

        state.initCausticSamples()

        return state.diffuse(kd!)
    }

    func scatterPhoton(_ state: ShadingState, _ power: Color) {
        let side: Int32 = state.getPrimitiveID()
        var kd: Color?

        switch side {
        case 0:
            kd = left
        case 1:
            kd = right
        case 3:
            kd = back
        case 4:
            kd = bottom
        case 5:
            let lx: Float = state.getPoint().x
            let ly: Float = state.getPoint().y

            if lx >= lxmin, lx < lxmax, ly >= lymin, ly < lymax, state.getRay()!.dz > 0 {
                return
            }

            kd = top
        default:
            assert(false)
        }

        //  make sure we are on the right side of the material
        if Vector3.dot(state.getNormal()!, state.getRay()!.getDirection()) > 0 {
            state.getNormal()!.negate()

            state.getGeoNormal()!.negate()
        }

        state.storePhoton(state.getRay()!.getDirection(), power, kd!)

        let avg: Double = Double(kd!.getAverage())
        let rnd: Double = state.getRandom(0, 0, 1)

        if rnd < avg {
            //  photon is scattered
            power.mul(kd!).mul(1 / Float(avg))

            let onb: OrthoNormalBasis = OrthoNormalBasis.makeFromW(state.getNormal()!)
            let u: Double = 2 * Double.pi * rnd / avg
            let v: Double = state.getRandom(0, 1, 1)
            let s: Float = Float(sqrt(v))
            let s1: Float = Float(sqrt(1.0 - v))
            var w: Vector3 = Vector3(Float(cos(u)) * s, Float(sin(u)) * s, s1)

            w = onb.transform(w, Vector3())

            state.traceDiffusePhoton(Ray(state.getPoint(), w), power)
        }
    }

    func getNumSamples() -> Int32 {
        return samples
    }

    func getSamples(_ state: ShadingState) {
        if lightBounds!.contains(state.getPoint()), state.getPoint().z < maxZ {
            let n: Int32 = (state.getDiffuseDepth() > 0 ? 1 : samples)
            let a: Float = area / Float(n)

            for i in 0 ..< n {
                //  random offset on unit square
                let randX: Double = state.getRandom(i, 0, n)
                let randY: Double = state.getRandom(i, 1, n)
                let p: Point3 = Point3()

                let _pX: Float = (lxmax * Float(randX))
                let _pY: Float = (lymax * Float(randY))

                p.x = Float((lxmin * Float(1 - randX)) + _pX)
                p.y = Float((lymin * Float(1 - randY)) + _pY)
                p.z = maxZ - 0.001

                let dest: LightSample = LightSample()

                //  prepare shadow ray to sampled point
                dest.setShadowRay(Ray(state.getPoint(), p))

                //  check that the direction of the sample is the same as the
                //  normal
                let cosNx: Float = dest.dot(state.getNormal()!)

                if cosNx <= 0 {
                    return
                }

                //  light source facing point
                //  (need to check with light source's normal)
                let cosNy: Float = dest.getShadowRay().dz

                if cosNy > 0 {
                    //  compute geometric attenuation and probability scale
                    //  factor
                    let r: Float = dest.getShadowRay().getMax()
                    let g: Float = cosNy / (r * r)
                    let scale: Float = g * a

                    //  set sample radiance
                    dest.setRadiance(radiance!, radiance!)

                    dest.getDiffuseRadiance().mul(scale)

                    dest.getSpecularRadiance().mul(scale)

                    dest.traceShadow(state)

                    state.addSample(dest)
                }
            }
        }
    }

    func getPhoton(_ randX1: Double, _ randY1: Double, _ randX2: Double, _ randY2: Double, _ p: Point3, _ dir: Vector3, _ power: Color) {
        // FIXME: riportare a forma normale (questo tipo di errori dipende dai cast sbagliati)
        let _pX: Float = (lxmax * Float(randX2))
        let _pY: Float = (lymax * Float(randY2))

        p.x = Float((lxmin * Float(1 - randX2)) + _pX)
        p.y = Float((lymin * Float(1 - randY2)) + _pY)
        p.z = maxZ - 0.001

        let u: Double = 2 * Double.pi * randX1
        let s: Double = sqrt(randY1)

        dir.set(Float(cos(u) * s), Float(sin(u) * s), Float(-sqrt(1.0 - randY1)))

        power.set(Color.mul(Float.pi * area, radiance!))
    }

    func getPower() -> Float {
        return radiance!.copy().mul(Float.pi * area).getLuminance()
    }

    func getNumPrimitives() -> Int32 {
        return 1
    }

    func getPrimitiveBound(_: Int32, _ i: Int32) -> Float {
        switch i {
        case 0:
            return minX
        case 1:
            return maxX
        case 2:
            return minY
        case 3:
            return maxY
        case 4:
            return minZ
        case 5:
            return maxZ
        default:
            return 0
        }
    }

    func getWorldBounds(_ o2w: AffineTransform?) -> BoundingBox? {
        let bounds: BoundingBox = BoundingBox(minX, minY, minZ)

        bounds.include(maxX, maxY, maxZ)

        if o2w == nil {
            return bounds
        }

        return o2w!.transform(bounds)
    }

    func getBakingPrimitives() -> PrimitiveList? {
        return nil
    }

    func createInstance() -> Instance? {
        return Instance.createTemporary(self, nil, self)
    }
}
