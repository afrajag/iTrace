//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

/*
 final class Benchmark : BenchmarkTest, UserInterface, Display {
 var resolution: Int32 = 0
 var showOutput: Bool = false
 var showBenchmarkOutput: Bool = false
 var saveOutput: Bool = false
 var threads: Int32 = 0
 var referenceImage: [Int32]
 var validationImage: [Int32]
 var errorThreshold: Int32 = 0

 static func main(_ args: [String]) {
 	if args.isEmpty {
 		print("Benchmark options:")
 		print("  -regen                        Regenerate reference images for a variety of sizes")
 		print("  -bench [threads] [resolution] Run a single iteration of the benchmark using the specified thread count and image resolution")
 		print("                                Default: threads=0 (auto-detect cpus), resolution=256")
 	} else {
 		if args[0] == "-regen" {
 var sizes: [Int32] = [32, 64, 96, 128, 256, 384, 512]
 			for s in sizes {
 				//  run a single iteration to generate the reference image
 				var b: Benchmark = Benchmark(s, true, false, true)
 				b.kernelMain()
 			}
 		} else {
 			if args[0] == "-bench" {
 				var threads: Int32 = 0
 				var resolution: Int32 = 256
 				if args.count > 1 {
 					threads = Int32.Parse(args[1])
 				}
 				if args.count > 2 {
 					resolution = Int32.Parse(args[2])
 				}
 				var benchmark: Benchmark = Benchmark(resolution, false, true, false, threads)
 				benchmark.kernelBegin()
 				benchmark.kernelMain()
 				benchmark.kernelEnd()
 			}
 		}
 	}
 }

 convenience required init() {
 	self.init(384, false, true, false)
 }

 convenience init(_ resolution: Int32, _ showOutput: Bool, _ showBenchmarkOutput: Bool, _ saveOutput: Bool) {
 	self.init(resolution, showOutput, showBenchmarkOutput, saveOutput, 0)
 }

 init(_ resolution: Int32, _ showOutput: Bool, _ showBenchmarkOutput: Bool, _ saveOutput: Bool, _ threads: Int32) {
 	UI.set(self)
 	self.resolution = resolution
 	self.showOutput = showOutput
 	self.showBenchmarkOutput = showBenchmarkOutput
 	self.saveOutput = saveOutput
 	self.threads = threads
 	errorThreshold = 6
 	//  fetch reference image from resources (jar file or classpath)
 	if saveOutput {
 		return
 	}
 	var imageURL: URL = getResource(String.Format("/resources/golden_\(xxx).png", resolution))
 	// fixme: add padding zeros
 	if imageURL == nil {
 		UI.printError(.BENCH, "Unable to find reference frame")
 	}
 	UI.printInfo(.BENCH, "Loading reference image from: \(xxx)", imageURL)

 		var bi: BufferedImage = ImageIO.read(imageURL)
 		if (bi.getWidth() != resolution) | (bi.getHeight() != resolution) {
 			UI.printError(.BENCH, "Reference image has invalid resolution Expected \(xxx)x\(xxx) found \(xxx)x\(xxx)", resolution, resolution, bi.getWidth(), bi.getHeight())
 		}
 		referenceImage = Int32[](repeating: 0, count: resolution * resolution)
 		for y in 0 ... resolution - 1 {
 			for x in 0 ... resolution - 1 {
 				referenceImage[i] = bi.getRGB(x, resolution - 1 - y)
 			}
 		}
 		//  flip
 		//UI.printError(.BENCH, "Unable to load reference frame")

 }

 func execute() {
 	//  10 iterations maximum - 10 minute time limit
 	var framework: BenchmarkFramework = BenchmarkFramework(10, 600)
 	framework.execute(self)
 }

 func kernelBegin() {
 	//  allocate a fresh validation target
 	validationImage = Int32[](repeating: 0, count: resolution * resolution)
 }

 func kernelMain() {
 	//  this builds and renders the scene
 	BenchmarkScene(self)
 }

 func kernelEnd() {
 	//  make sure the rendered image was correct
 	var diff: Int32 = 0
 	if referenceImage != nil & (validationImage.count == referenceImage.count) {
 		for i in 0 ... validationImage.count - 1 {
 			//  count absolute RGB differences
 			diff = diff + abs((validationImage[i] && 255) - (referenceImage[i] && 255))
 			diff = diff + abs(((validationImage[i] >> 8) && 255) - ((referenceImage[i] >> 8) && 255))
 			diff = diff + abs(((validationImage[i] >> 16) && 255) - ((referenceImage[i] >> 16) && 255))
 		}
 		if diff > errorThreshold {
 			UI.printError(.BENCH, "Image check failed - #errors: \(xxx)", diff)
 		} else {
 			UI.printInfo(.BENCH, "Image check passed")
 		}
 	} else {
 		UI.printError(.BENCH, "Image check failed - reference is not comparable")
 	}
 }

 func print(_ m: UI.Module, _ level: UI.PrintLevel, _ s: String) {
 	if showOutput | (showBenchmarkOutput & (m == Module.BENCH)) {
 		print(UI.formatOutput(m, level, s))
 	}
 	if level == PrintLevel.ERROR {
 		throw RuntimeException(s)
 	}
 }

 func taskStart(_ s: String, _ min: Int32, _ max: Int32) {
 	//  render progress display not needed
 	//
 }

 func taskStop() {
 	//  render progress display not needed
 	//
 }

 func taskUpdate(_ current: Int32) {
 	//  render progress display not needed
 	//
 }

 func imageBegin(_ w: Int32, _ h: Int32, _ bucketSize: Int32) {
 	//  we can assume w == h == resolution
 	//
 }

 func imageEnd() {
 	//  nothing needs to be done - image verification is done externally
 	//
 }

 func imageFill(_ x: Int32, _ y: Int32, _ w: Int32, _ h: Int32, _ c: Color, _ alpha: Float) {
 	//  this is not used
 	//
 }

 func imagePrepare(_ x: Int32, _ y: Int32, _ w: Int32, _ h: Int32, _ id: Int32) {
 	//  this is not needed
 	//
 }

 func imageUpdate(_ x: Int32, _ y: Int32, _ w: Int32, _ h: Int32, _ data: [Color], _ alpha: [Float]) {
 	//  copy bucket data to validation image
 	for j in 0 ... h - 1 {
 		for i in 0 ... w - 1 {
 			validationImage[offset] = data[index].copy().toNonLinear().toRGB()
 		}
 	}
 }

 final class BenchmarkScene : API {
 var benchmark: Benchmark

 	init(_ benchmark: Benchmark) {
 		self.benchmark = benchmark
 		build()
 		render(API.DEFAULT_OPTIONS, (saveOutput ? FileDisplay(String.Format("resources/golden_\(xxx).png", resolution)) : benchmark))
 		// fixme: add padding zeros
 	}

 	func build() {
 		//  settings
 		parameter("threads", threads)
 		//  spawn regular priority threads
 		parameter("threads.lowPriority", false)
 		parameter("resolutionX", resolution)
 		parameter("resolutionY", resolution)
 		parameter("aa.min", -1)
 		parameter("aa.max", 1)
 		parameter("filter", "triangle")
 		parameter("depths.diffuse", 2)
 		parameter("depths.reflection", 2)
 		parameter("depths.refraction", 2)
 		parameter("bucket.order", "hilbert")
 		parameter("bucket.size", 32)
 		//  gi options
 		parameter("gi.engine", "igi")
 		parameter("gi.igi.samples", 90)
 		parameter("gi.igi.c", 7.99999997980194E-06)
 		options(API.DEFAULT_OPTIONS)
 		buildCornellBox()
 	}

 	func buildCornellBox() {
 		//  camera
 		parameter("transform", AffineTransform.lookAt(Point3(0, 0, -600), Point3(0, 0, 0), Vector3(0, 1, 0)))
 		parameter("fov", 45.0)
 		camera("main_camera", "pinhole")
 		parameter("camera", "main_camera")
 		options(API.DEFAULT_OPTIONS)
 		//  cornell box
 		var gray: Color = Color(0.699999988079071, 0.699999988079071, 0.699999988079071)
 		var blue: Color = Color(0.25, 0.25, 0.800000011920929)
 		var red: Color = Color(0.800000011920929, 0.25, 0.25)
 		var emit: Color = Color(15, 15, 15)
 		var minX: Float = -200
 		var maxX: Float = 200
 		var minY: Float = -160
 		var maxY: Float = minY + 400
 		var minZ: Float = -250
 		var maxZ: Float = 200
 var verts: [Float] = ([minX, minY, minZ, maxX, minY, minZ, maxX, minY, maxZ, minX, minY, maxZ, minX, maxY, minZ, maxX, maxY, minZ, maxX, maxY, maxZ, minX, maxY, maxZ] as [Float])
 var indices: [Int32] = ([0, 1, 2, 2, 3, 0, 4, 5, 6, 6, 7, 4, 1, 2, 5, 5, 6, 2, 2, 3, 6, 6, 7, 3, 0, 3, 4, 4, 7, 3] as [Int32])
 		parameter("diffuse", gray)
 		shader("gray_shader", "diffuse")
 		parameter("diffuse", red)
 		shader("red_shader", "diffuse")
 		parameter("diffuse", blue)
 		shader("blue_shader", "diffuse")
 		//  build walls
 		parameter("triangles", indices)
 		parameter("points", "point", "vertex", verts)
 parameter("faceshaders", ([0, 0, 0, 0, 1, 1, 0, 0, 2, 2] as [Int32]))
 		geometry("walls", "triangle_mesh")
 		//  instance walls
 parameter("shaders", (["gray_shader", "red_shader", "blue_shader"] as [String]))
 		instance("walls.instance", "walls")
 		//  create mesh light
 parameter("points", "point", "vertex", ([-50, maxY - 1, -50, 50, maxY - 1, -50, 50, maxY - 1, 50, -50, maxY - 1, 50] as [Float]))
 parameter("triangles", ([0, 1, 2, 2, 3, 0] as [Int32]))
 		parameter("radiance", emit)
 		parameter("samples", 8)
 		light("light", "triangle_mesh")
 		//  spheres
 		parameter("eta", 1.60000002384186)
 		shader("Glass", "glass")
 		sphere("glass_sphere", "Glass", -120, minY + 55, -150, 50)
 		parameter("color", Color(0.699999988079071, 0.699999988079071, 0.699999988079071))
 		shader("Mirror", "mirror")
 		sphere("mirror_sphere", "Mirror", 100, minY + 60, -50, 50)
 		//  scanned model
 		geometry("teapot", "teapot")
 		parameter("transform", AffineTransform.translation(80, -50, 100).multiply(AffineTransform.rotateX((-Double.Pi as Float) / 6)).multiply(AffineTransform.rotateY((Double.Pi as Float) / 4)).multiply(AffineTransform.rotateX((-Double.Pi as Float) / 2).multiply(AffineTransform.scale(1.20000004768372))))
 		parameter("shaders", "gray_shader")
 		instance("teapot.instance1", "teapot")
 		parameter("transform", AffineTransform.translation(-80, -160, 50).multiply(AffineTransform.rotateY((Double.Pi as Float) / 4)).multiply(AffineTransform.rotateX((-Double.Pi as Float) / 2).multiply(AffineTransform.scale(1.20000004768372))))
 		parameter("shaders", "gray_shader")
 		instance("teapot.instance2", "teapot")
 	}

 	func sphere(_ name: String, _ shaderName: String, _ x: Float, _ y: Float, _ z: Float, _ radius: Float) {
 		geometry(name, "sphere")
 		parameter("transform", AffineTransform.translation(x, y, z).multiply(AffineTransform.scale(radius)))
 		parameter("shaders", shaderName)
 		instance(name + ".instance", name)
 	}
 }
 }
 */
