//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

protocol BenchmarkTest : class {
    func kernelBegin()

    func kernelMain()

    func kernelEnd()
}
