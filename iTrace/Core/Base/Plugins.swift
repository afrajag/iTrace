//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

protocol Plugins: class {
    associatedtype T
    var pluginClasses: [String: T] { get set }

    // Create an object from the specified T name. If this T name is
    // unknown or invalid, null is returned.
    //
    // @param name plugin T name
    // @return an instance of the specified plugin T, or null
    // if not found or invalid
    associatedtype U
    func createInstance(_ name: String?) -> U?

    // Check this plugin list for the presence of the specified T name
    //
    // @param name plugin T name
    // @return true if this name has been registered,
    // false otherwise
    func hasType(_ name: String) -> Bool

    // Generate a unique plugin T name which has not yet been registered.
    // This is meant to be used when the actual T name is not crucial, but
    // succesfully registration is.
    //
    // @param prefix a prefix to be used in generating the unique name
    // @return a unique plugin T name not yet in use
    func generateUniqueName(_ prefix: String) -> String

    // Define a new plugin T from an existing class. This checks to make sure
    // the provided final class is default constructible (ie: has a constructor with
    // no parameters). If the plugin T name was previously associated with a
    // different class, it will be overriden. This allows the behavior core
    // classes to be modified at runtime.
    //
    // @param name plugin T name
    // @param pluginClass final class object for the plugin class
    // @return true if the plugin registered successfully,
    // false otherwise
    func registerPlugin(_ name: String, _ pluginClass: T) -> Bool
}

extension Plugins {
    func generateUniqueName(_ prefix: String) -> String {
        var i = 1
        var type: String = "\(prefix)_\(i)"

        while hasType(type) {
            type = "\(prefix)_\(i)"

            i += 1
        }

        return type
    }
}
