//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class Statistics {
    var numEyeRays: Int64
    var numShadowRays: Int64
    var numReflectionRays: Int64
    var numGlossyRays: Int64
    var numRefractionRays: Int64
    var numRays: Int64
    var numPixels: Int64
    var cacheHits: Int64
    var cacheMisses: Int64
    var cacheSumDepth: Int64
    var cacheNumCaches: Int64

    init() {
        // reset()
        numEyeRays = 0
        numShadowRays = 0
        numReflectionRays = 0
        numGlossyRays = 0
        numRefractionRays = 0
        numRays = 0
        numPixels = 0
        cacheHits = 0
        cacheMisses = 0
        cacheSumDepth = 0
        cacheNumCaches = 0
    }

    func reset() {
        numEyeRays = 0
        numShadowRays = 0
        numReflectionRays = 0
        numGlossyRays = 0
        numRefractionRays = 0
        numRays = 0
        numPixels = 0
        cacheHits = 0
        cacheMisses = 0
        cacheSumDepth = 0
        cacheNumCaches = 0
    }

    func accumulate(_ state: IntersectionState) {
        numEyeRays = numEyeRays + state.numEyeRays
        numShadowRays = numShadowRays + state.numShadowRays
        numReflectionRays = numReflectionRays + state.numReflectionRays
        numGlossyRays = numGlossyRays + state.numGlossyRays
        numRefractionRays = numRefractionRays + state.numRefractionRays
        numRays = numRays + state.numRays
    }

    func accumulate(_ cache: ShadingCache) {
        cacheHits = cacheHits + cache.hits
        cacheMisses = cacheMisses + cache.misses
        cacheSumDepth = cacheSumDepth + cache.sumDepth
        cacheNumCaches = cacheNumCaches + cache.numCaches
    }

    func setResolution(_ w: Int32, _ h: Int32) {
        numPixels = Int64(w * h)
    }

    func displayStats() {
        //  display raytracing stats
        UI.printInfo(.SCENE, "Raytracing stats:")
        UI.printInfo(.SCENE, "  * Rays traced:              (per pixel) (per eye ray) (percentage)")

        printRayTypeStats("eye", numEyeRays)
        printRayTypeStats("shadow", numShadowRays)
        printRayTypeStats("reflection", numReflectionRays)
        printRayTypeStats("glossy", numGlossyRays)
        printRayTypeStats("refraction", numRefractionRays)
        printRayTypeStats("other", numRays - numEyeRays - numShadowRays - numReflectionRays - numGlossyRays - numRefractionRays)
        printRayTypeStats("total", numRays)

        if (cacheHits + cacheMisses) > 0 {
            UI.printInfo(.LIGHT, "Shading cache stats:")
            UI.printInfo(.LIGHT, "  * Lookups:             \(cacheHits + cacheMisses)")
            UI.printInfo(.LIGHT, "  * Hits:                \(cacheHits)")
            UI.printInfo(.LIGHT, "  * Hit rate:            \((100 * cacheHits) / (cacheHits + cacheMisses))%")
            UI.printInfo(.LIGHT, "  * Average cache depth: \(Double(cacheSumDepth) / Double(cacheNumCaches))")
        }
    }

    func printRayTypeStats(_ name: String, _ n: Int64) {
        if n > 0 {
            let per_pixel = Double(n) / Double(numPixels)
            let per_eye_ray = Double(n) / Double(numEyeRays)
            let perc = Double(n * 100) / Double(numRays)

            UI.printInfo(.SCENE, String(format: "      %-10@  %11d   %7.2f      %7.2f      %6.2f%%", name, n, per_pixel, per_eye_ray, perc))
        }
    }
}
