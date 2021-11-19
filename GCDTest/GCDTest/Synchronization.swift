//
//  Synchronization.swift
//  GCDTest
//
//  Created by Aleksei Shchukin on 2021-05-14.
//

import Foundation

let semaphore = DispatchSemaphore(value: 1)

private var internalResource: Int = 0
var resource: Int {
    get {
        defer {
            semaphore.signal()
        }
        semaphore.wait()
        return internalResource
    }
    set {
        semaphore.wait()
        print(newValue)
        internalResource = newValue
        sleep(1)
        semaphore.signal()
    }
}

func testSemaphore() {
    let group = DispatchGroup()
    DispatchQueue.global().async(group: group) {
        resource = 1
    }
    DispatchQueue.global().async(group: group) {
        resource = 2
    }
    DispatchQueue.global().async(group: group) {
        resource = 3
    }

    group.notify(queue: .global()) {
        print("Result = \(resource)")
    }



//    DispatchQueue.global().async {
//
//        print("test1")
//        sleep(1)
//        semaphore.signal()
//    }
//    semaphore.wait()
//    print("test2")
}

final class TestQueueSynchronization {

    let queue = DispatchQueue(label: "com.test.serial")

    private var internalResource: Int = 0
    var resource: Int {
        get {
            queue.sync {
                print("Read \(internalResource)")
                sleep(1) // Imitation of long work
                return internalResource
            }
        }
        set {
            queue.sync {
                print("Write \(newValue)")
                sleep(1) // Imitation of long work
                internalResource = newValue
            }
        }
    }

    func testQueueSynchronization() {
        for i in 0..<10 {
            if i % 2 == 0 {
                DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(Int.random(in: 1...5))) {
                    self.resource = i
                }
            } else {
                DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(Int.random(in: 1...5)))  {
                    _ = self.resource
                }
            }
        }
    }
}

final class TestBarrier {

    let queue = DispatchQueue(label: "com.test.concurrent", attributes: .concurrent)

    private var internalResource: Int = 0
    var resource: Int {
        get {
            queue.sync() {
                internalResource
            }
        }
        set {
            queue.async(flags: .barrier) {
                print("--- Barrier ---")
                sleep(1) // Imitation of long work
                self.internalResource = newValue
            }
        }
    }

    func testBarrier() {
        for i in 0..<10 {
            if i % 2 == 0 {
                DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(Int.random(in: 1...5))) {
                    self.resource = i
                }
            } else {
                DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(Int.random(in: 1...5)))  {
                    print(self.resource)
                }
            }
        }
    }
}
