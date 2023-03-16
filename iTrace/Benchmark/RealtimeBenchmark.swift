//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

/*
 final class RealtimeBenchmark : API {
 init(_ showGUI: Bool, _ threads: Int32) {
 	var display: Display = FileDisplay(false)
 	UI.printInfo(.BENCH, "Preparing benchmarking scene ...")
 	//  settings
 	parameter("threads", threads)
 	//  spawn regular priority threads
 	parameter("threads.lowPriority", false)
 	parameter("resolutionX", 512)
 	parameter("resolutionY", 512)
 	parameter("aa.min", -3)
 	parameter("aa.max", 0)
 	parameter("depths.diffuse", 1)
 	parameter("depths.reflection", 1)
 	parameter("depths.refraction", 0)
 	parameter("bucket.order", "hilbert")
 	parameter("bucket.size", 32)
 	options(API.DEFAULT_OPTIONS)
 	//  camera
 	var eye: Point3 = Point3(30, 0, 10.9670000076294)
 	var target: Point3 = Point3(0, 0, 5.40000009536743)
 	var up: Vector3 = Vector3(0, 0, 1)
 	parameter("transform", AffineTransform.lookAt(eye, target, up))
 	parameter("fov", 45.0)
 	camera("camera", "pinhole")
 	parameter("camera", "camera")
 	options(API.DEFAULT_OPTIONS)
 	//  geometry
 	createGeometry()
 	//  this first render is not timed, it caches the acceleration data
 	//  structures and tesselations so they won't be
 	//  included in the main timing
 	UI.printInfo(.BENCH, "Rendering warmup frame ...")
 	render(API.DEFAULT_OPTIONS, display)
 	//  now disable all output - and run the benchmark
 	UI.set(SilentInterface())
 	var t: TraceTimer = TraceTimer()
 	t.start()
 	var phi: Float = 0
 	var frames: Int32 = 0
 	while phi < (4 * Double.Pi) {
 		eye.x = 30 * (cos(phi) as Float)
 		eye.y = 30 * (sin(phi) as Float)
 		phi = phi + (Double.Pi / 30 as Float)
 		inc(frames)
 		//  update camera
 		parameter("transform", AffineTransform.lookAt(eye, target, up))
 		camera("camera", nil)
 		render(API.DEFAULT_OPTIONS, display)
 	}
 t.end()
 	UI.set(ConsoleInterface())
 	UI.printInfo(.BENCH, "Benchmark results:")
 	UI.printInfo(.BENCH, "  * Average FPS:         {0,6:0.00", frames / t.seconds())
 	UI.printInfo(.BENCH, "  * Total time:          \(xxx)", t)
 }

 func createGeometry() {
 	//  light source
 	parameter("source", Point3(-15.5944995880127, -30.0580997467041, 45.9669990539551))
 	parameter("dir", Vector3(15.5944995880127, 30.0580997467041, -45.9669990539551))
 	parameter("radius", 60.0)
 	parameter("radiance", nil, 3, 3, 3)
 	light("light", "directional")
 	//  gi-engine
 	parameter("gi.engine", "fake")
 	parameter("gi.fake.sky", nil, 0.25, 0.25, 0.25)
 	parameter("gi.fake.ground", nil, 0.00999999977648258, 0.00999999977648258, 0.5)
 	parameter("gi.fake.up", Vector3(0, 0, 1))
 	options(DEFAULT_OPTIONS)
 	//  shaders
 	parameter("diffuse", nil, 0.5, 0.5, 0.5)
 	shader("default", "diffuse")
 	parameter("diffuse", nil, 0.5, 0.5, 0.5)
 	parameter("shiny", 0.200000002980232)
 	shader("refl", "shiny_diffuse")
 	//  objects
 	//  teapot
 	parameter("subdivs", 10)
 	geometry("teapot", "teapot")
 	parameter("shaders", "default")
 	var m: AffineTransform = AffineTransform.IDENTITY
 	m = AffineTransform.scale(0.0750000029802322).multiply(m)
 	m = AffineTransform.rotateZ((MathUtils.toRadians(-45.0) as Float)).multiply(m)
 	m = AffineTransform.translation(-7, 0, 0).multiply(m)
 	parameter("transform", m)
 	instance("teapot.instance", "teapot")
 	//  gumbo
 	parameter("subdivs", 10)
 	geometry("gumbo", "gumbo")
 	m = AffineTransform.IDENTITY
 	m = AffineTransform.scale(0.5).multiply(m)
 	m = AffineTransform.rotateZ((MathUtils.toRadians(25.0) as Float)).multiply(m)
 	m = AffineTransform.translation(3, -7, 0).multiply(m)
 	parameter("shaders", "default")
 	parameter("transform", m)
 	instance("gumbo.instance", "gumbo")
 	//  ground plane
 	parameter("center", Point3(0, 0, 0))
 	parameter("normal", Vector3(0, 0, 1))
 	geometry("ground", "plane")
 	parameter("shaders", "refl")
 	instance("ground.instance", "ground")
 }
 }
 */
