//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

class ParameterList {
    static let PARAM_COLOR = "color"
    static let PARAM_SHADERS = "shaders"

    var list: [String: Parameter]
    var numVerts: Int32 = 0
    var numFaces: Int32 = 0
    var numFaceVerts: Int32 = 0

    // Creates an empty ParameterList.
    required init() {
        list = [String: Parameter]()

        numVerts = 0
        numFaces = 0
        numFaceVerts = 0
    }

    // Clears the list of all its members. If some members were never used, a
    // warning will be printed to remind the user something may be wrong.
    func clear(_ showUnused: Bool) {
        if showUnused {
            for e in list {
                if !e.value.checked {
                    UI.printWarning(.API, "Unused parameter: \(e.key) - \(e.value)")
                }
            }
        }

        list.removeAll()

        numVerts = 0
        numFaces = 0
        numFaceVerts = 0
    }

    // Setup how many faces should be used to check member count on "face"
    // interpolated parameters.
    //
    // @param numFaces number of faces
    func setFaceCount(_ numFaces: Int32) {
        self.numFaces = numFaces
    }

    // Setup how many vertices should be used to check member count of "vertex"
    // interpolated parameters.
    //
    // @param numVerts number of vertices
    func setVertexCount(_ numVerts: Int32) {
        self.numVerts = numVerts
    }

    // Setup how many "face-vertices" should be used to check member count of
    // "facevarying" interpolated parameters. This should be equal to the sum of
    // the number of vertices on each face.
    //
    // @param numFaceVerts number of "face-vertices"
    func setFaceVertexCount(_ numFaceVerts: Int32) {
        self.numFaceVerts = numFaceVerts
    }

    // Add the specified string as a parameter. null values are
    // not permitted.
    //
    // @param name parameter name
    // @param value parameter value
    func addString(_ name: String, _ value: String) {
        add(name, Parameter(value))
    }

    // Add the specified integer as a parameter. null values are
    // not permitted.
    //
    // @param name parameter name
    // @param value parameter value
    func addInteger(_ name: String, _ value: Int32) {
        add(name, Parameter(value))
    }

    // Add the specified bool as a parameter. null values are
    // not permitted.
    //
    // @param name parameter name
    // @param value parameter value
    func addBool(_ name: String, _ value: Bool) {
        add(name, Parameter(value))
    }

    // Add the specified float as a parameter. null values are
    // not permitted.
    //
    // @param name parameter name
    // @param value parameter value
    func addFloat(_ name: String, _ value: Float) {
        add(name, Parameter(value))
    }

    // Add the specified color as a parameter. null values are
    // not permitted.
    //
    // @param name parameter name
    // @param value parameter value
    func addColor(_ name: String, _ value: Color?) {
        if value == nil {
            UI.printError(.API, "Value is null")

            fatalError("Value is null")
        }

        add(name, Parameter(value!))
    }

    // Add the specified array of integers as a parameter. null
    // values are not permitted.
    //
    // @param name parameter name
    // @param array parameter value
    func addIntegerArray(_ name: String, _ array: [Int32]?) {
        if array == nil {
            UI.printError(.API, "Value is null")

            fatalError("Value is null")
        }

        add(name, Parameter(array!))
    }

    // Add the specified array of integers as a parameter. null
    // values are not permitted.
    //
    // @param name parameter name
    // @param array parameter value
    func addStringArray(_ name: String, _ array: [String]?) {
        if array == nil {
            UI.printError(.API, "Value is null")

            fatalError("Value is null")
        }

        add(name, Parameter(array!))
    }

    // Add the specified floats as a parameter. null values are
    // not permitted.
    //
    // @param name parameter name
    // @param interp interpolation type
    // @param data parameter value
    func addFloats(_ name: String, _ interp: InterpolationType, _ data: [Float]?) {
        if data == nil {
            UI.printError(.API, "Cannot create float parameter \(name) -- invalid data Length")

            return
        }

        add(name, Parameter(ParameterType.FLOAT, interp, data!))
    }

    // Add the specified points as a parameter. null values are
    // not permitted.
    //
    // @param name parameter name
    // @param interp interpolation type
    // @param data parameter value
    func addPoints(_ name: String, _ interp: InterpolationType, _ data: [Float]?) {
        //if (data == nil) || ((data!.count % 3) != 0) {
        //    UI.printError(.API, "Cannot create point parameter \(name) -- invalid data Length")
        //
        //    return
        //}

        add(name, Parameter(ParameterType.POINT, interp, data!))
    }

    // Add the specified vectors as a parameter. null values are
    // not permitted.
    //
    // @param name parameter name
    // @param interp interpolation type
    // @param data parameter value
    func addVectors(_ name: String, _ interp: InterpolationType, _ data: [Float]?) {
        if (data == nil) || ((data!.count % 3) != 0) {
            UI.printError(.API, "Cannot create vector parameter \(name) -- invalid data Length")

            return
        }

        add(name, Parameter(ParameterType.VECTOR, interp, data!))
    }

    // Add the specified texture coordinates as a parameter. null
    // values are not permitted.
    //
    // @param name parameter name
    // @param interp interpolation type
    // @param data parameter value
    func addTexCoords(_ name: String, _ interp: InterpolationType, _ data: [Float]?) {
        if (data == nil) || ((data!.count % 2) != 0) {
            UI.printError(.API, "Cannot create texcoord parameter \(name) -- invalid data Length")

            return
        }

        add(name, Parameter(ParameterType.TEXCOORD, interp, data!))
    }

    // Add the specified matrices as a parameter. null values are
    // not permitted.
    //
    // @param name parameter name
    // @param interp interpolation type
    // @param data parameter value
    func addMatrices(_ name: String, _ interp: InterpolationType, _ data: [Float]?) {
        if (data == nil) || ((data!.count % 16) != 0) {
            UI.printError(.API, "Cannot create matrix parameter \(name) -- invalid data Length")

            return
        }

        add(name, Parameter(ParameterType.MATRIX, interp, data!))
    }

    func add(_ name: String?, _ param: Parameter?) {
        if name == nil {
            UI.printError(.API, "Cannot declare parameter with null name")
        }

        if list[name!] != nil {
            UI.printWarning(.API, "Parameter \(name ?? "n/a") was already defined -- overwriting")
        }

        list[name!] = param!
    }

    // Get the specified string parameter from this list.
    //
    // @param name name of the parameter
    // @param defaultValue value to return if not found
    // @return the value of the parameter specified or default value if not
    //         found
    func getString(_ name: String, _ defaultValue: String?) -> String? {
        if let p = list[name] {
            if isValidParameter(name, ParameterType.STRING, InterpolationType.NONE, 1, p) {
                return p.getStringValue()
            }
        }

        return defaultValue
    }

    // Get the specified string array parameter from this list.
    //
    // @param name name of the parameter
    // @param defaultValue value to return if not found
    // @return the value of the parameter specified or default value if not
    //         found
    func getStringArray(_ name: String, _ defaultValue: [String]?) -> [String]? {
        if let p = list[name] {
            if isValidParameter(name, ParameterType.STRING, InterpolationType.NONE, -1, p) {
                return p.getStrings()
            }
        }

        return defaultValue
    }

    // Get the specified integer parameter from this list.
    //
    // @param name name of the parameter
    // @param defaultValue value to return if not found
    // @return the value of the parameter specified or default value if not
    //         found
    func getInt(_ name: String, _ defaultValue: Int32?) -> Int32? {
        if let p = list[name] {
            if isValidParameter(name, ParameterType.INT, InterpolationType.NONE, 1, p) {
                return p.getIntValue()
            }
        }

        return defaultValue
    }

    // Get the specified integer array parameter from this list.
    //
    // @param name name of the parameter
    // @return the value of the parameter specified or null if
    //         not found
    func getIntArray(_ name: String) -> [Int32]? {
        if let p = list[name] {
            if isValidParameter(name, ParameterType.INT, InterpolationType.NONE, -1, p) {
                return p.getInts()
            }
        }

        return nil
    }

    // Get the specified bool parameter from this list.
    //
    // @param name name of the parameter
    // @param defaultValue value to return if not found
    // @return the value of the parameter specified or default value if not
    //         found
    func getBool(_ name: String, _ defaultValue: Bool?) -> Bool? {
        if let p = list[name] {
            if isValidParameter(name, ParameterType.BOOL, InterpolationType.NONE, 1, p) {
                return p.getBoolValue()
            }
        }

        return defaultValue
    }

    // Get the specified float parameter from this list.
    //
    // @param name name of the parameter
    // @param defaultValue value to return if not found
    // @return the value of the parameter specified or default value if not
    //         found
    func getFloat(_ name: String, _ defaultValue: Float?) -> Float? {
        if let p = list[name] {
            if isValidParameter(name, ParameterType.FLOAT, InterpolationType.NONE, 1, p) {
                return p.getFloatValue()
            }
        }

        return defaultValue
    }

    // Get the specified color parameter from this list.
    //
    // @param name name of the parameter
    // @param defaultValue value to return if not found
    // @return the value of the parameter specified or default value if not
    //         found
    func getColor(_ name: String, _ defaultValue: Color?) -> Color? {
        if let p = list[name] {
            if isValidParameter(name, ParameterType.COLOR, InterpolationType.NONE, 1, p) {
                return p.getColor()
            }
        }

        return defaultValue
    }

    // Get the specified point parameter from this list.
    //
    // @param name name of the parameter
    // @param defaultValue value to return if not found
    // @return the value of the parameter specified or default value if not
    //         found
    func getPoint(_ name: String, _ defaultValue: Point3?) -> Point3? {
        if let p = list[name] {
            if isValidParameter(name, ParameterType.POINT, InterpolationType.NONE, 1, p) {
                return p.getPoint()
            }
        }

        return defaultValue
    }

    // Get the specified vector parameter from this list.
    //
    // @param name name of the parameter
    // @param defaultValue value to return if not found
    // @return the value of the parameter specified or default value if not
    //         found
    func getVector(_ name: String, _ defaultValue: Vector3?) -> Vector3? {
        if let p = list[name] {
            if isValidParameter(name, ParameterType.VECTOR, InterpolationType.NONE, 1, p) {
                return p.getVector()
            }
        }

        return defaultValue
    }

    // Get the specified texture coordinate parameter from this list.
    //
    // @param name name of the parameter
    // @param defaultValue value to return if not found
    // @return the value of the parameter specified or default value if not
    //         found
    func getTexCoord(_ name: String, _ defaultValue: Point2?) -> Point2? {
        if let p = list[name] {
            if isValidParameter(name, ParameterType.TEXCOORD, InterpolationType.NONE, 1, p) {
                return p.getTexCoord()
            }
        }

        return defaultValue
    }

    // Get the specified matrix parameter from this list.
    //
    // @param name name of the parameter
    // @param defaultValue value to return if not found
    // @return the value of the parameter specified or default value if not
    //         found
    func getMatrix(_ name: String, _ defaultValue: AffineTransform?) -> AffineTransform? {
        if let p = list[name] {
            if isValidParameter(name, ParameterType.MATRIX, InterpolationType.NONE, 1, p) {
                return p.getMatrix()
            }
        }

        return defaultValue
    }

    // Get the specified float array parameter from this list.
    //
    // @param name name of the parameter
    // @return the value of the parameter specified or null if
    //         not found
    func getFloatArray(_ name: String) -> FloatParameter? {
        return getFloatParameter(name, ParameterType.FLOAT, list[name])
    }

    // Get the specified point array parameter from this list.
    //
    // @param name name of the parameter
    // @return the value of the parameter specified or null if
    //         not found
    func getPointArray(_ name: String) -> FloatParameter? {
        return getFloatParameter(name, ParameterType.POINT, list[name])
    }

    // Get the specified vector array parameter from this list.
    //
    // @param name name of the parameter
    // @return the value of the parameter specified or null if
    //         not found
    func getVectorArray(_ name: String) -> FloatParameter? {
        return getFloatParameter(name, ParameterType.VECTOR, list[name])
    }

    // Get the specified texture coordinate array parameter from this list.
    //
    // @param name name of the parameter
    // @return the value of the parameter specified or null if
    //         not found
    func getTexCoordArray(_ name: String) -> FloatParameter? {
        return getFloatParameter(name, ParameterType.TEXCOORD, list[name])
    }

    // Get the specified matrix array parameter from this list.
    //
    // @param name name of the parameter
    // @return the value of the parameter specified or null if
    //         not found
    func getMatrixArray(_ name: String) -> FloatParameter? {
        return getFloatParameter(name, ParameterType.MATRIX, list[name])
    }

    func isValidParameter(_ name: String, _ type: ParameterType, _ interp: InterpolationType, _ requestedSize: Int32, _ p: Parameter?) -> Bool {
        if p == nil {
            return false
        }

        if p!.type != type {
            UI.printWarning(.API, "Parameter \(name) requested as a \(type) - declared as \(p!.type)")
            return false
        }

        if p!.interp != interp {
            UI.printWarning(.API, "Parameter \(name) requested as a \(interp) - declared as \(p!.interp)")
            return false
        }

        if (requestedSize > 0) && (p!.size() != requestedSize) {
            UI.printWarning(.API, "Parameter \(name) requires \(requestedSize) \(requestedSize == 1 ? "value" : "values") - declared with \(p!.size())")
            return false
        }

        p!.checked = true

        return true
    }

    func getFloatParameter(_ name: String, _ type: ParameterType, _ p: Parameter?) -> FloatParameter? {
        if p == nil {
            return nil
        }

        switch p!.interp {
            case InterpolationType.NONE:
                if !isValidParameter(name, type, p!.interp, -1, p) {
                    return nil
                }
            case InterpolationType.VERTEX:
                if !isValidParameter(name, type, p!.interp, numVerts, p) {
                    return nil
                }
            case InterpolationType.FACE:
                if !isValidParameter(name, type, p!.interp, numFaces, p) {
                    return nil
                }
            case InterpolationType.FACEVARYING:
                if !isValidParameter(name, type, p!.interp, numFaceVerts, p) {
                    return nil
                }
        }

        return p!.getFloats()
    }

    func getMovingMatrix(_ name: String, _ defaultValue: TimeAffineTransform) -> TimeAffineTransform? {
        //  step 1: check for a non-moving specification:
        let m: AffineTransform? = getMatrix(name, nil)

        if m != nil {
            return TimeAffineTransform(m!)
        }

        //  step 2: check to see if the time range has been updated
        let times: FloatParameter? = getFloatArray(name + ".times")

        if times != nil {
            if times!.data!.count <= 1 {
                defaultValue.updateTimes(0, 0)
            } else {
                if times!.data!.count != 2 {
                    UI.printWarning(.API, "Time value specification using only endpoints of \(times!.data!.count) values specified")
                }

                //  get endpoint times - we might allow multiple time values
                //  later
                let t0: Float = times!.data![0]
                let t1: Float = times!.data![times!.data!.count - 1]

                defaultValue.updateTimes(t0, t1)
            }
        } else {
            // time range stays at default
        }

        //  step 3: check to see if a number of steps has been specified
        let steps: Int32 = getInt(name + ".steps", 0)!

        if steps <= 0 {
            //  not specified - return default value
        } else {
            //  update each element
            defaultValue.setSteps(steps)

            for i in 0 ..< steps {
                defaultValue.updateData(i, getMatrix("\(name)[\(i)]", defaultValue.getData(i))!)
            }
        }

        return defaultValue
    }

    enum ParameterType {
        case STRING
        case INT
        case BOOL
        case FLOAT
        case POINT
        case VECTOR
        case TEXCOORD
        case MATRIX
        case COLOR
    }

    enum InterpolationType: String, CustomStringConvertible {
        case NONE = "none"
        case FACE = "face"
        case VERTEX = "vertex"
        case FACEVARYING = "facevarying"

        var description: String {
            return rawValue
        }
    }

    final class FloatParameter {
        var interp: InterpolationType
        var data: [Float]?

        convenience init() {
            self.init(InterpolationType.NONE, nil)
        }

        convenience init(_ f: Float) {
            self.init(InterpolationType.NONE, [Float]([f]))
        }

        init(_ interp: InterpolationType, _ data: [Float]?) {
            self.interp = interp
            self.data = data
        }
    }

    final class Parameter {
        var type: ParameterType
        var interp: InterpolationType
        var obj: Any
        var checked: Bool = false

        init(_ value: String) {
            type = ParameterType.STRING
            interp = InterpolationType.NONE
            obj = ([value] as [String])
            checked = false
        }

        init(_ value: Int32) {
            type = ParameterType.INT
            interp = InterpolationType.NONE
            obj = ([value] as [Int32])
            checked = false
        }

        init(_ value: Bool) {
            type = ParameterType.BOOL
            interp = InterpolationType.NONE
            obj = value
            checked = false
        }

        init(_ value: Float) {
            type = ParameterType.FLOAT
            interp = InterpolationType.NONE
            obj = ([value] as [Float])
            checked = false
        }

        init(_ array: [Int32]) {
            type = ParameterType.INT
            interp = InterpolationType.NONE
            obj = array
            checked = false
        }

        init(_ array: [String]) {
            type = ParameterType.STRING
            interp = InterpolationType.NONE
            obj = array
            checked = false
        }

        init(_ c: Color) {
            type = ParameterType.COLOR
            interp = InterpolationType.NONE
            obj = c
            checked = false
        }

        init(_ type: ParameterType, _ interp: InterpolationType, _ data: [Float]) {
            self.type = type
            self.interp = interp
            obj = data
            checked = false
        }

        func size() -> Int32 {
            //  number of elements
            switch type {
            case ParameterType.STRING:
                return Int32((obj as! [String]).count)
            case ParameterType.INT:
                return Int32((obj as! [Int32]).count)
            case ParameterType.BOOL:
                return 1
            case ParameterType.FLOAT:
                return Int32((obj as! [Float]).count)
            case ParameterType.POINT:
                return Int32((obj as! [Float]).count / 3)
            case ParameterType.VECTOR:
                return Int32((obj as! [Float]).count / 3)
            case ParameterType.TEXCOORD:
                return Int32((obj as! [Float]).count / 2)
            case ParameterType.MATRIX:
                return Int32((obj as! [Float]).count / 16)
            case ParameterType.COLOR:
                return 1
            }
        }

        func check() {
            checked = true
        }

        var description: String { "\(interp == InterpolationType.NONE ? "" : interp.description)\(type)[\(size())]" }

        func getStringValue() -> String {
            return (obj as! [String])[0]
        }

        func getBoolValue() -> Bool {
            return (obj as! Bool)
        }

        func getIntValue() -> Int32 {
            return (obj as! [Int32])[0]
        }

        func getInts() -> [Int32] {
            return (obj as! [Int32])
        }

        func getStrings() -> [String] {
            return (obj as! [String])
        }

        func getFloatValue() -> Float {
            return (obj as! [Float])[0]
        }

        func getFloats() -> FloatParameter {
            return FloatParameter(interp, (obj as! [Float]))
        }

        func getPoint() -> Point3 {
            let floats: [Float] = (obj as! [Float])

            return Point3(floats[0], floats[1], floats[2])
        }

        func getVector() -> Vector3 {
            let floats: [Float] = (obj as! [Float])

            return Vector3(floats[0], floats[1], floats[2])
        }

        func getTexCoord() -> Point2 {
            let floats: [Float] = (obj as! [Float])

            return Point2(floats[0], floats[1])
        }

        func getMatrix() -> AffineTransform {
            let floats: [Float] = (obj as! [Float])

            return AffineTransform(floats, true)
        }

        func getColor() -> Color {
            return (obj as! Color)
        }
    }
}
