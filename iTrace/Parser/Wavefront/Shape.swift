//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

import Foundation

#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

// N dimensional vector
typealias VectorShape = [Double]

final class VertexIndex {
    let vIndex: Int32? // Vertex index, zero-based
    let nIndex: Int32? // Normal index, zero-based
    let tIndex: Int32? // Texture Coordinates index, zero-based

    init(vIndex: Int32?, nIndex: Int32?, tIndex: Int32?) {
        self.vIndex = vIndex
        self.nIndex = nIndex
        self.tIndex = tIndex
    }
}

extension VertexIndex: Equatable {}

func == (lhs: VertexIndex, rhs: VertexIndex) -> Bool {
    return lhs.vIndex == rhs.vIndex &&
        lhs.nIndex == rhs.nIndex &&
        lhs.tIndex == rhs.tIndex
}

extension VertexIndex: CustomStringConvertible {
    public var description: String {
        return "\(vIndex ?? 0)/\(nIndex ?? 0)/\(tIndex ?? 0)"
    }
}

final class Shape {
    let name: String?
    let vertices: [VectorShape]
    let normals: [VectorShape]
    let textureCoords: [VectorShape]
    let material: Material?

    // Definition of faces that make up the shape
    // indexes are into the vertices, normals and
    // texture coords of this shape
    //
    // Example:
    //   VertexIndex(vIndex: 4, nIndex: 2, tIndex: 0)
    // Refers to vertices[4], normals[2] and textureCoords[0]
    //
    let faces: [[VertexIndex]]

    init(name: String?,
         vertices: [VectorShape],
         normals: [VectorShape],
         textureCoords: [VectorShape],
         material: Material?,
         faces: [[VertexIndex]]) {
        self.name = name
        self.vertices = vertices
        self.normals = normals
        self.textureCoords = textureCoords
        self.material = material
        self.faces = faces
    }

    func dataForVertexIndex(v: VertexIndex) -> (VectorShape?, VectorShape?, VectorShape?) {
        var data: (VectorShape?, VectorShape?, VectorShape?) = (nil, nil, nil)

        if let vi = v.vIndex {
            data.0 = vertices[Int(vi)]
        }

        if let ni = v.nIndex {
            data.1 = normals[Int(ni)]
        }

        if let ti = v.tIndex {
            data.2 = textureCoords[Int(ti)]
        }

        return data
    }
}

extension Shape: Equatable {}

func nestedEquality<T>(_ lhs: [[T]], _ rhs: [[T]], equal: ([T], [T]) -> Bool) -> Bool {
    if lhs.count != rhs.count {
        return false
    }

    for i in 0..<lhs.count {
        if equal(lhs[i], rhs[i]) == false {
            return false
        }
    }

    return true
}

func == (lhs: Shape, rhs: Shape) -> Bool {
    if lhs.name != rhs.name {
        return false
    }

    let lengthCheck: (VectorShape, VectorShape) -> Bool = { a, b in
        a.count == b.count
    }

    if !nestedEquality(lhs.vertices, rhs.vertices, equal: lengthCheck) ||
        !nestedEquality(lhs.normals, rhs.normals, equal: lengthCheck) ||
        !nestedEquality(lhs.textureCoords, rhs.textureCoords, equal: lengthCheck) {
        return false
    }

    let valueCheck: (VectorShape, VectorShape) -> Bool = { a, b in
        for i in 0..<a.count {
            if !MathUtils.doubleEquality(a[i], b[i]) {
                return false
            }
        }
        return true
    }

    if !nestedEquality(lhs.vertices, rhs.vertices, equal: valueCheck) ||
        !nestedEquality(lhs.normals, rhs.normals, equal: valueCheck) ||
        !nestedEquality(lhs.textureCoords, rhs.textureCoords, equal: valueCheck) {
        return false
    }

    if !nestedEquality(lhs.faces, rhs.faces, equal: { $0.count == $1.count }) {
        return false
    }

    let vertexIndexCheck: ([VertexIndex], [VertexIndex]) -> Bool = { a, b in
        for i in 0..<a.count {
            if a[i] != b[i] {
                return false
            }
        }
        return true
    }

    if !nestedEquality(lhs.faces, rhs.faces, equal: vertexIndexCheck) {
        return false
    }

    if lhs.material != rhs.material {
        return false
    }

    return true
}
