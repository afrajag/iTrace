//
//  Thread.swift
//  iTrace
//
//  Created by Fabrizio Pezzola on 15/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//
import Foundation

/*
 func lock(obj: AnyObject, blk:() -> ()) {
 objc_sync_enter(obj)
 blk()
 objc_sync_exit(obj)
 }

 func synchronize(lockObj: AnyObject!, closure: ()->()){
 objc_sync_enter(lockObj)
 closure()
 objc_sync_exit(lockObj)
 }
 */
func lock(obj _: AnyObject!, blk: () -> Void) {
    let lockQueue = DispatchQueue(label: "lock.serial.queue")
    lockQueue.sync { // synchronized block
        blk()
    }
}

final class ThreadSafeCollection<Element> {
    // Concurrent synchronization queue
    private let queue = DispatchQueue(label: "ThreadSafeCollection.queue", attributes: .concurrent)

    private var _elements: [Element] = []

    var elements: [Element] {
        var result: [Element] = []

        queue.sync { // Read
            result = _elements
        }

        return result
    }

    func append(_ element: Element) {
        // Write with .barrier
        // This can be performed synchronously or asynchronously not to block calling thread.
        queue.async(flags: .barrier) {
            self._elements.append(element)
        }
    }
}

/*
 final class ImageCache {
 private let queue = DispatchQueue(label: "sync queue")
 private var storage: [String: UIImage] = [:]
 public subscript(key: String) -> UIImage? {
     get {
       return queue.sync {
         return storage[key]
       }
     }
     set {
       queue.sync {
         storage[key] = newValue
       }
     }
 }
 }
 */
