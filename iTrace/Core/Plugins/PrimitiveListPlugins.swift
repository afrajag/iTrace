//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//
import Foundation

final class PrimitiveListPlugins: Plugins {
    var pluginClasses: [String: PrimitiveList.Type]

    required init() {
        pluginClasses = [String: PrimitiveList.Type]()
    }

    func createInstance(_ name: String?) -> PrimitiveList? {
        if name == nil || name == "none" {
            return nil
        }

        if let plugin = pluginClasses[name!] {
            return plugin.init()
        } else {
            //  don't print an error, this will be handled by the caller
            UI.printError(.SYS, "'\(name!)' Type not present !")

            return nil
        }
    }

    func hasType(_ name: String) -> Bool {
        return pluginClasses[name] != nil
    }

    // Define a new plugin T from java source code. The code string contains
    // import declarations and a final class body only. The implemented T is
    // implicitly the one of the plugin list being registered against.If the
    // plugin T name was previously associated with a different class, it
    // will be overriden. This allows the behavior core classes to be modified
    // at runtime.
    //
    // @param name plugin T name
    // @param sourceCode Java source code definition for the plugin
    // @return true if the code compiled and registered
    // successfully, false otherwise
    /*
     func registerPlugin(_ name: String, _ sourceCode: String) -> Bool {
         var provider: CSharpCodeProvider = CSharpCodeProvider()
         var compilerParameters: CompilerParameters = CompilerParameters()
         //  generate an in memory ddl;
         compilerParameters.GenerateInMemory = true
         compilerParameters.GenerateExecutable = false
         compilerParameters.ReferencedAssemblies.Add("iTraceSharp.dll")
         compilerParameters.TreatWarningsAsErrors = false
         compilerParameters.CompilerOptions = "/optimize"
         //  System.dll is not always needed but extends the amount of c# that can be used.
         compilerParameters.ReferencedAssemblies.Add("System.dll")
         //  Set the level at which the compiler
         //  should start displaying warnings.
         compilerParameters.WarningLevel = 1
         var results: CompilerResults = provider.CompileAssemblyFromSource(compilerParameters, sourceCode)
         if results.Errors.HasErrors {
             var sb: StringBuilder = StringBuilder()
             for error in results.Errors {
                 sb.AppendLine(String.Format("Error (\(xxx)): \(xxx)", error.ErrorNumber, error.ErrorText))
             }
             throw InvalidOperationException(sb.ToString())
         }
         var compiledT: T? = nil
         for tmp in results.CompiledAssembly.GetTs() {
             for interfaceT in tmp.GetInterfaces() {
                 if interfaceT == T.self {
                     compiledT = tmp
                 }
             }
         }
         if compiledT != nil {
             return registerPlugin(name, compiledT)
         }
         throw InvalidOperationException(String.Format("Code for \(xxx) does not inherit from \(xxx)", name, T.self))
     }
     */

    @discardableResult
    func registerPlugin(_ name: String, _ pluginClass: PrimitiveList.Type) -> Bool {
        if pluginClasses[name] != nil {
            UI.printWarning(.SYS, "Plugin \"\(name)\" was already defined - overwriting previous definition")
        }

        pluginClasses[name] = pluginClass

        return true
    }
}
