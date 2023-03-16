//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

import Foundation
import PathKit

final class FileMesh: Tesselatable {
    var filename: String?
    var mesh: PrimitiveList?
    var smoothNormals: Bool = false
    var api: API?
    
    let lockQueue = DispatchQueue(label: "filemesh.lock.serial.queue")
    
    required init() {}
    
    func getWorldBounds(_ o2w: AffineTransform?) -> BoundingBox? {
        //  world bounds can't be computed without reading file
        //  return null so the mesh will be loaded right away
        return nil
    }
    
    func tesselate() -> PrimitiveList? {
        if filename != nil {
            lockQueue.sync { // synchronized block
                // Trying to tesselate the mesh
                mesh = loadMesh(filename)
            }
        }
        
        return mesh != nil ? mesh : nil
        
        /*
         if filename.EndsWith(".ra3") {
         	print("RA3 unsupported")
         	// try
         	// {
         	//     UI.printInfo(.GEOM, "RA3 - Reading geometry: \"%s\" ...", filename);
         	//     File file = new File(filename);
         	//     FileInputStream stream = new FileInputStream(filename);
         	//     MappedByteBuffer map = stream.getChannel().map(FileChannel.MapMode.READ_ONLY, 0, file.count());
         	//     map.order(ByteOrder.LITTLE_ENDIAN);
         	//     IntBuffer ints = map.asIntBuffer();
         	//     FloatBuffer buffer = map.asFloatBuffer();
         	//     int numVerts = ints.get(0);
         	//     int numTris = ints.get(1);
         	//     UI.printInfo(.GEOM, "RA3 -   * Reading \(xxx) vertices ...", numVerts);
         	//     float[] verts = new float[3 * numVerts];
         	//     for (int i = 0; i < verts.count; i++)
         	//         verts[i] = buffer.get(2 + i);
         	//     UI.printInfo(.GEOM, "RA3 -   * Reading \(xxx) triangles ...", numTris);
         	//     int[] tris = new int[3 * numTris];
         	//     for (int i = 0; i < tris.count; i++)
         	//         tris[i] = ints.get(2 + verts.count + i);
         	//     stream.close();
         	//     UI.printInfo(.GEOM, "RA3 -   * Creating mesh ...");
         	//     return generate(tris, verts, smoothNormals);
         	// }
         	// catch (FileNotFoundException e)
         	// {
         	//     e.printStackTrace();
         	//     UI.printError(.GEOM, "Unable to read mesh file \"\(xxx)\" - file not found", filename);
         	// }
         	// catch (IOException e)
         	// {
         	//     e.printStackTrace();
         	//     UI.printError(.GEOM, "Unable to read mesh file \"\(xxx)\" - I/O error occured", filename);
         	// }
         } else {
         	if filename.EndsWith(".obj") {
         		var lineNumber: Int32 = 1
         
         			UI.printInfo(.GEOM, "OBJ - Reading geometry: \"\(xxx)\" ...", filename)
         			var verts: Array<Float> = Array<Float>()
         			var tris: Array<Int32> = Array<Int32>()
         			// FileReader file = new FileReader(filename);
         			// BufferedReader bf = new BufferedReader(file);
         			var bf: StreamReader = StreamReader(filename)
         			var line: String
         			while line = bf.ReadLine() != nil {
         				if line.StartsWith("v") {
         var v: [String] = line.Split(StringConsts.Whitespace, StringSplitOptions.RemoveEmptyEntries)
         					// "\\s+");
         					verts.Add(Float.Parse(v[1], System.Globalization.CultureInfo.InvariantCulture))
         					verts.Add(Float.Parse(v[2], System.Globalization.CultureInfo.InvariantCulture))
         					verts.Add(Float.Parse(v[3], System.Globalization.CultureInfo.InvariantCulture))
         				} else {
         					if line.StartsWith("f") {
         var f: [String] = line.Split(StringConsts.Whitespace, StringSplitOptions.RemoveEmptyEntries)
         						// "\\s+");
         						if f.count == 5 {
         							tris.Add(Int32.Parse(f[1]) - 1)
         							tris.Add(Int32.Parse(f[2]) - 1)
         							tris.Add(Int32.Parse(f[3]) - 1)
         							tris.Add(Int32.Parse(f[1]) - 1)
         							tris.Add(Int32.Parse(f[3]) - 1)
         							tris.Add(Int32.Parse(f[4]) - 1)
         						} else {
         							if f.count == 4 {
         								tris.Add(Int32.Parse(f[1]) - 1)
         								tris.Add(Int32.Parse(f[2]) - 1)
         								tris.Add(Int32.Parse(f[3]) - 1)
         							}
         						}
         					}
         				}
         				if (lineNumber % 100000) == 0 {
         					UI.printInfo(.GEOM, "OBJ -   * Parsed \(xxx) lines ...", lineNumber)
         				}
         				inc(lineNumber)
         			}// file.close();
         			bf.Close()
         			UI.printInfo(.GEOM, "OBJ -   * Creating mesh ...")
         			return generate(tris.ToArray(), verts.ToArray(), smoothNormals)
         
         			//print(e)
         			//UI.printError(.GEOM, "Unable to read mesh file \"\(xxx)\" - file not found", filename)
         
         	} else {
         		if filename.EndsWith(".stl") {
         
         				UI.printInfo(.GEOM, "STL - Reading geometry: \"\(xxx)\" ...", filename)
         				// FileInputStream file = new FileInputStream(filename);
         				// DataInputStream stream = new DataInputStream(new BufferedInputStream(file));
         				var stream: BinaryReader = BinaryReader(File.OpenRead(filename))
         				// file.skip(80);
         				stream.BaseStream.Seek(80, SeekOrigin.Current)
         				var numTris: Int32 = getLittleEndianInt(stream.ReadInt32())
         				UI.printInfo(.GEOM, "STL -   * Reading \(xxx) triangles ...", numTris)
         				var filesize: Int64 = stream.BaseStream.count
         				if filesize != (84 + (50 * numTris)) {
         					UI.printWarning(.GEOM, "STL - Size of file mismatch (expecting \(xxx), found \(xxx))", Memory.bytesTostring(84 + (14 * numTris)), Memory.bytesTostring(filesize))
         					return nil
         				}
         var tris: [[Int32Int32] = Int32[](repeating: 0, count: 3 * numTris)
         var verts: [Float] = Float[](repeating: 0, count: 9 * numTris)
         				for i in 0 ... numTris - 1 {
         					//  skip normal
         					stream.ReadInt32()
         					stream.ReadInt32()
         					stream.ReadInt32()
         					for j in 0 ... 3 - 1 {
         						tris[i3 + j] = i3 + j
         						//  get xyz
         						verts[index + 0] = getLittleEndianFloat(stream.ReadInt32())
         						verts[index + 1] = getLittleEndianFloat(stream.ReadInt32())
         						verts[index + 2] = getLittleEndianFloat(stream.ReadInt32())
         					}
         					stream.ReadInt16()
         					if ((i + 1) % 100000) == 0 {
         						UI.printInfo(.GEOM, "STL -   * Parsed \(xxx) triangles ...", i + 1)
         					}
         				}
         				stream.Close()
         				// file.close();
         				//  create geometry
         				UI.printInfo(.GEOM, "STL -   * Creating mesh ...")
         				if smoothNormals {
         					UI.printWarning(.GEOM, "STL - format does not support shared vertices - normal smoothing disabled")
         				}
         				return generate(tris, verts, false)
         
         				//print(e)
         				//UI.printError(.GEOM, "Unable to read mesh file \"\(xxx)\" - file not found", filename)
         
         		} else {
         			UI.printWarning(.GEOM, "Unable to read mesh file \"\(xxx)\" - unrecognized format", filename)
         		}
         	}
         }
         */
    }
    
    func update(_ pl: ParameterList) -> Bool {
        let file: String? = pl.getString("filename", nil)
        
        if file != nil {
            filename = API.shared.resolveIncludeFilename(file!)
        }
        
        smoothNormals = pl.getBool("smooth_normals", smoothNormals)!

        return filename != nil
    }
    
    func loadMesh(_ filename: String?) -> PrimitiveList? {
        let file_extension: String = FileUtils.getExtension(filename)!
        var brutal = false
        
        var vertices: [Float] = [Float]()
        var tris: [Int32] = [Int32]()
        var normals: [Float] = [Float]()
        var uvs: [Float] = [Float]()
        var materialsIds: [Int32] = [Int32]() // faceshaders
        var modifiersIds: [Int32] = [Int32]() // like faceshaders array but for modifiers
        var shaders: [(ShaderParameter, ModifierParameter?)]?
        
        let t: TraceTimer = TraceTimer()
        
        t.start()
        
        if file_extension == "obj" {
            // Wavefront OBJ loading
            let base_path = FileUtils.getPath(filename) ?? ""
            
            do {
                UI.printInfo(.GEOM, "  * Loading Wavefront OBJ file: \"\(filename!)\" ...")
                
                let t: TraceTimer = TraceTimer()
                
                t.start()
                
                // load text file
                let source = try String(contentsOfFile: filename!, encoding: .utf8).replacingOccurrences(of: "\r", with: "").cString(using: .utf8)
                
                // init tinyloader params
                var attrib: tinyobj_attrib_t = tinyobj_attrib_t()
                var shapes: UnsafeMutablePointer<tinyobj_shape_t>?
                var num_shapes: Int = 0
                var materials: UnsafeMutablePointer<tinyobj_material_t>?
                var num_materials: Int = 0
                
                UI.printInfo(.GEOM, "  * Parsing geometry ...")
                
                // let tinyloader do its magic
                let parsing_result = tinyobj_parse_obj(&attrib, &shapes, &num_shapes, &materials, &num_materials, source, source!.count, (base_path + "/").cString(using: .utf8), UInt32(TINYOBJ_FLAG_TRIANGULATE))
                
                if parsing_result == TINYOBJ_SUCCESS { // mesh loaded successfully
                    UI.printInfo(.GEOM, "  * Loaded \(num_shapes) shapes [triangles: \(attrib.num_face_num_verts) - vertices: \(attrib.num_vertices)] and \(num_materials) materials")

                    // vertices
                    for vertexIdx in stride(from: 0, to: attrib.num_vertices * 3, by: 3) {
                        vertices.append(attrib.vertices[Int(vertexIdx + 0)])
                        vertices.append(attrib.vertices[Int(vertexIdx + 1)])
                        vertices.append(attrib.vertices[Int(vertexIdx + 2)])
                    }
                    
                    for triIdx in 0 ..< attrib.num_faces {
                        // faces
                        tris.append(Int32(attrib.faces[Int(triIdx)].v_idx))
                        
                        // normals
                        if attrib.num_normals > 0 {
                            let idx = 3 * Int(attrib.faces[Int(triIdx)].vn_idx)
                            
                            normals.append(attrib.normals[idx + 0])
                            normals.append(attrib.normals[idx + 1])
                            normals.append(attrib.normals[idx + 2])
                        }
                        
                        // texture coords
                        if attrib.num_texcoords > 0 {
                            if (attrib.faces[Int(triIdx)].vt_idx < 0) {
                                // there are faces with null tex coords - setting to 0 index
                                uvs.append(0)
                                uvs.append(0)
                            } else {
                                let idx = 2 * Int(attrib.faces[Int(triIdx)].vt_idx)

                                uvs.append(attrib.texcoords[idx + 0])
                                uvs.append(attrib.texcoords[idx + 1])
                            }
                        }
                    }

                    if (num_materials > 0) { // there are some materials
                        shaders = [(ShaderParameter, ModifierParameter?)]()
                        
                        // init modifiers
                        modifiersIds = [Int32](repeating: -1, count: num_materials)
                        
                        // loading faceshaders & facemodifiers array
                        for materialIdx in 0 ..< attrib.num_face_num_verts {
                            materialsIds.append(Int32(attrib.material_ids[Int(materialIdx)]))
                        }
                        
                        // index for the modifiers array
                        var materialIdx: Int32 = 0
                        var modifierIdx: Int32 = 0
                        
                        // loading real shaders & modifiers
                        for material in UnsafeBufferPointer(start: materials, count: num_materials) {
                            if material.dissolve < 1.0 { // d < 1.0 -> transparent material
                                let shader = GlassShaderParameter(String.init(cString: material.name))
                                
                                shader.color = Color(material.specular.0, material.specular.1, material.specular.2)
                                
                                // IOR
                                shader.eta = material.ior
                                
                                if (material.bump_texname != nil) {
                                    let bump = BumpMapModifierParameter(String.init(cString: material.name) + "_bump")
                                    
                                    let _bumpTexture = String.init(cString: material.bump_texname)
                                    
                                    if _bumpTexture.hasPrefix("-bm") {
                                        // find multiplier
                                        let _components = _bumpTexture.components(separatedBy: .whitespaces)
                                        
                                        bump.scale = Float(_components[1]) ?? 1.0 // scale
                                        
                                        bump.texture = _components[2] // filename
                                    } else {
                                         bump.texture = _bumpTexture
                                    }
                                    
                                    // insert modifiers in the right index (same index as faceshader)
                                    modifiersIds[Int(materialIdx)] = modifierIdx
                                    
                                    modifierIdx += 1
                                    
                                    shaders!.append((shader, bump))
                                } else {
                                    shaders!.append((shader, nil))
                                }
                            } else {
                                // FIXME: choose best shader implementation
                                /*
                                // phong shader
                                let shader = PhongShaderParameter(String.init(cString: material.name))
                                
                                shader.diffuse = Color(material.diffuse.0, material.diffuse.1, material.diffuse.2)
                                
                                if (material.diffuse_texname != nil) {
                                    shader.texture = String.init(cString: material.diffuse_texname)
                                }
                                
                                shader.specular = Color(material.specular.0, material.specular.1, material.specular.2)
                                shader.power = material.shininess
                                */
                                
                                // uber shader
                                let shader = UberShaderParameter(String.init(cString: material.name))
                                
                                shader.diffuse = Color(material.diffuse.0, material.diffuse.1, material.diffuse.2)
                                
                                if (material.diffuse_texname != nil) { // diffuse texture
                                    shader.diffuseTexture = String.init(cString: material.diffuse_texname)
                                }
                                
                                shader.specular = Color(material.specular.0, material.specular.1, material.specular.2)
                                shader.glossyness = material.shininess
                                
                                if (material.specular_texname != nil) { // specular texture
                                    shader.specularTexture = String.init(cString: material.specular_texname)
                                }
                                
                                /*
                                // diffuse shader
                                let shader = DiffuseShaderParameter(String.init(cString: material.name))
                                
                                shader.diffuse = Color(material.diffuse.0, material.diffuse.1, material.diffuse.2)
                                
                                if (material.diffuse_texname != nil) {
                                    shader.texture = String.init(cString: material.diffuse_texname)
                                }
                                */
                                
                                if (material.bump_texname != nil) { // loading modifiers
                                    let bump = BumpMapModifierParameter(String.init(cString: material.name) + "_bump")
                                    
                                    let _bumpTexture = String.init(cString: material.bump_texname)
                                    
                                    if _bumpTexture.hasPrefix("-bm") {
                                        // find multiplier
                                        let _components = _bumpTexture.components(separatedBy: .whitespaces)
                                        
                                        bump.scale = Float(_components[1]) ?? 1.0 // scale
                                        
                                        bump.texture = _components[2] // filename
                                    } else {
                                         bump.texture = _bumpTexture
                                    }
                                    
                                    // insert modifiers in the right index (same index as faceshader)
                                    modifiersIds[Int(materialIdx)] = modifierIdx
                                    
                                    modifierIdx += 1
                                    
                                    shaders!.append((shader, bump))
                                } else {
                                    shaders!.append((shader, nil))
                                }
                            }
                            
                            materialIdx += 1
                        }
                    }
                    
                    // FIXME: controllare se questi causano il segmentation fault
                    //tinyobj_attrib_free(&attrib)
                    //tinyobj_shapes_free(shapes, num_shapes)
                    //tinyobj_materials_free(materials, num_materials)
                    
                    t.end()
                    
                    UI.printDetailed(.GEOM, "  * Parsing time:  \(t.toString())")
                    
                    UI.printInfo(.GEOM, "  * Creating mesh ...")
                } else {
                    // FIXME: complete parsing implementations (material, triangulate..)
                    UI.printInfo(.GEOM, "  * Trying brutal parsing ...")
                    
                    brutal = true
                    
                    t.start()
                    
                    let objLoader = ObjectLoader(URL(fileURLWithPath: filename!))
                    
                    let (state, _) = try! objLoader.read()
                    
                    for vertex in state.vertices {
                        vertices.append(Float(vertex[0]))
                        vertices.append(Float(vertex[1]))
                        vertices.append(Float(vertex[2]))
                    }
                    
                    for face in state.faces {
                        tris.append(face[0].vIndex!)
                        tris.append(face[1].vIndex!)
                        tris.append(face[2].vIndex!)
                    }
                    
                    t.end()
                    
                    UI.printDetailed(.GEOM, "  * brutal parsing time:  \(t.toString())")
                    
                    UI.printInfo(.GEOM, "  * Creating mesh ...")
                }
            } catch {
                // FIXME: gestire i vari tipi di eccezioni
                UI.printWarning(.GEOM, "Unable to read mesh file \"\(filename!)\" - parsing error: \(error)")
                
                return nil
            }        } else {
            UI.printWarning(.GEOM, "Unable to read mesh file \"\(filename!)\" - unrecognized format")
        }
        
        t.end()
        
        UI.printDetailed(.GEOM, "  * Tesselation time:  \(t.toString())")
        
        if !brutal {
            return generate(tris, vertices, normals, uvs, materialsIds, modifiersIds, shaders)
        } else {
            return generate(tris, vertices, true)
        }
    }
    
    func generate(_ tris: [Int32], _ verts: [Float], _ normals: [Float], _ uvs: [Float], _ materialIds: [Int32], _ modifiersIds: [Int32], _ shaders: [(ShaderParameter, ModifierParameter?)]?) -> TriangleMesh? {
        let pl: ParameterList = ParameterList()
        
        // adding vertices and triangles to parameter list
        pl.addIntegerArray("triangles", tris)
        pl.addPoints("points", .VERTEX, verts)
        
        if normals.count != 0 {
            // normals from file mesh
            pl.addVectors("normals", .FACEVARYING, normals)
        } else if smoothNormals {
            UI.printDetailed(.GEOM, "  * Smoothing normals ...")
            
            var normals: [Float] = [Float](repeating: 0, count: verts.count) //  filled with 0's
            let p0: Point3 = Point3()
            let p1: Point3 = Point3()
            let p2: Point3 = Point3()
            var n: Vector3 = Vector3()
            
            for i3 in stride(from: 0, to: tris.count, by: 3) {
                let v0: Int32 = tris[Int(i3) + 0]
                let v1: Int32 = tris[Int(i3) + 1]
                let v2: Int32 = tris[Int(i3) + 2]
                
                p0.set(verts[3 * Int(v0) + 0], verts[3 * Int(v0) + 1], verts[3 * Int(v0) + 2])
                p1.set(verts[3 * Int(v1) + 0], verts[3 * Int(v1) + 1], verts[3 * Int(v1) + 2])
                p2.set(verts[3 * Int(v2) + 0], verts[3 * Int(v2) + 1], verts[3 * Int(v2) + 2])
                
                n = Point3.normal(p0, p1, p2) //  compute normal
                
                //  add face normal to each vertex
                //  note that these are not normalized so this in fact weights
                //  each normal by the area of the triangle
                normals[3 * Int(v0) + 0] += n.x
                normals[3 * Int(v0) + 1] += n.y
                normals[3 * Int(v0) + 2] += n.z
                normals[3 * Int(v1) + 0] += n.x
                normals[3 * Int(v1) + 1] += n.y
                normals[3 * Int(v1) + 2] += n.z
                normals[3 * Int(v2) + 0] += n.x
                normals[3 * Int(v2) + 1] += n.y
                normals[3 * Int(v2) + 2] += n.z
            }
            
            // normalize all the vectors
            for i3 in stride(from: 0, to: normals.count, by: 3) {
                n.set(normals[Int(i3) + 0], normals[Int(i3) + 1], normals[Int(i3) + 2])
                
                n.normalize()
                
                normals[Int(i3) + 0] = n.x
                normals[Int(i3) + 1] = n.y
                normals[Int(i3) + 2] = n.z
            }
            
            pl.addVectors("normals", ParameterList.InterpolationType.VERTEX, normals)
        }
        
        if uvs.count != 0 {
            // adding tex coordsto parameter list
            pl.addTexCoords("uvs", .FACEVARYING, uvs)
        }
        
        if shaders != nil { // shaders & modifiers from mesh file
            // adding faceshader to parameter list (list of ids)
            pl.addIntegerArray("faceshaders", materialIds)
            
            // adding facemodifiers to parameter list (list of ids)
            pl.addIntegerArray("facemodifiers", modifiersIds)
            
            for shader in shaders! {
                // setup shader
                shader.0.setup()
                
                if shader.1 != nil {
                    //setup modifier
                    shader.1!.setup()
                }
            }
            
            // adding new shader names to parameter list
            pl.addStringArray("objshaders", shaders!.map(\.0.name))
            
            // adding new modifier names to parameter list
            pl.addStringArray("objmodifiers", shaders!.map { $0.1?.name ?? "" }.filter({ $0 != "" }))
        }

        let m: TriangleMesh = TriangleMesh()
        
        // update mesh with parameter list
        if m.update(pl) {
            return m
        }
        
        //  something failed in creating the mesh, the error message will be
        //  printed by the mesh itself - no need to repeat it here
        return nil
    }
    
    func generate(_ tris: [Int32], _ verts: [Float], _ smoothNormals: Bool) -> TriangleMesh? {
        let pl: ParameterList = ParameterList()
        
        pl.addIntegerArray("triangles", tris)
        pl.addPoints("points", ParameterList.InterpolationType.VERTEX, verts)
        
        if smoothNormals {
            UI.printDetailed(.GEOM, "  * Smoothing normals ...")
            
            var normals: [Float] = [Float](repeating: 0, count: verts.count) //  filled with 0's
            let p0: Point3 = Point3()
            let p1: Point3 = Point3()
            let p2: Point3 = Point3()
            var n: Vector3 = Vector3()
            
            for i3 in stride(from: 0, to: tris.count, by: 3) {
                let v0: Int32 = tris[Int(i3) + 0]
                let v1: Int32 = tris[Int(i3) + 1]
                let v2: Int32 = tris[Int(i3) + 2]
                
                p0.set(verts[3 * Int(v0) + 0], verts[3 * Int(v0) + 1], verts[3 * Int(v0) + 2])
                p1.set(verts[3 * Int(v1) + 0], verts[3 * Int(v1) + 1], verts[3 * Int(v1) + 2])
                p2.set(verts[3 * Int(v2) + 0], verts[3 * Int(v2) + 1], verts[3 * Int(v2) + 2])
                
                n = Point3.normal(p0, p1, p2) //  compute normal
                
                //  add face normal to each vertex
                //  note that these are not normalized so this in fact weights
                //  each normal by the area of the triangle
                normals[3 * Int(v0) + 0] += n.x
                normals[3 * Int(v0) + 1] += n.y
                normals[3 * Int(v0) + 2] += n.z
                normals[3 * Int(v1) + 0] += n.x
                normals[3 * Int(v1) + 1] += n.y
                normals[3 * Int(v1) + 2] += n.z
                normals[3 * Int(v2) + 0] += n.x
                normals[3 * Int(v2) + 1] += n.y
                normals[3 * Int(v2) + 2] += n.z
            }
            
            // normalize all the vectors
            for i3 in stride(from: 0, to: normals.count, by: 3) {
                n.set(normals[Int(i3) + 0], normals[Int(i3) + 1], normals[Int(i3) + 2])
                
                n.normalize()
                
                normals[Int(i3) + 0] = n.x
                normals[Int(i3) + 1] = n.y
                normals[Int(i3) + 2] = n.z
            }
            
            pl.addVectors("normals", ParameterList.InterpolationType.VERTEX, normals)
        }
        
        let m: TriangleMesh = TriangleMesh()
        
        if m.update(pl) {
            return m
        }
        
        //  something failed in creating the mesh, the error message will be
        //  printed by the mesh itself - no need to repeat it here
        return nil
    }
    
    func getLittleEndianInt(_ i: Int32) -> Int32 {
        //  input integer has its bytes in big endian byte order
        //  swap them around
        return (i >>> 24) | ((i >>> 8) & 0xFF00) | ((i << 8) & 0xFF0000) | (i << 24)
    }
    
    func getLittleEndianFloat(_ i: Int32) -> Float {
        //  input integer has its bytes in big endian byte order
        //  swap them around and interpret data as floating point
        return ByteUtil.intBitsToFloat(getLittleEndianInt(i))
    }
}
