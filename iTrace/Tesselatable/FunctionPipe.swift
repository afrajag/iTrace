//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//
/*
final class FunctionPipe: QuadMesh, Tesselatable {
    var smooth: Bool = false
    var pipeSegments: Int32 = 10000
    var knotsPerPipeSegment: Int32 = 12
    var pipeRadius: Float = 0.0500000007450581
    var startPosition: Vector3 = Vector3(1.0, 0.0, 0.0)
    var outlinePoints: [Point3] = [Point3]()
    var pipeFunction: IFunctionPipeFunction
    var bb: BoundingBox = BoundingBox()
    static let M11: Double = 0.0
    static let M12: Double = 1.0
    static let M21: Double = -0.5
    static let M23: Double = 0.5
    static let M31: Double = 1.0
    static let M32: Double = -2.5
    static let M33: Double = 2.0
    static let M34: Double = -0.5
    static let M41: Double = -0.5
    static let M42: Double = 1.5
    static let M43: Double = -1.5
    static let M44: Double = 0.5

    init() {
        print(System.Reflection.MethodBase.GetCurrentMethod())
        pipeFunction = NullAttractor()
    }

    func GenerateMesh() {
        var curvePoints: [Vector3] = [Vector3]()
        var attractorPoints: [Vector3] = [Vector3]()
        pipeFunction.InitParameters()
        attractorPoints.Capacity = pipeSegments + 2
        curvePoints.Capacity = (pipeSegments + 2) * 5
        var circleSegments: Int32 = outlinePoints.Count
        var tDelta: Float = 1.0 / (knotsPerPipeSegment - 1)
        attractorPoints.Add(startPosition)
        var temp: Vector3 = Vector3()
        temp.set(startPosition)
        //     		print(temp);
        for i in 0 ... pipeSegments - 1 {
            pipeFunction.GetNextPosition(temp)
            var nextPoint: Vector3 = Vector3()
            nextPoint.set(temp)
            attractorPoints.Add(nextPoint)
        }
        //  special case the first point
        var lastItem: Int32 = attractorPoints.Count - 1
        if attractorPoints[0] == attractorPoints[lastItem] {
            //  it loops
            attractorPoints.RemoveAt(lastItem)
            var tmp: Vector3 = attractorPoints[attractorPoints.Count - 1]
            attractorPoints.Add(attractorPoints[0])
            attractorPoints.Insert(0, tmp)
        } else {
            //  it does not loop
            var diff: Vector3 = Vector3()
            diff = Vector3.sub(attractorPoints[0], attractorPoints[1], diff)
            diff = Vector3.add(attractorPoints[0], diff, diff)
            var diff2: Vector3 = Vector3()
            diff2 = Vector3.sub(attractorPoints[lastItem], attractorPoints[lastItem - 1], diff2)
            diff2 = Vector3.add(attractorPoints[lastItem], diff2, diff2)
            attractorPoints.Add(diff2)
            attractorPoints.Insert(0, diff)
        }
        //   	    	print("attractorPoints: \(xxx)" , attractorPoints.Count);
        var knotIndex: Int32 = 0
        var splinePoint: Vector3 = Vector3()
        var tangent: Vector3 = Vector3()
        var normal: Vector3 = Vector3()
        var up: Vector3 = Vector3(0.0, 1.0, 0.0)
        var zero: Point3 = Point3(0.0, 0.0, 0.0)
        var tangentAsPoint: Point3 = Point3()
        var rotatedPoint: Point3 = Point3()
        var oldSplinePoint: Vector3 = Vector3()
        var rotateToTangent: AffineTransform
        var pipeIndex: Int32 = 0
        var quadIndex: Int32 = 0
        var circleIndex: Int32 = 0
        var normalIndex: Int32 = 0
        var t: Float = 0.0
        for tempv in attractorPoints {
            tempv.mul(4.0)
            //  	    		print("attractorPoint: \(xxx)" , tempv);
        }
        oldSplinePoint.set(attractorPoints[0])
        for i in 0 ... pipeSegments - 1 {
            while t <= 1.0 {
                // 				print("t : \(xxx)", t);
                // 				print("knotIndex : \(xxx) - \(xxx)", knotIndex, knotIndex+3);
                // 				print(attractorPoints[knotIndex+1]);
                // 				print(attractorPoints[knotIndex+2]);
                splinePoint.x = CatmullRomSpline(t, attractorPoints[knotIndex].x, attractorPoints[knotIndex + 1].x, attractorPoints[knotIndex + 2].x, attractorPoints[knotIndex + 3].x)
                splinePoint.y = CatmullRomSpline(t, attractorPoints[knotIndex].y, attractorPoints[knotIndex + 1].y, attractorPoints[knotIndex + 2].y, attractorPoints[knotIndex + 3].y)
                splinePoint.z = CatmullRomSpline(t, attractorPoints[knotIndex].z, attractorPoints[knotIndex + 1].z, attractorPoints[knotIndex + 2].z, attractorPoints[knotIndex + 3].z)
                t = t + tDelta
                tangent = Vector3.sub(splinePoint, oldSplinePoint, tangent).normalize()
                tangentAsPoint.set(tangent.x, tangent.y, tangent.z)
                // 					normal =  Vector3.cross(tangent,up,normal).normalize();
                oldSplinePoint.set(splinePoint)
                // 					AffineTransform rotateAlongTangent = AffineTransform.rotate(tangent.x, tangent.y, tangent.z, (float)thetaDelta);
                rotateToTangent = AffineTransform.lookAt(zero, tangentAsPoint, up)
                // .inverse();
                if circleIndex == 0 {
                    for circleSegement in 0 ... circleSegments - 1 {
                        // 							pointOnOutline.set (pipeRadius * (float)cos(theta) ,pipeRadius * (float)sin(theta), 0f);
                        rotatedPoint = rotateToTangent.transformP(outlinePoints[circleSegement])
                        bb.include(rotatedPoint.x + splinePoint.x, rotatedPoint.y + splinePoint.y, rotatedPoint.z + splinePoint.z)
                        points[pipeIndex] = rotatedPoint.x + splinePoint.x
                        inc(pipeIndex)
                        points[pipeIndex] = rotatedPoint.y + splinePoint.y
                        inc(pipeIndex)
                        points[pipeIndex] = rotatedPoint.z + splinePoint.z
                        inc(pipeIndex)
                        if smooth {
                            normal.x = rotatedPoint.x
                            normal.y = rotatedPoint.y
                            normal.z = rotatedPoint.z
                            normal.normalize()
                            normals.data[normalIndex] = normal.x
                            inc(normalIndex)
                            normals.data[normalIndex] = normal.y
                            inc(normalIndex)
                            normals.data[normalIndex] = normal.z
                            inc(normalIndex)
                        }
                    }
                } else {
                    //  go round it a circle.
                    var circleSegement: Int32
                    while circleSegement < circleSegments {
                        circleSegement = 0
                        {
                            rotatedPoint = rotateToTangent.transformP(outlinePoints[circleSegement])
                            bb.include(rotatedPoint.x + splinePoint.x, rotatedPoint.y + splinePoint.y, rotatedPoint.z + splinePoint.z)
                            points[pipeIndex] = rotatedPoint.x + splinePoint.x
                            inc(pipeIndex)
                            points[pipeIndex] = rotatedPoint.y + splinePoint.y
                            inc(pipeIndex)
                            points[pipeIndex] = rotatedPoint.z + splinePoint.z
                            inc(pipeIndex)
                            if smooth {
                                normal.x = rotatedPoint.x
                                normal.y = rotatedPoint.y
                                normal.z = rotatedPoint.z
                                normal.normalize()
                                normals.data[normalIndex] = normal.x
                                inc(normalIndex)
                                normals.data[normalIndex] = normal.y
                                inc(normalIndex)
                                normals.data[normalIndex] = normal.z
                                inc(normalIndex)
                            }
                            if (circleSegement + 1) < circleSegments {
                                quads[quadIndex] = circleSegement + ((circleIndex - 1) * circleSegments)
                                inc(quadIndex)
                                quads[quadIndex] = circleSegement + ((circleIndex - 1) * circleSegments) + 1
                                inc(quadIndex)
                                quads[quadIndex] = circleSegement + (circleIndex * circleSegments) + 1
                                inc(quadIndex)
                                quads[quadIndex] = circleSegement + (circleIndex * circleSegments)
                                inc(quadIndex)
                            }
                        }
                        rotatedPoint = rotateToTangent.transformP(outlinePoints[circleSegement])
                        bb.include(rotatedPoint.x + splinePoint.x, rotatedPoint.y + splinePoint.y, rotatedPoint.z + splinePoint.z)
                        points[pipeIndex] = rotatedPoint.x + splinePoint.x
                        inc(pipeIndex)
                        points[pipeIndex] = rotatedPoint.y + splinePoint.y
                        inc(pipeIndex)
                        points[pipeIndex] = rotatedPoint.z + splinePoint.z
                        inc(pipeIndex)
                        if smooth {
                            normal.x = rotatedPoint.x
                            normal.y = rotatedPoint.y
                            normal.z = rotatedPoint.z
                            normal.normalize()
                            normals.data[normalIndex] = normal.x
                            inc(normalIndex)
                            normals.data[normalIndex] = normal.y
                            inc(normalIndex)
                            normals.data[normalIndex] = normal.z
                            inc(normalIndex)
                        }
                        if (circleSegement + 1) < circleSegments {
                            quads[quadIndex] = circleSegement + ((circleIndex - 1) * circleSegments)
                            inc(quadIndex)
                            quads[quadIndex] = circleSegement + ((circleIndex - 1) * circleSegments) + 1
                            inc(quadIndex)
                            quads[quadIndex] = circleSegement + (circleIndex * circleSegments) + 1
                            inc(quadIndex)
                            quads[quadIndex] = circleSegement + (circleIndex * circleSegments)
                            inc(quadIndex)
                        }
                        inc(circleSegement)
                    } quads[quadIndex] = (circleSegement - 1) + ((circleIndex - 1) * circleSegments)
                    inc(quadIndex)
                    quads[quadIndex] = (circleIndex - 1) * circleSegments
                    inc(quadIndex)
                    quads[quadIndex] = circleIndex * circleSegments
                    inc(quadIndex)
                    quads[quadIndex] = (circleSegement - 1) + (circleIndex * circleSegments)
                    inc(quadIndex)
                }
                inc(circleIndex)
            } t = tDelta
            inc(knotIndex)
        }
    }

    func tesselate() -> PrimitiveList {
        return self
    }

    func CatmullRomSpline(_ x: Float, _ v0: Float, _ v1: Float, _ v2: Float, _ v3: Float) -> Float {
        var c1: Double
        var c2: Double
        var c3: Double
        var c4: Double
        c1 = M12 * v1
        c2 = (M21 * v0) + (M23 * v2)
        c3 = (M31 * v0) + (M32 * v1) + (M33 * v2) + (M34 * v3)
        c4 = (M41 * v0) + (M42 * v1) + (M43 * v2) + (M44 * v3)
        return ((((((c4 * x) + c3) * x) + c2) * x) + c1 as Float)
    }

    func CatmullRomSplineTangent(_ t: Float, _ v0: Float, _ v1: Float, _ v2: Float, _ v3: Float) -> Float {
        var tangent: Double = 0.5 * ((2.0 * v1) + -v0 + v2 + (2.0 * ((((2.0 * v0) - (5.0 * v1)) + (4.0 * v2)) - v3) * t) + (3.0 * (((-v0 + (3.0 * v1)) - (3.0 * v2)) + v3) * t * t))
        return (tangent as Float)
    }

    func update(_ pl: ParameterList) -> Bool {
        if outlinePoints.isEmpty {
            var circlePoints: Int32 = 16
            var theta: Double = 0
            var thetaDelta: Double = (Double.Pi * 2.0) / circlePoints
            for i in 0 ... circlePoints - 1 {
                outlinePoints.Add(Point3(pipeRadius * cos(theta) as Float, pipeRadius * sin(theta) as Float, 0.0))
                theta = theta + thetaDelta
            }
        }
        var circleSegments: Int32 = outlinePoints.Count
        if points == nil {
            points = Float[](repeating: 0, count: ((circleSegments * pipeSegments * knotsPerPipeSegment) + circleSegments) * 3)
            quads = Int32[](repeating: 0, count: circleSegments * pipeSegments * (knotsPerPipeSegment - 1) * 4)
            if smooth {
                normals = ParameterList.FloatParameter(ParameterList.InterpolationType.VERTEX, Float[](repeating: 0, count: points.count))
            }
            //   	    	print("mp: \(xxx)", (circleSegments * (pipeSegments  * (knotsPerPipeSegment-1)) + circleSegments) * 3);
            //   	    	print("mq: \(xxx)", circleSegments * pipeSegments * (knotsPerPipeSegment-1) * 4 );
        }
        GenerateMesh()
        return true
    }

    func getWorldBounds(_ o2w: AffineTransform) -> BoundingBox {
        if o2w == nil {
            return bb
        }
        return o2w.transform(bb)
    }

    internal protocol IFunctionPipeFunction {
        func InitParameters()

        func GetNextPosition(_ p: Vector3)

        func GetStartPosition(_ p: Vector3)
    }

    final class NullAttractor: IFunctionPipeFunction {
        // initialize attractor parameters
        func GetStartPosition(_: Vector3) {}

        func InitParameters() {}

        // calculate next attractor position
        func GetNextPosition(_: Vector3) {}
    }
}
*/
