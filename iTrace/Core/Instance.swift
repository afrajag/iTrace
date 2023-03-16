//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

import Foundation

final class Instance: RenderObject {
    var o2w: TimeAffineTransform?
    var w2o: TimeAffineTransform?
    var bounds: BoundingBox?
    var geometry: Geometry?
    var shaders: [Shader]?
    var modifiers: [Modifier]?

    required init() {
        o2w = TimeAffineTransform(nil)
        w2o = TimeAffineTransform(nil)
        bounds = nil
        geometry = nil
        shaders = nil
        modifiers = nil
    }

    static func createTemporary(_ primitives: PrimitiveList, _ transform: AffineTransform?, _ shader: Shader) -> Instance? {
        let i: Instance = Instance()

        i.o2w = TimeAffineTransform(transform)

        i.w2o = i.o2w!.inverse()!

        if i.w2o == nil {
            UI.printError(.GEOM, "Unable to compute transform inverse")

            return nil
        }

        i.geometry = Geometry(primitives)
        
        i.shaders = [shader]

        i.updateBounds()

        return i
    }

    @discardableResult
    func update(_ pl: ParameterList) -> Bool {
        let geometryName: String? = pl.getString("geometry", nil)

        if (geometry == nil) || geometryName != nil {
            if geometryName == nil {
                UI.printError(.GEOM, "geometry parameter missing - unable to create instance")

                return false
            }

            geometry = API.shared.lookupGeometry(geometryName!)

            if geometry == nil {
                UI.printError(.GEOM, "Geometry \"\(geometryName ?? "geometry_name")\" was not declared yet - instance is invalid")

                return false
            }
        }

        let shaderNames: [String]? = pl.getStringArray("shaders", nil)

        if shaderNames != nil {
            //  new shader names have been provided
            shaders = [Shader]()

            for i in 0 ..< shaderNames!.count {
                if API.shared.lookupShader(shaderNames![i]) == nil {
                    UI.printWarning(.GEOM, "Shader \"\(shaderNames![i])\" was not declared yet - ignoring")
                } else {
                    // shaders![i] = API.shared.lookupShader(shaderNames![i])!
                    shaders!.append(API.shared.lookupShader(shaderNames![i])!)
                }
            }
        }

        let modifierNames: [String]? = pl.getStringArray("modifiers", nil)

        if modifierNames != nil {
            //  new modifier names have been provided
            modifiers = [Modifier]()

            for i in 0 ..< modifierNames!.count {
                if API.shared.lookupModifier(modifierNames![i]) == nil {
                    UI.printWarning(.GEOM, "Modifier \"\(modifierNames![i])\" was not declared yet - ignoring")
                } else {
                    // modifiers![i] = API.shared.lookupModifier(modifierNames![i])!
                    modifiers!.append(API.shared.lookupModifier(modifierNames![i])!)
                }
            }
        }

        o2w = pl.getMovingMatrix("transform", o2w!)!

        w2o = o2w!.inverse()!

        if w2o == nil {
            UI.printError(.GEOM, "Unable to compute transform inverse")
            return false
        }

        return true
    }

    // Recompute world space bounding box of this instance.
    func updateBounds() {
        bounds = geometry!.getWorldBounds(o2w!.getData(0))

        for i in 1 ..< o2w!.numSegments() {
            bounds!.include(geometry!.getWorldBounds(o2w!.getData(i)!)!)
        }
    }

    // Checks to see if this instance is relative to the specified geometry.
    //
    // @param g geometry to check against
    // @return true if the instanced geometry is equals to g,
    //         false otherwise
    func hasGeometry(_ g: Geometry) -> Bool {
        return geometry?.description == g.description // FIXME: cambiare con qualcosa tipo equatable
    }
    
    // Remove the specified shader from the instance's list if it is being used.
    //
    // @param s shader to remove
    func removeShader(_ s: Shader) {
        if shaders != nil {
            shaders!.removeAll(where: { $0.description == s.description })
            // for i in 0 ... shaders!.count - 1 {

            // FIXME: ripristinare e anche qui utilizzare equatable
            /*
             if shaders![i] == s {
             	shaders[i] = nil
             }
             */

            // }
        }
    }

    // Remove the specified modifier from the instance's list if it is being
    // used.
    //
    // @param m modifier to remove
    func removeModifier(_ m: Modifier) {
        if modifiers != nil {
            modifiers!.removeAll(where: { $0.description == m.description })
            // for i in 0 ... modifiers!.count - 1 {

            // FIXME: ripristinare e anche qui utilizzare equatable
            /*
             if modifiers[i] == m {
             	modifiers[i] = nil
             }
             */
            // }
        }
    }

    // Get the world space bounding box for this instance.
    //
    // @return bounding box in world space
    func getBounds() -> BoundingBox? {
        return bounds
    }

    func getNumPrimitives() -> Int32 {
        return geometry!.getNumPrimitives()
    }

    func intersect(_ r: Ray, _ state: IntersectionState) {
        let extractedExpr: AffineTransform? = w2o!.sample(state.time)
        let localRay: Ray = r.transform(extractedExpr)

        state.current = self

        geometry!.intersect(localRay, state)

        //  FIXME: transfer max distance to current ray
        r.setMax(localRay.getMax())
    }

    // Prepare the shading state for shader invocation. This also runs the
    // currently attached surface modifier.
    //
    // @param state shading state to be prepared
    func prepareShadingState(_ state: ShadingState) {
        geometry!.prepareShadingState(state)

        if state.getNormal() != nil, state.getGeoNormal() != nil {
            state.correctShadingNormal()
        }

        //  run modifier if it was provided
        if state.getModifier() != nil {
            state.getModifier()!.modify(state)
        }
    }

    // Get a shader for the instance's list.
    //
    // @param i index into the shader list
    // @return requested shader, or null if the input is invalid
    func getShader(_ i: Int32) -> Shader? {
        if (shaders == nil) || (i < 0) || (i >= shaders!.count) {
            return nil
        }
        
        return shaders![Int(i)]
    }
    
    // Get a modifier for the instance's list.
    //
    // @param i index into the modifier list
    // @return requested modifier, or null if the input is
    //         invalid
    func getModifier(_ i: Int32) -> Modifier? {
        if (modifiers == nil) || (i < 0) || (i >= modifiers!.count) {
            return nil
        }
        
        return modifiers![Int(i)]
    }

    func getObjectToWorld(_ time: Float) -> AffineTransform? {
        return o2w!.sample(time)
    }

    func getWorldToObject(_ time: Float) -> AffineTransform? {
        return w2o!.sample(time)
    }

    func getBakingPrimitives() -> PrimitiveList? {
        return geometry!.getBakingPrimitives()
    }

    func getGeometry() -> Geometry? {
        return geometry
    }
}
